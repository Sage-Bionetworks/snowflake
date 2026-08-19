"""Overview tab."""
import streamlit as st

from utils import (
    SQL_CTE_NON_SAGERS,
    SQL_CTE_SYNAPSE_USERS,
    SQL_CTE_NODES_WITH_PARENT,
    SQL_CTE_MC2_DATASET_NODES,
    rename_duplicate_columns,
    execute_query,
)


def query_kpi_counts() -> str:
    """Single query for all cheap headline counts (no events table scan)."""
    return f"""
WITH
    {SQL_CTE_NODES_WITH_PARENT},
    {SQL_CTE_MC2_DATASET_NODES}

SELECT
    COUNT(DISTINCT project_id) AS total_projects,
    COUNT_IF(node_type = 'file' AND name NOT ILIKE 'synapse_storage_manifest_%view.csv') AS total_files,
    COUNT_IF(
        node_type = 'file'
        AND name NOT ILIKE 'synapse_storage_manifest_%view.csv'
        AND is_public = TRUE
    ) AS public_files,
    (SELECT COUNT(DISTINCT id) FROM mc2_dataset_nodes) AS total_datasets
FROM
    sage.cckp.mc2_nodes;
"""


def query_kpi_downloads() -> str:
    """Download totals and 30-day window with prior-period delta, from the events table."""
    return f"""
WITH
    {SQL_CTE_NON_SAGERS},
    mc2_file_handles AS (
        SELECT file_handle_id
        FROM sage.cckp.mc2_nodes
        WHERE node_type = 'file'
    ),
    events AS (
        SELECT
            dl.user_id,
            dl.record_date
        FROM
            synapse_data_warehouse.synapse_event.objectdownload_event AS dl
        INNER JOIN
            non_sagers ON dl.user_id = non_sagers.user_id
        INNER JOIN
            mc2_file_handles ON dl.file_handle_id = mc2_file_handles.file_handle_id
        WHERE
            dl.project_id IN (SELECT project_id FROM sage.cckp.mc2_projects)
    )

SELECT
    COUNT(*) AS total_external_downloads,
    COUNT(DISTINCT user_id) AS total_external_users,
    COUNT_IF(record_date >= CURRENT_DATE - 30) AS downloads_last_30d,
    COUNT_IF(record_date >= CURRENT_DATE - 60 AND record_date < CURRENT_DATE - 30) AS downloads_prior_30d
FROM
    events;
"""


def query_downloads_by_project() -> str:
    return f"""
WITH
    {SQL_CTE_SYNAPSE_USERS}

SELECT
    mc2.project_name,

    -- Sage metrics
    COUNT_IF(synapse_users.user_type = 'Sager') AS sage_downloads,
    COUNT(DISTINCT CASE WHEN synapse_users.user_type = 'Sager' THEN dl.user_id END) AS sage_unique_users,

    -- External community metrics
    COUNT_IF(synapse_users.user_type = 'External') AS external_downloads,
    COUNT(DISTINCT CASE WHEN synapse_users.user_type = 'External' THEN dl.user_id END) AS external_unique_users
FROM
    sage.cckp.mc2_projects AS mc2
LEFT JOIN
    synapse_data_warehouse.synapse_event.objectdownload_event AS dl
        ON dl.project_id = mc2.project_id
        AND dl.file_handle_id IN (
            SELECT file_handle_id FROM sage.cckp.mc2_nodes
            WHERE node_type = 'file'
            AND name NOT ILIKE 'synapse_storage_manifest_%view.csv'
        )
LEFT JOIN
    synapse_users ON dl.user_id = synapse_users.id
GROUP BY 1
ORDER BY 4 DESC;
"""


@st.fragment
def _cell_kpis():
    _, col_btn = st.columns([9, 1])
    with col_btn:
        if st.button(
            ":material/refresh:",
            type="tertiary",
            key="refresh_overview_kpis",
            help="Refresh KPI metrics",
        ):
            execute_query.clear(query_kpi_counts())
            execute_query.clear(query_kpi_downloads())

    try:
        with st.spinner("Loading metrics", show_time=True):
            counts = st.session_state.session.create_async_job(
                execute_query(query_kpi_counts())
            ).result("pandas").iloc[0]
            downloads = st.session_state.session.create_async_job(
                execute_query(query_kpi_downloads())
            ).result("pandas").iloc[0]

        # Row 1 — entity counts
        total_files = int(counts['TOTAL_FILES'])
        public_files = int(counts['PUBLIC_FILES'])
        public_pct = round(100 * public_files / total_files) if total_files else 0

        c1, c2, c3, c4, c5 = st.columns(5)
        c1.metric("Projects", f"{int(counts['TOTAL_PROJECTS']):,}")
        c2.metric("Datasets", f"{int(counts['TOTAL_DATASETS']):,}")
        c3.metric("Files", f"{total_files:,}")
        c4.metric("Public Files", f"{public_files:,}", delta=f"{public_pct}% of all files", delta_color="off")
        c5.metric("External Users", f"{int(downloads['TOTAL_EXTERNAL_USERS']):,}")

        st.divider()

        # Row 2 — download totals; last-30d shows delta vs prior 30d
        last_30d = int(downloads["DOWNLOADS_LAST_30D"])
        prior_30d = int(downloads["DOWNLOADS_PRIOR_30D"])
        delta_30d = last_30d - prior_30d

        d1, d2, d3 = st.columns(3)
        d1.metric("Total External Downloads", f"{int(downloads['TOTAL_EXTERNAL_DOWNLOADS']):,}")
        d2.metric(
            "External Downloads (last 30 days)",
            f"{last_30d:,}",
            delta=f"{delta_30d:+,} vs prior 30 days",
            delta_color="normal",
        )
        d3.metric("External Downloads (prior 30 days)", f"{prior_30d:,}")

    except Exception as e:
        st.error(f"Error: {str(e)}")


@st.fragment
def _cell_downloads_by_project():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Download Counts by Project (All-Time)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_overview_chart",
                help="Refresh download counts by project",
            ):
                execute_query.clear(query_downloads_by_project())

        try:
            with st.spinner("Executing query", show_time=True):
                df = st.session_state.session.create_async_job(
                    execute_query(query_downloads_by_project())
                ).result("pandas")
            df = rename_duplicate_columns(df)

            if len(df) > 0:
                max_external = int(df["EXTERNAL_DOWNLOADS"].max())
                st.caption(f"{len(df):,} rows")
                st.dataframe(
                    df,
                    width="stretch",
                    hide_index=True,
                    column_config={
                        "PROJECT_NAME": st.column_config.TextColumn("Project"),
                        "EXTERNAL_DOWNLOADS": st.column_config.ProgressColumn(
                            "External Downloads",
                            min_value=0,
                            max_value=max_external,
                            format="%d",
                        ),
                        "EXTERNAL_UNIQUE_USERS": st.column_config.NumberColumn(
                            "External Unique Users"
                        ),
                        "SAGE_DOWNLOADS": st.column_config.ProgressColumn(
                            "Sage Downloads",
                            min_value=0,
                            max_value=max_external,
                            format="%d",
                        ),
                        "SAGE_UNIQUE_USERS": st.column_config.NumberColumn(
                            "Sage Unique Users"
                        ),
                    },
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def prefetch():
    execute_query(query_kpi_counts())
    execute_query(query_kpi_downloads())
    execute_query(query_downloads_by_project())


def render():
    _cell_kpis()
    st.markdown("")
    _cell_downloads_by_project()
