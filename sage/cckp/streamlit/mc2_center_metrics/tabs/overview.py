"""Overview tab."""
import streamlit as st

from utils import (
    CTE_NON_SAGERS,
    CTE_SYNAPSE_USERS,
    CTE_MC2_DATASET_NODES,
    CTE_MC2_FILE_NODES,
    MANIFEST_FILTER,
    rename_duplicate_columns,
    execute_query,
)


def query_kpi_counts() -> str:
    """Project, dataset, and files counts across all MC2 projects."""
    return f"""
        WITH
            {CTE_MC2_DATASET_NODES}

        SELECT
            COUNT(DISTINCT project_id) AS total_projects,
            (SELECT COUNT(DISTINCT id) FROM mc2_dataset_nodes) AS total_datasets,
            COUNT_IF(node_type = 'file' AND name NOT ILIKE '{MANIFEST_FILTER}') AS total_files,
            COUNT_IF(
                node_type = 'file'
                AND name NOT ILIKE '{MANIFEST_FILTER}'
                AND is_public = TRUE
            ) AS public_files
        FROM
            -- TODO: fix source table to remove duplicate node ids, then remove QUALIFY workaround
            -- sage.cckp.mc2_nodes
            (SELECT * FROM sage.cckp.mc2_nodes QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY change_timestamp DESC) = 1);
        """


def query_kpi_downloads() -> str:
    """Download counts (total and last 30-60 days)."""
    return f"""
        WITH
            {CTE_NON_SAGERS},
            {CTE_MC2_FILE_NODES},
            events AS (
                SELECT
                    dl.user_id,
                    dl.record_date
                FROM
                    synapse_data_warehouse.synapse_event.objectdownload_event AS dl
                INNER JOIN
                    non_sagers ON dl.user_id = non_sagers.user_id
                WHERE
                    dl.project_id IN (SELECT project_id FROM sage.cckp.mc2_projects)
                    AND dl.file_handle_id IN (SELECT file_handle_id FROM mc2_file_nodes)
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
    """Project-level breakdown of external vs Sage downloads."""
    return f"""
        WITH
            {CTE_SYNAPSE_USERS},
            {CTE_MC2_FILE_NODES}

        SELECT
            mc2.project_name,

            -- External community metrics
            COUNT_IF(synapse_users.user_type = 'External') AS external_downloads,
            COUNT(DISTINCT CASE WHEN synapse_users.user_type = 'External' THEN dl.user_id END) AS external_unique_users,

            -- Sage metrics
            COUNT_IF(synapse_users.user_type = 'Sager') AS sage_downloads,
            COUNT(DISTINCT CASE WHEN synapse_users.user_type = 'Sager' THEN dl.user_id END) AS sage_unique_users
        FROM
            -- TODO: fix source table to remove duplicate project ids, then remove DISTINCT workaround
            -- sage.cckp.mc2_projects mc2
            (SELECT DISTINCT project_id, project_name FROM sage.cckp.mc2_projects) AS mc2
        LEFT JOIN
            synapse_data_warehouse.synapse_event.objectdownload_event AS dl
                ON dl.project_id = mc2.project_id
                AND dl.file_handle_id IN (SELECT file_handle_id FROM mc2_file_nodes)
        LEFT JOIN
            synapse_users ON dl.user_id = synapse_users.id
        GROUP BY 1
        ORDER BY 2 DESC;
        """


@st.fragment
def _cell_kpis():
    _, col_btn = st.columns([11, 1])
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

        total_files = int(counts['TOTAL_FILES'])
        public_files = int(counts['PUBLIC_FILES'])
        public_pct = round(100 * public_files / total_files) if total_files else 0

        col1, col2, col3, col4, col5 = st.columns(5)
        col1.metric(
            "Projects",
            f"{int(counts['TOTAL_PROJECTS']):,}",
        )
        col2.metric(
            "Datasets",
            f"{int(counts['TOTAL_DATASETS']):,}",
        )
        col3.metric(
            "Files",
            f"{total_files:,}",
        )
        col4.metric(
            "Public Files",
            f"{public_files:,}",
            delta=f"{public_pct}% of all files",
            delta_color="off",
        )
        col5.metric(
            "External Users",
            f"{int(downloads['TOTAL_EXTERNAL_USERS']):,}",
        )

        st.divider()

        last_30d = int(downloads["DOWNLOADS_LAST_30D"])
        prior_30d = int(downloads["DOWNLOADS_PRIOR_30D"])
        delta_30d = last_30d - prior_30d

        download1, download2, download3 = st.columns(3)
        download1.metric(
            "Total External User Downloads",
            f"{int(downloads['TOTAL_EXTERNAL_DOWNLOADS']):,}",
        )
        download2.metric(
            "External User Downloads (last 30 days)",
            f"{last_30d:,}",
            delta=f"{delta_30d:+,} vs prior 30 days",
            delta_color="normal",
        )
        download3.metric(
            "External User Downloads (prior 30 days)",
            f"{prior_30d:,}",
        )

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
                st.markdown("### Download Counts by Project")
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
                st.caption(f"{len(df):,} projects · {int(df['EXTERNAL_DOWNLOADS'].sum()):,} external user downloads")
                st.dataframe(
                    df,
                    width="stretch",
                    hide_index=True,
                    column_config={
                        "PROJECT_NAME": st.column_config.TextColumn("Project"),
                        "EXTERNAL_DOWNLOADS": st.column_config.ProgressColumn(
                            "External User Downloads",
                            min_value=0,
                            max_value=max_external,
                            format="%d",
                        ),
                        "EXTERNAL_UNIQUE_USERS": st.column_config.NumberColumn(
                            "Unique External Users"
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
    _cell_downloads_by_project()
