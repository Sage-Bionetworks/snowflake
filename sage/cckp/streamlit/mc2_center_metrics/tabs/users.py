"""External users tab."""
import pandas as pd
import streamlit as st

from utils import (
    SQL_CTE_NON_SAGERS,
    rename_duplicate_columns,
    execute_query,
)


def query_user_summary() -> str:
    """
    One row per external user: total downloads, projects touched, first/last
    activity, and whether they are a one-time or returning downloader.
    """
    return f"""
WITH
    {SQL_CTE_NON_SAGERS},
    user_stats AS (
        SELECT
            dl.user_id,
            COUNT(*) AS total_downloads,
            COUNT(DISTINCT dl.project_id) AS projects_downloaded,
            MIN(dl.record_date) AS first_download,
            MAX(dl.record_date) AS latest_download
        FROM
            synapse_data_warehouse.synapse_event.objectdownload_event AS dl
        INNER JOIN
            non_sagers ON dl.user_id = non_sagers.user_id
        WHERE
            dl.project_id IN (SELECT project_id FROM sage.cckp.mc2_projects)
            AND dl.file_handle_id IN (
                SELECT file_handle_id FROM sage.cckp.mc2_nodes WHERE node_type = 'file'
            )
        GROUP BY 1
    )

SELECT
    ns.user_name,
    us.total_downloads,
    us.projects_downloaded,
    us.first_download,
    us.latest_download,
    CASE WHEN us.total_downloads = 1 THEN 'One-time' ELSE 'Returning' END AS user_type
FROM
    user_stats us
INNER JOIN
    non_sagers ns ON ns.user_id = us.user_id
ORDER BY 2 DESC;
"""


def query_user_project_breakdown() -> str:
    """Downloads per user per project — used for the filterable breakdown table."""
    return f"""
WITH
    {SQL_CTE_NON_SAGERS}

SELECT
    ns.user_name,
    mc2.project_name,
    COUNT(*) AS downloads,
    MIN(dl.record_date) AS first_download,
    MAX(dl.record_date) AS latest_download
FROM
    synapse_data_warehouse.synapse_event.objectdownload_event AS dl
INNER JOIN
    non_sagers ns ON dl.user_id = ns.user_id
INNER JOIN
    sage.cckp.mc2_projects mc2 ON dl.project_id = mc2.project_id
WHERE
    dl.file_handle_id IN (
        SELECT file_handle_id FROM sage.cckp.mc2_nodes WHERE node_type = 'file'
    )
GROUP BY 1, 2
ORDER BY 1 ASC, 3 DESC;
"""


@st.fragment
def _cell_returning_vs_onetime():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Returning vs One-Time Users")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_users_retention",
                help="Refresh user retention breakdown",
            ):
                execute_query.clear(query_user_summary())

        try:
            with st.spinner("Executing query", show_time=True):
                df = st.session_state.session.create_async_job(
                    execute_query(query_user_summary())
                ).result("pandas")
            df = rename_duplicate_columns(df)

            returning = int((df["USER_TYPE"] == "Returning").sum())
            one_time = int((df["USER_TYPE"] == "One-time").sum())
            total = returning + one_time

            m1, m2, m3 = st.columns(3)
            m1.metric("Total External Users", f"{total:,}")
            m2.metric("Returning Users", f"{returning:,}",
                      delta=f"{returning / total * 100:.0f}% of total" if total else None,
                      delta_color="off")
            m3.metric("One-Time Users", f"{one_time:,}",
                      delta=f"{one_time / total * 100:.0f}% of total" if total else None,
                      delta_color="off")

            # Bar chart: download distribution bucketed by download count
            buckets = pd.cut(
                df["TOTAL_DOWNLOADS"],
                bins=[0, 1, 5, 10, 50, float("inf")],
                labels=["1", "2–5", "6–10", "11–50", "50+"],
                right=True,
            )
            bucket_counts = buckets.value_counts().sort_index().reset_index()
            bucket_counts.columns = ["Downloads per User", "Users"]
            st.bar_chart(
                bucket_counts.set_index("Downloads per User"),
                width="stretch",
                height=250,
                x_label="Download count bucket",
                y_label="Number of users",
            )
        except Exception as e:
            st.error(f"Error: {str(e)}")


