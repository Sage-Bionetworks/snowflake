"""MC2 Center tab — metrics scoped to the MC2 Center project.

Syn ID: syn7080714
"""
import pandas as pd
import streamlit as st

from utils import (
    SQL_CTE_NON_SAGERS,
    execute_query,
    rename_duplicate_columns,
)

_PROJECT_ID = 7080714


def query_kpis() -> str:
    """File count, download totals, and 30-day window for the MC2 Center project."""
    return f"""
WITH
    {SQL_CTE_NON_SAGERS},
    project_files AS (
        SELECT file_handle_id, id AS node_id, name
        FROM synapse_data_warehouse.synapse.node_latest
        WHERE
            project_id = {_PROJECT_ID}
            AND node_type = 'file'
    ),
    events AS (
        SELECT dl.user_id, dl.record_date, dl.file_handle_id
        FROM synapse_data_warehouse.synapse_event.objectdownload_event dl
        INNER JOIN non_sagers ON dl.user_id = non_sagers.user_id
        INNER JOIN project_files ON dl.file_handle_id = project_files.file_handle_id
        WHERE dl.project_id = {_PROJECT_ID}
    )

SELECT
    (SELECT COUNT(*) FROM project_files)               AS total_files,
    COUNT(*)                                           AS total_external_downloads,
    COUNT(DISTINCT user_id)                            AS total_external_users,
    COUNT_IF(record_date >= CURRENT_DATE - 30)         AS downloads_last_30d,
    COUNT_IF(record_date >= CURRENT_DATE - 60
             AND record_date < CURRENT_DATE - 30)      AS downloads_prior_30d
FROM events;
"""


def query_daily_downloads() -> str:
    """Daily external download counts for the MC2 Center project."""
    return f"""
WITH
    {SQL_CTE_NON_SAGERS},
    project_files AS (
        SELECT file_handle_id
        FROM synapse_data_warehouse.synapse.node_latest
        WHERE project_id = {_PROJECT_ID} AND node_type = 'file'
    )

SELECT
    dl.record_date,
    COUNT(*) AS external_downloads
FROM
    synapse_data_warehouse.synapse_event.objectdownload_event dl
INNER JOIN non_sagers ON dl.user_id = non_sagers.user_id
INNER JOIN project_files ON dl.file_handle_id = project_files.file_handle_id
WHERE dl.project_id = {_PROJECT_ID}
GROUP BY 1
ORDER BY 1 ASC;
"""


def query_top_files() -> str:
    """Top files by external download count for the MC2 Center project."""
    return f"""
WITH
    {SQL_CTE_NON_SAGERS}

SELECT
    'syn' || n.id::string        AS synid,
    n.name                       AS file_name,
    COUNT(*)                     AS external_downloads,
    COUNT(DISTINCT dl.user_id)   AS external_unique_users,
    MAX(dl.record_date)          AS last_downloaded
FROM
    synapse_data_warehouse.synapse_event.objectdownload_event dl
INNER JOIN non_sagers ON dl.user_id = non_sagers.user_id
INNER JOIN synapse_data_warehouse.synapse.node_latest n
    ON dl.file_handle_id = n.file_handle_id
    AND n.project_id = {_PROJECT_ID}
    AND n.node_type = 'file'
WHERE dl.project_id = {_PROJECT_ID}
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 50;
"""

@st.fragment
def _cell_kpis():
    _, col_btn = st.columns([9, 1])
    with col_btn:
        if st.button(
            ":material/refresh:",
            type="tertiary",
            key="refresh_mc2_center_kpis",
            help="Refresh metrics",
        ):
            execute_query.clear(query_kpis())

    try:
        with st.spinner("Loading metrics", show_time=True):
            row = st.session_state.session.create_async_job(
                execute_query(query_kpis())
            ).result("pandas").iloc[0]

        last_30d = int(row["DOWNLOADS_LAST_30D"])
        prior_30d = int(row["DOWNLOADS_PRIOR_30D"])

        c1, c2, c3, c4 = st.columns(4)
        c1.metric("Files", f"{int(row['TOTAL_FILES']):,}")
        c2.metric("External Downloads (all-time)", f"{int(row['TOTAL_EXTERNAL_DOWNLOADS']):,}")
        c3.metric("External Users (all-time)", f"{int(row['TOTAL_EXTERNAL_USERS']):,}")
        c4.metric(
            "Downloads (last 30 days)",
            f"{last_30d:,}",
            delta=f"{last_30d - prior_30d:+,} vs prior 30 days",
            delta_color="normal",
        )
    except Exception as e:
        st.error(f"Error: {e}")


