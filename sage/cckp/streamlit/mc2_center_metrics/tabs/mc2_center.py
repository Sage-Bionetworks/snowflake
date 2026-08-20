"""MC2 Center tab — metrics scoped to the MC2 Center project.

Syn ID: syn7080714
"""
import pandas as pd
import streamlit as st

from utils import (
    SQL_CTE_NON_SAGERS,
    SQL_CTE_SYNAPSE_USERS,
    GRANULARITY_OPTIONS,
    RESAMPLE_FREQ,
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
        SELECT
            file_handle_id,
            id AS node_id, name
        FROM
            synapse_data_warehouse.synapse.node_latest
        WHERE
            project_id = {_PROJECT_ID}
            AND node_type = 'file'
    ),
    events AS (
        SELECT
            dl.user_id,
            dl.record_date,
            dl.file_handle_id
        FROM
            synapse_data_warehouse.synapse_event.objectdownload_event dl
        INNER JOIN
            non_sagers ON dl.user_id = non_sagers.user_id
        INNER JOIN
            project_files ON dl.file_handle_id = project_files.file_handle_id
        WHERE
            dl.project_id = {_PROJECT_ID}
    )

SELECT
    (SELECT COUNT(DISTINCT parent_id) FROM synapse_data_warehouse.synapse.node_latest
     WHERE project_id = {_PROJECT_ID} AND node_type = 'file'
       AND name NOT ILIKE 'synapse_storage_manifest_%view.csv') AS total_folders,
    (SELECT COUNT(*) FROM project_files) AS total_files,
    (SELECT COUNT(*) FROM synapse_data_warehouse.synapse.node_latest
     WHERE project_id = {_PROJECT_ID} AND node_type = 'file' AND is_public = TRUE) AS public_files,
    COUNT(*) AS total_external_downloads,
    COUNT(DISTINCT user_id) AS total_external_users,
    COUNT_IF(record_date >= CURRENT_DATE - 30) AS downloads_last_30d,
    COUNT_IF(record_date >= CURRENT_DATE - 60
             AND record_date < CURRENT_DATE - 30) AS downloads_prior_30d
FROM events;
"""


def query_daily_downloads() -> str:
    """Daily external download counts for the MC2 Center project."""
    return f"""
WITH
    {SQL_CTE_NON_SAGERS},
    project_files AS (
        SELECT
            file_handle_id
        FROM
            synapse_data_warehouse.synapse.node_latest
        WHERE
            project_id = {_PROJECT_ID}
            AND node_type = 'file'
    )

SELECT
    dl.record_date,
    COUNT(*) AS external_downloads
FROM
    synapse_data_warehouse.synapse_event.objectdownload_event dl
INNER JOIN
    non_sagers ON dl.user_id = non_sagers.user_id
INNER JOIN
    project_files ON dl.file_handle_id = project_files.file_handle_id
WHERE
    dl.project_id = {_PROJECT_ID}
GROUP BY 1
ORDER BY 1 ASC;
"""


def query_files_browser() -> str:
    """All files in the MC2 Center project."""
    return f"""
WITH
    {SQL_CTE_SYNAPSE_USERS},
    download_counts AS (
        SELECT
            dl.file_handle_id,
            COUNT_IF(u.user_type = 'External') AS external_downloads,
            COUNT(DISTINCT CASE WHEN u.user_type = 'External' THEN dl.user_id END) AS external_unique_users,
            COUNT_IF(u.user_type = 'Sager') AS sage_downloads,
            COUNT(*) AS total_downloads,
            MAX(dl.record_date) AS latest_download_activity
        FROM
            synapse_data_warehouse.synapse_event.objectdownload_event AS dl
        INNER JOIN
            synapse_users u ON dl.user_id = u.id
        WHERE
            dl.project_id = {_PROJECT_ID}
        GROUP BY 1
    )

