"""Datasets tab."""
import pandas as pd
import streamlit as st

from utils import (
    CTE_MC2_DATASET_FILES,
    CTE_MC2_DATASET_NODES,
    CTE_NON_SAGERS,
    GRANULARITY_OPTIONS,
    RESAMPLE_FREQ,
    rename_duplicate_columns,
    execute_query,
)


def query_downloads_by_dataset() -> str:
    """
    Dataset-level breakdown for external user downloads.

    Uses a LEFT JOIN so datasets that have never been downloaded still appear.
    """
    return f"""
        WITH
            {CTE_NON_SAGERS},
            {CTE_MC2_DATASET_NODES},
            {CTE_MC2_DATASET_FILES},
            dataset_events AS (
                SELECT
                    f.dataset_name,
                    f.project_id,
                    dl.user_id,
                    dl.record_date
                FROM
                    -- Deduplicate on file_handle_id so shared file content is counted once per dataset
                    (SELECT DISTINCT dataset_name, project_id, file_handle_id FROM mc2_dataset_files) f
                INNER JOIN
                    synapse_data_warehouse.synapse_event.objectdownload_event dl
                        ON dl.file_handle_id = f.file_handle_id
                        AND dl.project_id = f.project_id
                INNER JOIN
                    non_sagers ON dl.user_id = non_sagers.user_id
            ),
            dataset_dl_summary AS (
                SELECT
                    dataset_name,
                    project_id,
                    COUNT(*) AS external_downloads,
                    COUNT(DISTINCT user_id) AS external_unique_users,
                    MAX(record_date) AS last_download_activity
                FROM dataset_events
                GROUP BY 1, 2
            )

        SELECT
            'syn' || d.id::STRING AS syn_id,
            d.dataset_name,
            d.project_name,
            COUNT(DISTINCT f.file_entity_id) AS total_files,
            '' AS download_type,  -- TODO: update when downloadType annotation available
            COALESCE(s.external_downloads, 0) AS external_downloads,
            COALESCE(s.external_unique_users, 0) AS external_unique_users,
            s.last_download_activity
        FROM
            mc2_dataset_nodes d
        LEFT JOIN
            mc2_dataset_files f ON f.project_id = d.project_id AND f.dataset_name = d.dataset_name
        LEFT JOIN
            dataset_dl_summary s
                ON s.dataset_name = d.dataset_name
                AND s.project_id  = d.project_id
        GROUP BY 1, 2, 3, 5, 6, 7, 8
        ORDER BY 6 DESC NULLS LAST;
        """


def query_dataset_files() -> str:
    """
    Get all files in MC2 datasets, along with their download counts and last
    download activity.

    Uses LEFT JOIN so files with zero downloads are included.
    """
    return f"""
        WITH
            {CTE_NON_SAGERS},
            {CTE_MC2_DATASET_NODES},
            {CTE_MC2_DATASET_FILES},
            -- Scoped to MC2 projects before scanning the events table
            external_dl_counts AS (
                SELECT
                    dl.file_handle_id,
                    dl.project_id,
                    COUNT(*) AS external_downloads,
                    COUNT(DISTINCT dl.user_id) AS external_unique_users,
                    MAX(dl.record_date) AS last_download_activity
                FROM
                    synapse_data_warehouse.synapse_event.objectdownload_event dl
                INNER JOIN
                    non_sagers ON dl.user_id = non_sagers.user_id
                WHERE
                    dl.project_id IN (SELECT project_id FROM sage.cckp.mc2_projects)
                GROUP BY 1, 2
            )

        SELECT
            'syn' || f.file_entity_id::string AS file_synid,
            n.name AS file_name,
            f.dataset_name,
            f.project_name,
            n.is_public,
            '' AS download_type,  -- TODO: update when downloadType annotation available
            COALESCE(edc.external_downloads, 0) AS external_downloads,
            COALESCE(edc.external_unique_users, 0) AS external_unique_users,
            edc.last_download_activity
        FROM
            mc2_dataset_files f
        LEFT JOIN
            external_dl_counts edc
                ON edc.file_handle_id = f.file_handle_id
                AND edc.project_id = f.project_id
        LEFT JOIN
            -- TODO: fix source table to remove duplicate node ids, then remove QUALIFY workaround
            -- sage.cckp.mc2_nodes n ON n.id = f.file_entity_id
            (SELECT * FROM sage.cckp.mc2_nodes QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY change_timestamp DESC) = 1) n
                ON n.id = f.file_entity_id
        ORDER BY 3 ASC, 9 DESC;
        """


def query_dataset_downloads_over_time() -> str:
    """Daily external download counts per dataset."""
    return f"""
        WITH
            {CTE_NON_SAGERS},
            {CTE_MC2_DATASET_NODES},
            {CTE_MC2_DATASET_FILES}

        SELECT
            dl.record_date,
            f.dataset_name,
            COUNT(*) AS external_downloads
        FROM
            -- Deduplicate on file_handle_id so shared file content is counted once per dataset
            (SELECT DISTINCT dataset_name, project_id, file_handle_id FROM mc2_dataset_files) f
        INNER JOIN
            synapse_data_warehouse.synapse_event.objectdownload_event dl
                ON dl.file_handle_id = f.file_handle_id
                AND dl.project_id = f.project_id
        INNER JOIN
            non_sagers ON dl.user_id = non_sagers.user_id
        GROUP BY 1, 2
        ORDER BY 1 ASC, 2 ASC;
        """