@st.fragment
def _cell_user_table():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### All Users")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_users_table",
                help="Refresh external users table",
            ):
                execute_query.clear(query_user_summary())

        try:
            with st.spinner("Executing query", show_time=True):
                # Reuses cached result from _cell_returning_vs_onetime
                df = st.session_state.session.create_async_job(
                    execute_query(query_user_summary())
                ).result("pandas")
            df = rename_duplicate_columns(df)
            max_dl = int(df["TOTAL_DOWNLOADS"].max()) if len(df) > 0 else 1
            st.caption(f"{len(df):,} rows")
            st.dataframe(
                df,
                width="stretch",
                hide_index=True,
                height=400,
                column_config={
                    "USER_NAME": st.column_config.TextColumn("Username"),
                    "TOTAL_DOWNLOADS": st.column_config.ProgressColumn(
                        "Total Downloads",
                        min_value=0,
                        max_value=max_dl,
                        format="%d",
                    ),
                    "PROJECTS_DOWNLOADED": st.column_config.NumberColumn("Projects"),
                    "FIRST_DOWNLOAD": st.column_config.DateColumn("First Download"),
                    "LATEST_DOWNLOAD": st.column_config.DateColumn("Latest Download"),
                    "USER_TYPE": st.column_config.TextColumn("Type"),
                },
            )
        except Exception as e:
            st.error(f"Error: {str(e)}")


@st.fragment
def _cell_user_project_breakdown():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Downloads by User & Project")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_users_projects",
                help="Refresh user–project breakdown",
            ):
                execute_query.clear(query_user_project_breakdown())
                if "users_project_df" in st.session_state:
                    del st.session_state["users_project_df"]

        if "users_project_df" not in st.session_state:
            try:
                with st.spinner("Executing query", show_time=True):
                    df = st.session_state.session.create_async_job(
                        execute_query(query_user_project_breakdown())
                    ).result("pandas")
                st.session_state["users_project_df"] = rename_duplicate_columns(df)
            except Exception as e:
                st.error(f"Error: {str(e)}")
                return

        df = st.session_state["users_project_df"]

        user_options = sorted(df["USER_NAME"].dropna().unique())
        selected = st.multiselect(
            "Filter by username",
            options=user_options,
            placeholder="Select one or more users (shows all by default)",
            key="users_project_filter",
        )
        filtered = df[df["USER_NAME"].isin(selected)] if selected else df

        st.caption(f"{len(filtered):,} of {len(df):,} rows" if selected else f"{len(df):,} rows")
        st.dataframe(
            filtered,
            width="stretch",
            hide_index=True,
            height=400,
            column_config={
                "USER_NAME": st.column_config.TextColumn("Username"),
                "PROJECT_NAME": st.column_config.TextColumn("Project"),
                "DOWNLOADS": st.column_config.NumberColumn("Downloads"),
                "FIRST_DOWNLOAD": st.column_config.DateColumn("First Download"),
                "LATEST_DOWNLOAD": st.column_config.DateColumn("Latest Download"),
            },
        )


@st.fragment
def _cell_projects_per_user():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Projects Downloaded per User")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_projects_per_user",
                help="Refresh projects per user",
            ):
                execute_query.clear(query_user_summary())

        try:
            with st.spinner("Executing query", show_time=True):
                # Reuses cached result from _cell_user_table
                df = st.session_state.session.create_async_job(
                    execute_query(query_user_summary())
                ).result("pandas")
            df = rename_duplicate_columns(df)
            summary = (
                df[["USER_NAME", "PROJECTS_DOWNLOADED"]]
                .sort_values("PROJECTS_DOWNLOADED", ascending=False)
                .reset_index(drop=True)
            )

            user_options = sorted(summary["USER_NAME"].dropna().unique())
            selected = st.multiselect(
                "Filter by username",
                options=user_options,
                placeholder="Select one or more users (shows all by default)",
                key="projects_per_user_filter",
            )
            filtered = summary[summary["USER_NAME"].isin(selected)] if selected else summary

            st.caption(f"{len(filtered):,} of {len(summary):,} rows" if selected else f"{len(summary):,} rows")
            st.dataframe(
                filtered,
                width="stretch",
                hide_index=True,
                height=400,
                column_config={
                    "USER_NAME": st.column_config.TextColumn("Username"),
                    "PROJECTS_DOWNLOADED": st.column_config.NumberColumn("Projects Downloaded From"),
                },
            )
        except Exception as e:
            st.error(f"Error: {str(e)}")


def prefetch():
    execute_query(query_user_summary())
    execute_query(query_user_project_breakdown())


def render():
    _cell_returning_vs_onetime()
    _cell_user_table()
    col1, col2 = st.columns(2)
    with col1:
        _cell_user_project_breakdown()
    with col2:
        _cell_projects_per_user()
