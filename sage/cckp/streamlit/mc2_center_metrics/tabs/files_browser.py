"""Files Browser tab — all MC2 project files with download counts."""
import pandas as pd
import streamlit as st

from utils import (
    SQL_CTE_MC2_DATASET_FILES,
    SQL_CTE_MC2_DATASET_NODES,
    SQL_CTE_SYNAPSE_USERS,
    rename_duplicate_columns,
    execute_query,
)


def query_all_files() -> str:
    """All MC2 file nodes that have at least one download, with per-file download counts."""
    return f"""
WITH
    {SQL_CTE_SYNAPSE_USERS},
    {SQL_CTE_MC2_DATASET_NODES},
    {SQL_CTE_MC2_DATASET_FILES},
    -- Scoped to MC2 projects before scanning the events table
    download_counts AS (
        SELECT
            dl.file_handle_id,
            dl.project_id,
            COUNT_IF(u.user_type = 'Sager') AS sage_downloads,
            COUNT(DISTINCT CASE WHEN u.user_type = 'Sager' THEN dl.user_id END) AS sage_unique_users,
            COUNT_IF(u.user_type = 'External') AS external_downloads,
            COUNT(DISTINCT CASE WHEN u.user_type = 'External' THEN dl.user_id END) AS external_unique_users,
            COUNT(*) AS total_downloads,
            COUNT(DISTINCT dl.user_id) AS total_unique_users,
            MAX(dl.record_date) AS latest_download_activity
        FROM
            synapse_data_warehouse.synapse_event.objectdownload_event AS dl
        INNER JOIN
            synapse_users u ON dl.user_id = u.id
        WHERE
            dl.project_id IN (SELECT project_id FROM sage.cckp.mc2_projects)
        GROUP BY 1, 2
    )

SELECT
    n.project_id,
    n.project_name,
    'syn' || n.id::STRING AS file_synid,
    n.name AS filename,
    n.is_public,
    (mdf.file_entity_id IS NOT NULL) AS in_dataset,
    n.change_timestamp::DATE AS created_on,
    COALESCE(dc.external_downloads, 0) AS external_downloads,
    COALESCE(dc.external_unique_users, 0) AS external_unique_users,
    COALESCE(dc.sage_downloads, 0) AS sage_downloads,
    COALESCE(dc.sage_unique_users, 0) AS sage_unique_users,
    COALESCE(dc.total_downloads, 0) AS total_downloads,
    COALESCE(dc.total_unique_users, 0) AS total_unique_users,
    dc.latest_download_activity
FROM
    sage.cckp.mc2_nodes AS n
INNER JOIN
    download_counts dc
        ON dc.file_handle_id = n.file_handle_id
        AND dc.project_id = n.project_id
LEFT JOIN
    (SELECT DISTINCT file_entity_id FROM mc2_dataset_files) mdf ON mdf.file_entity_id = n.id
WHERE
    n.node_type = 'file'
    AND n.name NOT ILIKE 'synapse_storage_manifest_%view.csv'
ORDER BY 2 ASC, 8 DESC;
"""


@st.fragment
def _cell_files_browser():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### All Files with Download Counts")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_files_browser",
                help="Refresh all files data",
            ):
                execute_query.clear(query_all_files())
                if "files_browser_df" in st.session_state:
                    del st.session_state["files_browser_df"]

        # Cache full dataframe so filter/toggle interactions don't re-query Snowflake.
        if "files_browser_df" not in st.session_state:
            try:
                with st.spinner("Executing query", show_time=True):
                    df = st.session_state.session.create_async_job(
                        execute_query(query_all_files())
                    ).result("pandas")
                st.session_state["files_browser_df"] = rename_duplicate_columns(df)
            except Exception as e:
                st.error(f"Error: {str(e)}")
                return

        df = st.session_state["files_browser_df"]

        # Filters
        filter_col1, _ = st.columns([3, 1])
        with filter_col1:
            project_options = sorted(
                f"{row['PROJECT_NAME']} ({row['PROJECT_ID']})"
                for _, row in df[["PROJECT_NAME", "PROJECT_ID"]]
                .drop_duplicates()
                .iterrows()
            )
            selected_projects = st.multiselect(
                "Filter by project",
                options=project_options,
                placeholder="Select one or more projects (shows all by default)",
                key="files_browser_project_filter",
            )

        # Apply filters
        filtered_df = df.copy()
        if selected_projects:
            selected_names = {s.rsplit(" (", 1)[0] for s in selected_projects}
            filtered_df = filtered_df[filtered_df["PROJECT_NAME"].isin(selected_names)]

        total_ext_dl = int(filtered_df["EXTERNAL_DOWNLOADS"].sum())
        st.caption(
            f"{len(filtered_df):,} of {len(df):,} files · "
            f"{total_ext_dl:,} total external downloads in view"
        )

        max_ext = int(df["EXTERNAL_DOWNLOADS"].max()) if len(df) > 0 else 1
        st.dataframe(
            filtered_df.drop(columns=["PROJECT_ID"]),
            width="stretch",
            hide_index=True,
            height=500,
            column_config={
                "PROJECT_NAME": st.column_config.TextColumn("Project"),
                "FILE_SYNID": st.column_config.TextColumn("Syn ID"),
                "FILENAME": st.column_config.TextColumn("File Name"),
                "IS_PUBLIC": st.column_config.CheckboxColumn("Public*"),
                "IN_DATASET": st.column_config.CheckboxColumn("In Dataset"),
                "CREATED_ON": st.column_config.DateColumn("Created On"),
                "EXTERNAL_DOWNLOADS": st.column_config.ProgressColumn(
                    "Ext. Downloads",
                    min_value=0,
                    max_value=max_ext,
                    format="%d",
                ),
                "EXTERNAL_UNIQUE_USERS": st.column_config.NumberColumn("Ext. Unique Users"),
                "SAGE_DOWNLOADS": st.column_config.NumberColumn("Sage Downloads"),
                "SAGE_UNIQUE_USERS": st.column_config.NumberColumn("Sage Unique Users"),
                "TOTAL_DOWNLOADS": st.column_config.NumberColumn("Total Downloads"),
                "TOTAL_UNIQUE_USERS": st.column_config.NumberColumn("Total Unique Users"),
                "LATEST_DOWNLOAD_ACTIVITY": st.column_config.DateColumn("Last Download Activity"),
            },
        )


