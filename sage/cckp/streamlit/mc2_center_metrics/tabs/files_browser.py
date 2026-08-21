"""Files Browser tab — all MC2 project files with download counts."""
import pandas as pd
import streamlit as st

from utils import (
    CTE_MC2_DATASET_FILES,
    CTE_MC2_DATASET_NODES,
    CTE_SYNAPSE_USERS,
    MANIFEST_FILTER,
    rename_duplicate_columns,
    execute_query,
)


def query_all_files() -> str:
    """
    File-level breakdown for external user downloads.

    Uses a LEFT JOIN so files that have never been downloaded still appear.
    """
    return f"""
        WITH
            {CTE_SYNAPSE_USERS},
            {CTE_MC2_DATASET_NODES},
            {CTE_MC2_DATASET_FILES},
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
            'syn' || n.id::STRING AS file_synid,
            n.name AS filename,
            n.project_name,
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
            -- TODO: fix source table to remove duplicate node ids, then remove QUALIFY workaround
            -- sage.cckp.mc2_nodes AS n
            (
                SELECT *
                FROM sage.cckp.mc2_nodes
                QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY change_timestamp DESC) = 1
            ) AS n
        LEFT JOIN
            download_counts dc
                ON dc.file_handle_id = n.file_handle_id
                AND dc.project_id = n.project_id
        LEFT JOIN
            (SELECT DISTINCT file_entity_id FROM mc2_dataset_files) mdf ON mdf.file_entity_id = n.id
        WHERE
            n.node_type = 'file'
            AND n.name NOT ILIKE '{MANIFEST_FILTER}'
        ORDER BY 4 ASC, 9 DESC;
        """