@st.fragment
def _cell_downloads_by_dataset():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Download Counts by Dataset")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_datasets_summary",
                help="Refresh dataset summary",
            ):
                execute_query.clear(query_downloads_by_dataset())
                if "datasets_summary_df" in st.session_state:
                    del st.session_state["datasets_summary_df"]
                if "datasets_summary_qid" in st.session_state:
                    del st.session_state["datasets_summary_qid"]

        # Reuses the cached result if available, otherwise executes the query and caches the result
        current_qid = execute_query(query_downloads_by_dataset())
        if (
            "datasets_summary_df" not in st.session_state
            or st.session_state.get("datasets_summary_qid") != current_qid
        ):
            try:
                with st.spinner("Executing query", show_time=True):
                    df = st.session_state.session.create_async_job(current_qid).result("pandas")
                st.session_state["datasets_summary_df"] = rename_duplicate_columns(df)
                st.session_state["datasets_summary_qid"] = current_qid
            except Exception as e:
                st.error(f"Error: {str(e)}")
                return
        df = st.session_state["datasets_summary_df"]
        max_dl = max(1, int(df["EXTERNAL_DOWNLOADS"].max())) if len(df) > 0 else 1

        filter_col1, filter_col2 = st.columns([3, 1])
        with filter_col1:
            project_options = sorted(df["PROJECT_NAME"].dropna().unique())
            selected_projects = st.multiselect(
                "Filter by project",
                options=project_options,
                placeholder="All projects",
                key="datasets_summary_project_filter",
            )
        with filter_col2:
            dl_type_options = sorted(df["DOWNLOAD_TYPE"].dropna().unique())
            selected_dl_types = st.multiselect(
                "Filter by download type",
                options=dl_type_options,
                placeholder="All download types",
                key="datasets_summary_dl_type_filter",
            )

        mask = pd.Series(True, index=df.index)
        if selected_projects:
            mask &= df["PROJECT_NAME"].isin(selected_projects)
        if selected_dl_types:
            mask &= df["DOWNLOAD_TYPE"].isin(selected_dl_types)
        filtered = df[mask]

        st.caption(
            f"{len(filtered):,} datasets · "
            f"{int(filtered['TOTAL_FILES'].sum()):,} files · "
            f"{int(filtered['EXTERNAL_DOWNLOADS'].sum()):,} external user downloads in view"
        )
        st.dataframe(
            filtered,
            width="stretch",
            hide_index=True,
            column_config={
                "SYN_ID": st.column_config.TextColumn("Dataset synID"),
                "DATASET_NAME": st.column_config.TextColumn("Dataset"),
                "PROJECT_NAME": st.column_config.TextColumn("Project"),
                "TOTAL_FILES": st.column_config.NumberColumn("Files"),
                "DOWNLOAD_TYPE": st.column_config.TextColumn("Download Type"),
                "EXTERNAL_DOWNLOADS": st.column_config.ProgressColumn(
                    "External User Downloads",
                    min_value=0,
                    max_value=max_dl,
                    format="%d",
                ),
                "EXTERNAL_UNIQUE_USERS": st.column_config.NumberColumn(
                    "Unique External Users"
                ),
                "LAST_DOWNLOAD_ACTIVITY": st.column_config.DateColumn(
                    "Last Download Activity"
                ),
            },
        )


@st.fragment
def _cell_downloads_over_time():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Dataset Downloads Over Time")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_dataset_downloads_over_time",
                help="Refresh downloads over time",
            ):
                execute_query.clear(query_dataset_downloads_over_time())
                if "dataset_downloads_over_time_df" in st.session_state:
                    del st.session_state["dataset_downloads_over_time_df"]
                if "dataset_downloads_over_time_qid" in st.session_state:
                    del st.session_state["dataset_downloads_over_time_qid"]
    
        current_qid = execute_query(query_dataset_downloads_over_time())
        if (
            "dataset_downloads_over_time_df" not in st.session_state
            or st.session_state.get("dataset_downloads_over_time_qid") != current_qid
        ):
            try:
                with st.spinner("Executing query", show_time=True):
                    df = st.session_state.session.create_async_job(current_qid).result("pandas")
                st.session_state["dataset_downloads_over_time_df"] = rename_duplicate_columns(df)
                st.session_state["dataset_downloads_over_time_qid"] = current_qid
            except Exception as e:
                st.error(f"Error: {str(e)}")
                return
        df = st.session_state["dataset_downloads_over_time_df"]
        df["RECORD_DATE"] = pd.to_datetime(df["RECORD_DATE"])

        col_filter, col_gran = st.columns([3, 1])
        with col_filter:
            dataset_options = sorted(df["DATASET_NAME"].dropna().unique())
            selected = st.multiselect(
                "Filter by dataset",
                options=dataset_options,
                placeholder="Select one or more datasets (shows all by default)",
                key="dataset_downloads_time_filter",
            )
        with col_gran:
            granularity = st.selectbox(
                "Granularity",
                GRANULARITY_OPTIONS,
                index=2,
                key="dataset_downloads_time_granularity",
            )

        filtered = df[df["DATASET_NAME"].isin(selected)].copy() if selected else df.copy()
        if filtered.empty:
            st.info("No download data available for the selected dataset(s).")
            return

        # Reindex to the full date range so sparse datasets don't collapse the x-axis
        full_range = pd.date_range(df["RECORD_DATE"].min(), df["RECORD_DATE"].max(), freq="D")
        pivot = (
            filtered.pivot_table(
                index="RECORD_DATE",
                columns="DATASET_NAME",
                values="EXTERNAL_DOWNLOADS",
                aggfunc="sum",
            )
            .reindex(full_range, fill_value=0)
            .resample(RESAMPLE_FREQ[granularity])
            .sum()
        )
        st.line_chart(pivot, width="stretch", height=400)


