"""Datasets tab."""
import streamlit as st

from utils import (
    SQL_CTE_MC2_DATASET_FILES,
    SQL_CTE_MC2_DATASET_NODES,
    SQL_CTE_NODES_WITH_PARENT,
    SQL_CTE_NON_SAGERS,
    rename_duplicate_columns,
    execute_query,
)


def query_dataset_summary() -> str:
    """One row per CCKP dataset with download totals and unique external users.

    Uses a LEFT JOIN so datasets that have never been downloaded still appear.
    Unique-user count is computed at dataset level.
    """
    return f"""
WITH
    {SQL_CTE_NON_SAGERS},
    {SQL_CTE_NODES_WITH_PARENT},
    {SQL_CTE_MC2_DATASET_NODES},
    {SQL_CTE_MC2_DATASET_FILES},
    -- Dataset-level download events, scoped to MC2 projects and non-Sagers only.
    dataset_events AS (
        SELECT
            f.dataset_name,
            f.project_id,
            dl.user_id,
            dl.record_date
        FROM
            mc2_dataset_files f
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
    d.dataset_name,
    d.project_name,
    d.matched_rule,
    COUNT(DISTINCT f.file_entity_id) AS total_files,
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
GROUP BY 1, 2, 3, 5, 6, 7
ORDER BY 5 DESC NULLS LAST;
"""


def query_dataset_files() -> str:
    """One row per file in CCKP-annotated datasets, with access-type flags.

    Uses LEFT JOIN so files with zero downloads are included.
    """
    return f"""
WITH
    {SQL_CTE_NON_SAGERS},
    {SQL_CTE_NODES_WITH_PARENT},
    {SQL_CTE_MC2_DATASET_NODES},
    {SQL_CTE_MC2_DATASET_FILES},
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
    COALESCE(edc.external_downloads, 0) AS external_downloads,
    COALESCE(edc.external_unique_users, 0) AS external_unique_users,
    edc.last_download_activity
FROM
    mc2_dataset_files f
LEFT JOIN
    external_dl_counts edc
        ON edc.file_handle_id = f.file_handle_id
        AND edc.project_id    = f.project_id
LEFT JOIN
    sage.cckp.mc2_nodes n ON n.id = f.file_entity_id
ORDER BY 3 ASC, 8 DESC;
"""


@st.fragment
def _cell_dataset_summary():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Dataset Summary")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_datasets_summary",
                help="Refresh dataset summary",
            ):
                execute_query.clear(query_dataset_summary())

        try:
            with st.spinner("Executing query", show_time=True):
                df = st.session_state.session.create_async_job(
                    execute_query(query_dataset_summary())
                ).result("pandas")
            df = rename_duplicate_columns(df)
            max_dl = int(df["EXTERNAL_DOWNLOADS"].max()) if len(df) > 0 else 1
            st.caption(f"{len(df):,} rows")
            st.dataframe(
                df,
                width="stretch",
                hide_index=True,
                column_config={
                    "DATASET_NAME": st.column_config.TextColumn("Dataset"),
                    "PROJECT_NAME": st.column_config.TextColumn("Project"),
                    "MATCHED_RULE": st.column_config.TextColumn("Rule"),
                    "TOTAL_FILES": st.column_config.NumberColumn("Files"),
                    "EXTERNAL_DOWNLOADS": st.column_config.ProgressColumn(
                        "External Downloads",
                        min_value=0,
                        max_value=max_dl,
                        format="%d",
                    ),
                    "EXTERNAL_UNIQUE_USERS": st.column_config.NumberColumn(
                        "Ext. Unique Users"
                    ),
                    "LAST_DOWNLOAD_ACTIVITY": st.column_config.DateColumn(
                        "Last Download"
                    ),
                },
            )
        except Exception as e:
            st.error(f"Error: {str(e)}")


@st.fragment
def _cell_file_detail():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Dataset File Detail")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_datasets_files",
                help="Refresh file detail",
            ):
                execute_query.clear(query_dataset_files())
                if "datasets_files_df" in st.session_state:
                    del st.session_state["datasets_files_df"]

        # Cache full dataframe in session_state so the filter selectbox
        # reruns don't trigger a new Snowflake query.
        if "datasets_files_df" not in st.session_state:
            try:
                with st.spinner("Executing query", show_time=True):
                    df = st.session_state.session.create_async_job(
                        execute_query(query_dataset_files())
                    ).result("pandas")
                st.session_state["datasets_files_df"] = rename_duplicate_columns(df)
            except Exception as e:
                st.error(f"Error: {str(e)}")
                return

        df = st.session_state["datasets_files_df"]

        dataset_options = sorted(df["DATASET_NAME"].dropna().unique())
        selected = st.multiselect(
            "Filter by dataset",
            options=dataset_options,
            placeholder="Select one or more datasets (shows all by default)",
            key="datasets_files_filter",
        )
        filtered = df[df["DATASET_NAME"].isin(selected)] if selected else df

        st.caption(f"{len(filtered):,} of {len(df):,} rows" if selected else f"{len(df):,} rows")
        st.dataframe(
            filtered,
            width="stretch",
            hide_index=True,
            height=450,
            column_config={
                "FILE_SYNID": st.column_config.TextColumn("Syn ID"),
                "FILE_NAME": st.column_config.TextColumn("File Name"),
                "DATASET_NAME": st.column_config.TextColumn("Dataset"),
                "PROJECT_NAME": st.column_config.TextColumn("Project"),
                "IS_PUBLIC": st.column_config.CheckboxColumn("Public"),
                "EXTERNAL_DOWNLOADS": st.column_config.NumberColumn("Ext. Downloads"),
                "EXTERNAL_UNIQUE_USERS": st.column_config.NumberColumn("Ext. Unique Users"),
                "LAST_DOWNLOAD_ACTIVITY": st.column_config.DateColumn("Last Download"),
            },
        )


def prefetch():
    execute_query(query_dataset_summary())
    execute_query(query_dataset_files())


def _cell_dataset_rules():
    with st.container(border=True):
        st.markdown("##### What Counts as a Dataset?")
        st.markdown(
            "A node is counted as a dataset if it meets **any** of the following criteria:\n\n"
            "1. **Entity type:** `node_type` is `dataset` or `datasetcollection`\n\n"
            "2. **Annotations:** `node_type` is `file` or `folder` with the annotations: `portal = CCKP` & `entityType = dataset`\n\n"
            "3. **`datasets` parent folder:** `node_type` is an unannotated `file` with a parent folder named \"datasets\""
        )


def render():
    col_summary, col_rules = st.columns([3, 1])
    with col_summary:
        _cell_dataset_summary()
    with col_rules:
        _cell_dataset_rules()
    _cell_file_detail()