def query_projects_without_files() -> str:
    """Get projects that have no files for comprehensive analysis."""
    return f"""
        SELECT
            'syn' || p.project_id::STRING AS syn_id,
            p.project_name
        FROM
            (SELECT DISTINCT project_id, project_name FROM sage.cckp.mc2_projects) p
        LEFT JOIN
            sage.cckp.mc2_nodes n
                ON n.project_id = p.project_id
                AND n.node_type = 'file'
                AND n.name NOT ILIKE '{MANIFEST_FILTER}'
        WHERE
            n.id IS NULL
        ORDER BY p.project_name ASC;
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
                st.markdown("### All Files Browser")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_files_browser",
                help="Refresh all files data",
            ):
                execute_query.clear(query_all_files())
                if "files_browser_df" in st.session_state:
                    del st.session_state["files_browser_df"]
                if "files_browser_qid" in st.session_state:
                    del st.session_state["files_browser_qid"]

        # Reuses the cached result if available, otherwise executes the query and caches the result
        current_qid = execute_query(query_all_files())
        if (
            "files_browser_df" not in st.session_state
            or st.session_state.get("files_browser_qid") != current_qid
        ):
            try:
                with st.spinner("Executing query", show_time=True):
                    df = st.session_state.session.create_async_job(current_qid).result("pandas")
                st.session_state["files_browser_df"] = rename_duplicate_columns(df)
                st.session_state["files_browser_qid"] = current_qid
            except Exception as e:
                st.error(f"Error: {str(e)}")
                return
        df = st.session_state["files_browser_df"]

        with st.expander("Why might total download counts here differ from the **Overview** tab?"):
            st.markdown(
                """
                Summing file-level counts in this table may yield a higher number than shown in **Overview**.
                When a file is copied or linked across multiple folders (e.g. `Pt42.csv` in the "H Lee Moffitt
                Cancer Center and Research Institute" project), downloading it once will add +1 to each copy.

                For true, deduplicated project totals, refer to the **Overview** tab.
                """
            )

        filter_col1, filter_col2, filter_col3 = st.columns([3, 1, 1])
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
                placeholder="All projects",
                key="files_browser_project_filter",
            )
        with filter_col2:
            public_filter = st.selectbox(
                "Publicly viewable?",
                options=["All", "Yes", "No"],
                key="files_browser_public_filter",
            )
        with filter_col3:
            dataset_filter = st.selectbox(
                "Part of a dataset?",
                options=["All", "Yes", "No"],
                key="files_browser_dataset_filter",
            )
        
        mask = pd.Series(True, index=df.index)
        if selected_projects:
            selected_names = {s.rsplit(" (", 1)[0] for s in selected_projects}
            mask &= df["PROJECT_NAME"].isin(selected_names)
        if public_filter != "All":
            mask &= df["IS_PUBLIC"] == (public_filter == "Yes")
        if dataset_filter != "All":
            mask &= df["IN_DATASET"] == (dataset_filter == "Yes")
        filtered_df = df[mask].sort_values("EXTERNAL_DOWNLOADS", ascending=False)

        total_ext_dl = int(filtered_df["EXTERNAL_DOWNLOADS"].sum())
        n_projects = filtered_df["PROJECT_NAME"].nunique()
        st.caption(
            f"{len(filtered_df):,} files · "
            f"{n_projects:,} projects · "
            f"{total_ext_dl:,} external user downloads in view"
        )

        max_ext = int(df["EXTERNAL_DOWNLOADS"].max()) if len(df) > 0 else 1
        st.dataframe(
            filtered_df.drop(columns=["PROJECT_ID"]),
            width="stretch",
            hide_index=True,
            height=500,
            column_config={
                "FILE_SYNID": st.column_config.TextColumn("File synID"),
                "FILENAME": st.column_config.TextColumn("File Name"),
                "PROJECT_NAME": st.column_config.TextColumn("Project"),
                "IS_PUBLIC": st.column_config.CheckboxColumn("Public"),
                "IN_DATASET": st.column_config.CheckboxColumn("In Dataset"),
                "CREATED_ON": st.column_config.DateColumn("Created On"),
                "EXTERNAL_DOWNLOADS": st.column_config.ProgressColumn(
                    "External User Downloads",
                    min_value=0,
                    max_value=max_ext,
                    format="%d",
                ),
                "EXTERNAL_UNIQUE_USERS": st.column_config.NumberColumn("Unique External Users"),
                "SAGE_DOWNLOADS": st.column_config.NumberColumn("Sage Downloads"),
                "SAGE_UNIQUE_USERS": st.column_config.NumberColumn("Sage Unique Users"),
                "TOTAL_DOWNLOADS": st.column_config.NumberColumn("Total Downloads"),
                "TOTAL_UNIQUE_USERS": st.column_config.NumberColumn("Total Unique Users"),
                "LATEST_DOWNLOAD_ACTIVITY": st.column_config.DateColumn("Last Download Activity"),
            },
        )


@st.fragment
def _cell_projects_without_files():
    current_qid = execute_query(query_projects_without_files())
    if (
        "projects_without_files_df" not in st.session_state
        or st.session_state.get("projects_without_files_qid") != current_qid
    ):
        try:
            with st.spinner("Executing query", show_time=True):
                df = st.session_state.session.create_async_job(current_qid).result("pandas")
            st.session_state["projects_without_files_df"] = rename_duplicate_columns(df)
            st.session_state["projects_without_files_qid"] = current_qid
        except Exception as e:
            st.error(f"Error: {str(e)}")
            return

    df = st.session_state["projects_without_files_df"]
    with st.expander(f"Projects with no files ({len(df):,})"):
        if len(df) == 0:
            st.success("All projects have at least one file.")
        else:
            st.dataframe(
                df,
                width="stretch",
                hide_index=True,
                column_config={
                    "SYN_ID": st.column_config.TextColumn("Project SynID"),
                    "PROJECT_NAME": st.column_config.TextColumn("Project"),
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
                if "files_browser_qid" in st.session_state:
                    del st.session_state["files_browser_qid"]

        current_qid = execute_query(query_all_files())
        if (
            "files_browser_df" not in st.session_state
            or st.session_state.get("files_browser_qid") != current_qid
        ):
            try:
                with st.spinner("Executing query", show_time=True):
                    df = st.session_state.session.create_async_job(current_qid).result("pandas")
                st.session_state["files_browser_df"] = rename_duplicate_columns(df)
                st.session_state["files_browser_qid"] = current_qid
            except Exception as e:
                st.error(f"Error: {str(e)}")
                return
        df = st.session_state["files_browser_df"]

        cutoff = pd.Timestamp.now() - pd.DateOffset(days=30)
        df["CREATED_ON"] = pd.to_datetime(df["CREATED_ON"], errors="coerce")
        recent = df[df["CREATED_ON"] >= cutoff].sort_values("CREATED_ON", ascending=False)

        st.caption(
            f"{len(recent):,} files · "
            f"{recent['PROJECT_NAME'].nunique():,} projects · "
            f"{int(recent['EXTERNAL_DOWNLOADS'].sum()):,} external user downloads in view"
        )
        if len(recent) == 0:
            st.info("No files have been added in the last 30 days.")
        else:
            st.dataframe(
                recent.drop(columns=["PROJECT_ID"]),
                width="stretch",
                hide_index=True,
                column_config={
                    "FILE_SYNID": st.column_config.TextColumn("File synID"),
                    "FILENAME": st.column_config.TextColumn("File Name"),
                    "PROJECT_NAME": st.column_config.TextColumn("Project"),
                    "IS_PUBLIC": st.column_config.CheckboxColumn("Public*"),
                    "IN_DATASET": st.column_config.CheckboxColumn("In Dataset"),
                    "CREATED_ON": st.column_config.DateColumn("Created On"),
                    "EXTERNAL_DOWNLOADS": st.column_config.NumberColumn("External User Downloads"),
                    "EXTERNAL_UNIQUE_USERS": st.column_config.NumberColumn("Unique External Users"),
                    "SAGE_DOWNLOADS": st.column_config.NumberColumn("Sage Downloads"),
                    "SAGE_UNIQUE_USERS": st.column_config.NumberColumn("Sage Unique Users"),
                    "TOTAL_DOWNLOADS": st.column_config.NumberColumn("Total Downloads"),
                    "TOTAL_UNIQUE_USERS": st.column_config.NumberColumn("Total Unique Users"),
                    "LATEST_DOWNLOAD_ACTIVITY": st.column_config.DateColumn("Last Download Activity"),
                },
            )


def prefetch():
    execute_query(query_all_files())
    execute_query(query_projects_without_files())


def render():
    _cell_files_browser()
    _cell_projects_without_files()
    _cell_recently_added()