@st.fragment
def _cell_file_browser():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Dataset Files Browser")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_datasets_files",
                help="Refresh file detail",
            ):
                execute_query.clear(query_dataset_files())
                if "datasets_files_df" in st.session_state:
                    del st.session_state["datasets_files_df"]
                if "datasets_files_qid" in st.session_state:
                    del st.session_state["datasets_files_qid"]

        current_qid = execute_query(query_dataset_files())
        if (
            "datasets_files_df" not in st.session_state
            or st.session_state.get("datasets_files_qid") != current_qid
        ):
            try:
                with st.spinner("Executing query", show_time=True):
                    df = st.session_state.session.create_async_job(current_qid).result("pandas")
                st.session_state["datasets_files_df"] = rename_duplicate_columns(df)
                st.session_state["datasets_files_qid"] = current_qid
            except Exception as e:
                st.error(f"Error: {str(e)}")
                return
        df = st.session_state["datasets_files_df"]

        dataset_options = sorted(df["DATASET_NAME"].dropna().unique())
        col_filter1, col_filter2 = st.columns([3, 1])
        with col_filter1:
            selected_datasets = st.multiselect(
                "Filter by dataset name",
                options=dataset_options,
                placeholder="All datasets",
                key="datasets_files_name_filter",
            )
        with col_filter2:
            dl_type_options = sorted(df["DOWNLOAD_TYPE"].dropna().unique())
            selected_dl_types = st.multiselect(
                "Filter by download type",
                options=dl_type_options,
                placeholder="All download types",
                key="datasets_files_dl_type_filter",
            )

        mask = pd.Series(True, index=df.index)
        if selected_datasets:
            mask &= df["DATASET_NAME"].isin(selected_datasets)
        if selected_dl_types:
            mask &= df["DOWNLOAD_TYPE"].isin(selected_dl_types)
        filtered = df[mask].sort_values("EXTERNAL_DOWNLOADS", ascending=False)

        st.caption(
            f"{len(filtered):,} files · "
            f"{int(filtered['EXTERNAL_DOWNLOADS'].sum()):,} external user downloads in view"
        )
        max_ext = max(1, int(df["EXTERNAL_DOWNLOADS"].max())) if len(df) > 0 else 1
        st.dataframe(
            filtered,
            width="stretch",
            hide_index=True,
            height=450,
            column_config={
                "FILE_SYNID": st.column_config.TextColumn("File synID"),
                "FILE_NAME": st.column_config.TextColumn("File Name"),
                "DATASET_NAME": st.column_config.TextColumn("Dataset"),
                "PROJECT_NAME": st.column_config.TextColumn("Project"),
                "IS_PUBLIC": st.column_config.CheckboxColumn("Public"),
                "DOWNLOAD_TYPE": st.column_config.TextColumn("Download Type"),
                "EXTERNAL_DOWNLOADS": st.column_config.ProgressColumn(
                    "External User Downloads",
                    min_value=0,
                    max_value=max_ext,
                    format="%d",
                ),
                "EXTERNAL_UNIQUE_USERS": st.column_config.NumberColumn("Unique External Users"),
                "LAST_DOWNLOAD_ACTIVITY": st.column_config.DateColumn("Last Download Activity"),
            },
        )


def prefetch():
    execute_query(query_downloads_by_dataset())
    execute_query(query_dataset_downloads_over_time())
    execute_query(query_dataset_files())


def render():
    ## TODO: remove this warning once downloadType annotation are available
    st.warning(
        """
        **Work in Progress**

        The **Download Type** column will populate as Synapse datasets are annotated with their hosting location:
        * `Synapse Hosted` - hosted in Synapse and available for download
        * `Synapse Indexed` - externally hosted but can be downloaded from Synapse
        * `Externally Hosted` - hosted externally and will need to be downloaded from the external source
        * `Not Available for Download`
        """,
        icon=":material/construction:",
    )
    _cell_downloads_by_dataset()
    _cell_downloads_over_time()
    _cell_file_browser()
