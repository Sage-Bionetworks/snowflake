"""Trends tab."""
import pandas as pd
import streamlit as st

from utils import (
    CTE_NON_SAGERS,
    CTE_SYNAPSE_USERS,
    CTE_MC2_FILE_NODES,
    GRANULARITY_OPTIONS,
    RESAMPLE_FREQ,
    rename_duplicate_columns,
    execute_query,
)


def query_daily_downloads() -> str:
    """Daily external and Sage download counts across all MC2 projects."""
    return f"""
        WITH
            {CTE_SYNAPSE_USERS},
            {CTE_MC2_FILE_NODES}

        SELECT
            record_date,
            COUNT_IF(u.user_type = 'External') AS external_user_downloads,
            COUNT_IF(u.user_type = 'Sager') AS sage_downloads
        FROM
            synapse_data_warehouse.synapse_event.objectdownload_event AS dl
        INNER JOIN
            synapse_users u ON dl.user_id = u.id
        WHERE
            dl.project_id IN (SELECT project_id FROM sage.cckp.mc2_projects)
            AND dl.file_handle_id IN (SELECT file_handle_id FROM mc2_file_nodes)
        GROUP BY 1
        ORDER BY 1 ASC;
        """


def query_new_external_users_by_day() -> str:
    """Count of external users whose first download fell on each date."""
    return f"""
        WITH
            {CTE_NON_SAGERS},
            {CTE_MC2_FILE_NODES},
            first_downloads AS (
                SELECT
                    dl.user_id,
                    MIN(dl.record_date) AS first_download_date
                FROM
                    synapse_data_warehouse.synapse_event.objectdownload_event AS dl
                INNER JOIN
                    non_sagers ON dl.user_id = non_sagers.user_id
                WHERE
                    dl.project_id IN (SELECT project_id FROM sage.cckp.mc2_projects)
                    AND dl.file_handle_id IN (SELECT file_handle_id FROM mc2_file_nodes)
                GROUP BY 1
            )

        SELECT
            first_download_date AS record_date,
            COUNT(*) AS new_external_users
        FROM
            first_downloads
        GROUP BY 1
        ORDER BY 1 ASC;
        """


def _resample(df: pd.DataFrame, granularity: str) -> pd.DataFrame:
    """Resample a daily df to the given granularity."""
    return (
        df.set_index("RECORD_DATE")
        .resample(RESAMPLE_FREQ[granularity])
        .sum()
        .reset_index()
    )


@st.fragment
def _cell_downloads(granularity: str):
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Downloads Over Time")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_trends_downloads",
                help="Refresh downloads chart",
            ):
                execute_query.clear(query_daily_downloads())

        try:
            with st.spinner("Executing query", show_time=True):
                df = st.session_state.session.create_async_job(
                    execute_query(query_daily_downloads())
                ).result("pandas")
            df = rename_duplicate_columns(df)
            df["RECORD_DATE"] = pd.to_datetime(df["RECORD_DATE"])
            df = _resample(df, granularity)
            st.line_chart(df.set_index("RECORD_DATE"), width="stretch", height=350)
        except Exception as e:
            st.error(f"Error: {str(e)}")


@st.fragment
def _cell_new_users(granularity: str):
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### New External Users Over Time")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_trends_new_users",
                help="Refresh new users chart",
            ):
                execute_query.clear(query_new_external_users_by_day())

        try:
            with st.spinner("Executing query", show_time=True):
                df = st.session_state.session.create_async_job(
                    execute_query(query_new_external_users_by_day())
                ).result("pandas")
            df = rename_duplicate_columns(df)
            df["RECORD_DATE"] = pd.to_datetime(df["RECORD_DATE"])
            df = _resample(df, granularity)
            st.bar_chart(df.set_index("RECORD_DATE"), width="stretch", height=350)
        except Exception as e:
            st.error(f"Error: {str(e)}")


@st.fragment
def _cell_cumulative(granularity: str):
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Cumulative External User Downloads")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_trends_cumulative",
                help="Refresh cumulative chart",
            ):
                execute_query.clear(query_daily_downloads())

        try:
            with st.spinner("Executing query", show_time=True):
                # Reuses the cached result from _cell_downloads — no extra query.
                df = st.session_state.session.create_async_job(
                    execute_query(query_daily_downloads())
                ).result("pandas")
            df = rename_duplicate_columns(df)
            df["RECORD_DATE"] = pd.to_datetime(df["RECORD_DATE"])
            df = _resample(df, granularity)[["RECORD_DATE", "EXTERNAL_USER_DOWNLOADS"]]
            df["CUMULATIVE_EXTERNAL_DOWNLOADS"] = df["EXTERNAL_USER_DOWNLOADS"].cumsum()
            df = df.drop(columns=["EXTERNAL_USER_DOWNLOADS"])
            st.area_chart(df.set_index("RECORD_DATE"), width="stretch", height=350)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def prefetch():
    execute_query(query_daily_downloads())
    execute_query(query_new_external_users_by_day())


def render():
    _, col_label, col_select = st.columns([7, 1, 2])
    with col_label:
        st.markdown("**View by:**")
    with col_select:
        granularity = st.selectbox(
            "granularity",
            GRANULARITY_OPTIONS,
            index=2,  # default to Monthly
            key="trends_granularity",
            label_visibility="collapsed",
        )

    col_downloads, col_users = st.columns(2)
    with col_downloads:
        _cell_downloads(granularity)
    with col_users:
        _cell_new_users(granularity)
    _cell_cumulative(granularity)