@st.fragment
def _cell_recently_added():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Recently Added Files (Last 30 Days)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_files_browser_new",
                help="Refresh recently added files",
            ):
                execute_query.clear(query_all_files())
                if "files_browser_df" in st.session_state:
                    del st.session_state["files_browser_df"]

        # Reuses the cached result from _cell_files_browser — no extra query.
        if "files_browser_df" not in st.session_state:
            try:
                with st.spinner("Executing query", show_time=True):
                    df = st.session_state.session.create_async_job(
                        execute_query(query_all_files())
                    ).result("pandas")
                st.session_state["files_browser_df"] = rename_duplicate_columns(df)
            except Exception as e:
                st.error(f"Error: {str(e)}")
                return

        df = st.session_state["files_browser_df"]

        cutoff = pd.Timestamp.now() - pd.DateOffset(days=30)
        df["CREATED_ON"] = pd.to_datetime(df["CREATED_ON"], errors="coerce")
        recent = df[df["CREATED_ON"] >= cutoff].sort_values("CREATED_ON", ascending=False)

        st.caption(f"{len(recent):,} files added in the last 30 days")
        if len(recent) == 0:
            st.info("No files have been added in the last 30 days.")
        else:
            st.dataframe(
                recent.drop(columns=["PROJECT_ID"]),
                width="stretch",
                hide_index=True,
                column_config={
                    "PROJECT_NAME": st.column_config.TextColumn("Project"),
                    "FILE_SYNID": st.column_config.TextColumn("Syn ID"),
                    "FILENAME": st.column_config.TextColumn("File Name"),
                    "IS_PUBLIC": st.column_config.CheckboxColumn("Public*"),
                    "IN_DATASET": st.column_config.CheckboxColumn("In Dataset"),
                    "CREATED_ON": st.column_config.DateColumn("Created On"),
                    "EXTERNAL_DOWNLOADS": st.column_config.NumberColumn("Ext. Downloads"),
                    "EXTERNAL_UNIQUE_USERS": st.column_config.NumberColumn("Ext. Unique Users"),
                    "SAGE_DOWNLOADS": st.column_config.NumberColumn("Sage Downloads"),
                    "SAGE_UNIQUE_USERS": st.column_config.NumberColumn("Sage Unique Users"),
                    "TOTAL_DOWNLOADS": st.column_config.NumberColumn("Total Downloads"),
                    "TOTAL_UNIQUE_USERS": st.column_config.NumberColumn("Total Unique Users"),
                    "LATEST_DOWNLOAD_ACTIVITY": st.column_config.DateColumn("Last Download Activity"),
                },
            )


def prefetch():
    execute_query(query_all_files())


def _cell_download_count_note():
    with st.container(border=True):
        st.markdown("##### About Download Counts")
        st.markdown(
            "Each file's download count reflects how many times that specific file's "
            "content was downloaded. In Synapse, multiple file entities can reference the "
            "same underlying file handle; for example, when a file is copied or linked "
            "to another project."
        )
        st.markdown(
            "Because of this, **summing the download counts across files in a project "
            "can overcount**. That is, the same download event can be attributed to each "
            "file entity that shares that file handle."
        )
        st.markdown(
            "For the most accurate project-level download counts, see the **Overview tab**."
        )


def _cell_recently_added_note():
    with st.container(border=True):
        st.markdown("##### About Recently Added Files")
        st.markdown(
            "This table shows file nodes across MC2 Center projects that have at least one download, whose "
            "`created_on` date falls within the last 30 days."
        )
        st.markdown(
            "It includes download counts so you can quickly see whether newly added "
            "files are already being accessed."
        )


def render():
    col_browser, col_note = st.columns([3, 1])
    with col_browser:
        _cell_files_browser()
    with col_note:
        _cell_download_count_note()
    col_recent, col_recent_note = st.columns([3, 1])
    with col_recent:
        _cell_recently_added()
    with col_recent_note:
        _cell_recently_added_note()