@st.fragment
def _cell_trends():
    with st.container(
        horizontal=True,
        horizontal_alignment="distribute",
        vertical_alignment="center",
    ):
        st.markdown("### Download Trends")
        if st.button(
            ":material/refresh:",
            type="tertiary",
            key="refresh_mc2_center_trends",
            help="Refresh trends",
        ):
            execute_query.clear(query_daily_downloads())

    try:
        with st.spinner("Loading trend data", show_time=True):
            df = st.session_state.session.create_async_job(
                execute_query(query_daily_downloads())
            ).result("pandas")

        df = rename_duplicate_columns(df)
        df["RECORD_DATE"] = pd.to_datetime(df["RECORD_DATE"])
        df = df.set_index("RECORD_DATE").resample("MS").sum().reset_index()

        col1, col2 = st.columns(2)
        with col1:
            with st.container(border=True):
                st.markdown("**Monthly External Downloads**")
                st.bar_chart(df.set_index("RECORD_DATE")["EXTERNAL_DOWNLOADS"], height=280)
        with col2:
            with st.container(border=True):
                st.markdown("**Cumulative External Downloads**")
                cumulative = df.copy()
                cumulative["CUMULATIVE"] = cumulative["EXTERNAL_DOWNLOADS"].cumsum()
                st.area_chart(cumulative.set_index("RECORD_DATE")["CUMULATIVE"], height=280)
    except Exception as e:
        st.error(f"Error: {e}")


@st.fragment
def _cell_top_files():
    with st.container(
        horizontal=True,
        horizontal_alignment="distribute",
        vertical_alignment="center",
    ):
        st.markdown("### Top Downloaded Files")
        if st.button(
            ":material/refresh:",
            type="tertiary",
            key="refresh_mc2_center_files",
            help="Refresh file list",
        ):
            execute_query.clear(query_top_files())

    try:
        with st.spinner("Loading file data", show_time=True):
            df = st.session_state.session.create_async_job(
                execute_query(query_top_files())
            ).result("pandas")

        df = rename_duplicate_columns(df)

        with st.container(border=True):
            st.markdown(f"**Top Files by External Downloads** — {len(df)} files")
            st.dataframe(
                df,
                width="stretch",
                hide_index=True,
                column_config={
                    "SYNID": st.column_config.TextColumn("synID"),
                    "FILE_NAME": st.column_config.TextColumn("File Name"),
                    "EXTERNAL_DOWNLOADS": st.column_config.ProgressColumn(
                        "External Downloads",
                        min_value=0,
                        max_value=int(df["EXTERNAL_DOWNLOADS"].max()) if len(df) else 1,
                        format="%d",
                    ),
                    "EXTERNAL_UNIQUE_USERS": st.column_config.NumberColumn("Unique Users"),
                    "LAST_DOWNLOADED": st.column_config.DateColumn("Last Downloaded"),
                },
            )
    except Exception as e:
        st.error(f"Error: {e}")


def prefetch():
    execute_query(query_kpis())
    execute_query(query_daily_downloads())
    execute_query(query_top_files())


def render():
    st.markdown(
        "Metrics scoped to [syn7080714](https://www.synapse.org/Synapse:syn7080714)",
        unsafe_allow_html=False,
    )
    _cell_kpis()
    st.divider()
    _cell_trends()
    st.divider()
    _cell_top_files()