SELECT
    'syn' || n.id::STRING AS file_synid,
    n.name AS filename,
    n.parent_id AS folder_id,
    COALESCE(p.name, 'Root') AS folder_name,
    n.is_public,
    n.change_timestamp::DATE AS created_on,
    COALESCE(dc.external_downloads, 0) AS external_downloads,
    COALESCE(dc.external_unique_users, 0) AS external_unique_users,
    COALESCE(dc.sage_downloads, 0) AS sage_downloads,
    COALESCE(dc.total_downloads, 0) AS total_downloads,
    dc.latest_download_activity
FROM
    synapse_data_warehouse.synapse.node_latest AS n
INNER JOIN
    download_counts dc ON dc.file_handle_id = n.file_handle_id
LEFT JOIN
    synapse_data_warehouse.synapse.node_latest AS p ON n.parent_id = p.id
WHERE
    n.project_id = {_PROJECT_ID}
    AND n.node_type = 'file'
    AND n.name NOT ILIKE 'synapse_storage_manifest_%view.csv'
ORDER BY 7 DESC;
"""


def query_new_external_users() -> str:
    """Monthly count of users whose first MC2 Center download fell in each period."""
    return f"""
WITH
    {SQL_CTE_NON_SAGERS},
    project_files AS (
        SELECT file_handle_id
        FROM synapse_data_warehouse.synapse.node_latest
        WHERE
            project_id = {_PROJECT_ID}
            AND node_type = 'file'
    ),
    first_downloads AS (
        SELECT
            dl.user_id,
            MIN(dl.record_date) AS first_download_date
        FROM
            synapse_data_warehouse.synapse_event.objectdownload_event dl
        INNER JOIN
            non_sagers ON dl.user_id = non_sagers.user_id
        INNER JOIN
            project_files ON dl.file_handle_id = project_files.file_handle_id
        WHERE
            dl.project_id = {_PROJECT_ID}
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


def query_top_users() -> str:
    """Top external users by download count for the MC2 Center project."""
    return f"""
WITH
    {SQL_CTE_NON_SAGERS},
    project_files AS (
        SELECT
            file_handle_id
        FROM
            synapse_data_warehouse.synapse.node_latest
        WHERE
            project_id = {_PROJECT_ID}
            AND node_type = 'file'
    )

SELECT
    ns.user_name,
    COUNT(*) AS external_downloads,
    MIN(dl.record_date) AS first_download,
    MAX(dl.record_date) AS last_download
FROM
    synapse_data_warehouse.synapse_event.objectdownload_event dl
INNER JOIN
    non_sagers ns ON dl.user_id = ns.user_id
INNER JOIN
    project_files ON dl.file_handle_id = project_files.file_handle_id
WHERE
    dl.project_id = {_PROJECT_ID}
GROUP BY 1
ORDER BY 2 DESC
LIMIT 50;
"""


def query_file_type_breakdown() -> str:
    """External download counts grouped by file extension."""
    return f"""
WITH
    {SQL_CTE_NON_SAGERS},
    project_files AS (
        SELECT
            file_handle_id,
            name
        FROM
            synapse_data_warehouse.synapse.node_latest
        WHERE
            project_id = {_PROJECT_ID}
            AND node_type = 'file'
    )

SELECT
    COALESCE(LOWER(REGEXP_SUBSTR(pf.name, '\\\\.[^.]+$')), '(no extension)') AS file_extension,
    COUNT(*) AS external_downloads,
    COUNT(DISTINCT dl.user_id) AS external_unique_users
FROM
    synapse_data_warehouse.synapse_event.objectdownload_event dl
INNER JOIN
    non_sagers ON dl.user_id = non_sagers.user_id
INNER JOIN
    project_files pf ON dl.file_handle_id = pf.file_handle_id
WHERE
    dl.project_id = {_PROJECT_ID}
GROUP BY 1
ORDER BY 2 DESC;
"""


def query_downloads_by_folder() -> str:
    """External download counts grouped by the immediate parent folder."""
    return f"""
WITH
    {SQL_CTE_NON_SAGERS},
    project_files AS (
        SELECT
            child.file_handle_id,
            COALESCE(parent.name, 'Root') AS folder_name
        FROM
            synapse_data_warehouse.synapse.node_latest child
        LEFT JOIN synapse_data_warehouse.synapse.node_latest parent
            ON child.parent_id = parent.id
        WHERE
            child.project_id = {_PROJECT_ID}
            AND child.node_type = 'file'
    )

SELECT
    pf.folder_name,
    COUNT(DISTINCT dl.file_handle_id) AS unique_files_downloaded,
    COUNT(*) AS external_downloads,
    COUNT(DISTINCT dl.user_id) AS external_unique_users
FROM
    synapse_data_warehouse.synapse_event.objectdownload_event dl
INNER JOIN
    non_sagers ON dl.user_id = non_sagers.user_id
INNER JOIN
    project_files pf ON dl.file_handle_id = pf.file_handle_id
WHERE
    dl.project_id = {_PROJECT_ID}
GROUP BY 1
ORDER BY 3 DESC;
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

        total_files = int(row["TOTAL_FILES"])
        public_files = int(row["PUBLIC_FILES"])
        public_pct = round(100 * public_files / total_files) if total_files else 0

        last_30d = int(row["DOWNLOADS_LAST_30D"])
        prior_30d = int(row["DOWNLOADS_PRIOR_30D"])

        c1, c2, c3, c4 = st.columns(4)
        c1.metric("Folders", f"{int(row['TOTAL_FOLDERS']):,}")
        c2.metric("Files", f"{total_files:,}")
        c3.metric("Public* Files", f"{public_files:,}",
                  delta=f"{public_pct}% of all files", delta_color="off")
        c4.metric("External Users", f"{int(row['TOTAL_EXTERNAL_USERS']):,}")

        st.divider()

        d1, d2, d3 = st.columns(3)
        d1.metric("Total External Downloads", f"{int(row['TOTAL_EXTERNAL_DOWNLOADS']):,}")
        d2.metric("External Downloads (last 30 days)", f"{last_30d:,}",
                  delta=f"{last_30d - prior_30d:+,} vs prior 30 days",
                  delta_color="normal")
        d3.metric("External Downloads (prior 30 days)", f"{prior_30d:,}")
    except Exception as e:
        st.error(f"Error: {e}")


@st.fragment
def _cell_trends():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Monthly External Downloads")
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
            st.bar_chart(df.set_index("RECORD_DATE")["EXTERNAL_DOWNLOADS"], height=280)
        except Exception as e:
            st.error(f"Error: {e}")


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
                key="refresh_mc2_files_browser",
                help="Refresh files",
            ):
                execute_query.clear(query_files_browser())
                if "mc2_files_browser_df" in st.session_state:
                    del st.session_state["mc2_files_browser_df"]

        if "mc2_files_browser_df" not in st.session_state:
            try:
                with st.spinner("Loading file data", show_time=True):
                    df = st.session_state.session.create_async_job(
                        execute_query(query_files_browser())
                    ).result("pandas")
                st.session_state["mc2_files_browser_df"] = rename_duplicate_columns(df)
            except Exception as e:
                st.error(f"Error: {e}")
                return

        df = st.session_state["mc2_files_browser_df"]

        col_folder, col_public = st.columns([3, 1])
        with col_folder:
            folder_options = sorted(df["FOLDER_NAME"].dropna().unique())
            selected_folders = st.multiselect(
                "Filter by folder",
                options=folder_options,
                placeholder="All folders",
                key="mc2_files_browser_folder_filter",
            )
        with col_public:
            public_filter = st.selectbox(
                "Public",
                options=["All", "Yes", "No"],
                key="mc2_files_browser_public_filter",
            )

        filtered = df.copy()
        if selected_folders:
            filtered = filtered[filtered["FOLDER_NAME"].isin(selected_folders)]
        if public_filter == "Yes":
            filtered = filtered[filtered["IS_PUBLIC"] == True]
        elif public_filter == "No":
            filtered = filtered[filtered["IS_PUBLIC"] == False]

        max_ext = max(1, int(df["EXTERNAL_DOWNLOADS"].max())) if len(df) else 1
        st.caption(
            f"{len(filtered):,} files · "
            f"{filtered['FOLDER_ID'].nunique():,} folders · "
            f"{int(filtered['EXTERNAL_DOWNLOADS'].sum()):,} external downloads in view"
        )
        st.dataframe(
            filtered.drop(columns=["FOLDER_ID"]),
            width="stretch",
            hide_index=True,
            height=450,
            column_config={
                "FILE_SYNID": st.column_config.TextColumn("File synID"),
                "FILENAME": st.column_config.TextColumn("File Name"),
                "FOLDER_NAME": st.column_config.TextColumn("Folder"),
                "IS_PUBLIC": st.column_config.CheckboxColumn("Public*"),
                "CREATED_ON": st.column_config.DateColumn("Created On"),
                "EXTERNAL_DOWNLOADS": st.column_config.ProgressColumn(
                    "External Downloads",
                    min_value=0,
                    max_value=max_ext,
                    format="%d",
                ),
                "EXTERNAL_UNIQUE_USERS": st.column_config.NumberColumn("External Unique Users"),
                "SAGE_DOWNLOADS": st.column_config.NumberColumn("Sage Downloads"),
                "TOTAL_DOWNLOADS": st.column_config.NumberColumn("Total Downloads"),
                "LATEST_DOWNLOAD_ACTIVITY": st.column_config.DateColumn("Last Download Activity"),
            },
        )


@st.fragment
def _cell_new_users():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Cumulative External Downloads")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_mc2_new_users",
                help="Refresh cumulative chart",
            ):
                execute_query.clear(query_new_external_users())

        try:
            with st.spinner("Loading data", show_time=True):
                df = st.session_state.session.create_async_job(
                    execute_query(query_daily_downloads())
                ).result("pandas")
            df = rename_duplicate_columns(df)
            df["RECORD_DATE"] = pd.to_datetime(df["RECORD_DATE"])
            df = df.set_index("RECORD_DATE").resample("MS").sum().reset_index()
            cumulative = df.copy()
            cumulative["CUMULATIVE"] = cumulative["EXTERNAL_DOWNLOADS"].cumsum()
            st.area_chart(cumulative.set_index("RECORD_DATE")["CUMULATIVE"], height=280)
        except Exception as e:
            st.error(f"Error: {e}")


@st.fragment
def _cell_new_external_users():
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
                key="refresh_mc2_new_external_users",
                help="Refresh new users chart",
            ):
                execute_query.clear(query_new_external_users())

        try:
            with st.spinner("Loading data", show_time=True):
                df = st.session_state.session.create_async_job(
                    execute_query(query_new_external_users())
                ).result("pandas")
            df = rename_duplicate_columns(df)
            df["RECORD_DATE"] = pd.to_datetime(df["RECORD_DATE"])
            df = df.set_index("RECORD_DATE").resample("MS").sum().reset_index()
            st.bar_chart(df.set_index("RECORD_DATE")["NEW_EXTERNAL_USERS"], height=280)
        except Exception as e:
            st.error(f"Error: {e}")


@st.fragment
def _cell_top_users():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Top External Users")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_mc2_top_users",
                help="Refresh top users",
            ):
                execute_query.clear(query_top_users())

        try:
            with st.spinner("Loading data", show_time=True):
                df = st.session_state.session.create_async_job(
                    execute_query(query_top_users())
                ).result("pandas")
            df = rename_duplicate_columns(df)
            st.caption(f"{len(df):,} users")
            st.dataframe(
                df,
                width="stretch",
                hide_index=True,
                height=400,
                column_config={
                    "USER_NAME": st.column_config.TextColumn("Username"),
                    "EXTERNAL_DOWNLOADS": st.column_config.ProgressColumn(
                        "External Downloads",
                        min_value=0,
                        max_value=int(df["EXTERNAL_DOWNLOADS"].max()) if len(df) else 1,
                        format="%d",
                    ),
                    "FIRST_DOWNLOAD": st.column_config.DateColumn("First Download"),
                    "LAST_DOWNLOAD": st.column_config.DateColumn("Last Download Activity"),
                },
            )
        except Exception as e:
            st.error(f"Error: {e}")


@st.fragment
def _cell_file_type_breakdown():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Downloads by File Type")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_mc2_file_types",
                help="Refresh file type breakdown",
            ):
                execute_query.clear(query_file_type_breakdown())

        try:
            with st.spinner("Loading data", show_time=True):
                df = st.session_state.session.create_async_job(
                    execute_query(query_file_type_breakdown())
                ).result("pandas")
            df = rename_duplicate_columns(df)
            st.caption(f"{int(df['EXTERNAL_DOWNLOADS'].sum()):,} external downloads in view")
            st.dataframe(
                df,
                width="stretch",
                hide_index=True,
                column_config={
                    "FILE_EXTENSION": st.column_config.TextColumn("Extension"),
                    "EXTERNAL_DOWNLOADS": st.column_config.ProgressColumn(
                        "External Downloads",
                        min_value=0,
                        max_value=int(df["EXTERNAL_DOWNLOADS"].max()) if len(df) else 1,
                        format="%d",
                    ),
                    "EXTERNAL_UNIQUE_USERS": st.column_config.NumberColumn("External Unique Users"),
                },
            )
        except Exception as e:
            st.error(f"Error: {e}")


@st.fragment
def _cell_downloads_by_folder():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Downloads by Folder")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_mc2_folders",
                help="Refresh folder breakdown",
            ):
                execute_query.clear(query_downloads_by_folder())

        try:
            with st.spinner("Loading data", show_time=True):
                df = st.session_state.session.create_async_job(
                    execute_query(query_downloads_by_folder())
                ).result("pandas")
            df = rename_duplicate_columns(df)
            st.caption(f"{int(df['EXTERNAL_DOWNLOADS'].sum()):,} external downloads in view")
            st.dataframe(
                df,
                width="stretch",
                hide_index=True,
                column_config={
                    "FOLDER_NAME": st.column_config.TextColumn("Folder"),
                    "UNIQUE_FILES_DOWNLOADED": st.column_config.NumberColumn("Files"),
                    "EXTERNAL_DOWNLOADS": st.column_config.ProgressColumn(
                        "External Downloads",
                        min_value=0,
                        max_value=int(df["EXTERNAL_DOWNLOADS"].max()) if len(df) else 1,
                        format="%d",
                    ),
                    "EXTERNAL_UNIQUE_USERS": st.column_config.NumberColumn("External Unique Users"),
                },
            )
        except Exception as e:
            st.error(f"Error: {e}")


def prefetch():
    execute_query(query_kpis())
    execute_query(query_daily_downloads())
    execute_query(query_files_browser())
    execute_query(query_new_external_users())
    execute_query(query_top_users())
    execute_query(query_file_type_breakdown())
    execute_query(query_downloads_by_folder())


def render():
    st.markdown(
        "Metrics scoped to [syn7080714](https://www.synapse.org/Synapse:syn7080714)",
        unsafe_allow_html=False,
    )
    _cell_kpis()
    col_trends, col_new_users = st.columns(2)
    with col_trends:
        _cell_trends()
    with col_new_users:
        _cell_new_external_users()
    _cell_new_users()
    col_types, col_folders = st.columns(2)
    with col_types:
        _cell_file_type_breakdown()
    with col_folders:
        _cell_downloads_by_folder()
    _cell_files_browser()
    _cell_top_users()
