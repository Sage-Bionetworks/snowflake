import datetime as dt
import argparse
import streamlit as st
import pandas as pd
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session


def read_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--local-dev",
        action="store_true",
        help=(
            "Run in local development mode. Creates a Snowflake session using the "
            "'default' connection from ~/.snowflake/connections.toml instead of "
            "the active Streamlit in Snowflake (SiS) session. "
            "Usage: streamlit run streamlit_app.py -- --local-dev"
        ),
    )
    return parser.parse_args()


def get_session(local_dev: bool) -> Session:
    if local_dev:
        local_session = Session.builder.config("connection_name", "default").create()
        try:
            local_session.use_role("SAGE_ADMIN")
        except Exception:
            pass
        return local_session

    return get_active_session()


# Set page config
st.set_page_config(page_title="MC2 Center Metrics", layout="wide")

# Title
st.title("MC2 Center Metrics")
st.markdown(
    '<p style="color: #cc0000; font-size: 0.85rem; margin-top: -0.4rem;">'
    "This app is "
    '<a href="https://github.com/Sage-Bionetworks/snowflake/blob/dev/STREAMLIT.md" target="_blank">managed on Github</a>. '
    "Any local edits will not be retained."
    "</p>",
    unsafe_allow_html=True,
)

# Initialize session configured for generated Streamlit apps
args = read_args()
session = get_session(args.local_dev)
try:
    session.query_tag = "__generated_streamlit"
except Exception:
    pass


@st.cache_data(ttl="23h50m")
def execute_query(query: str) -> str:
    return session.sql(query).collect_nowait().query_id


def query_1_1() -> str:
    sql_query = r"""
WITH 
    -- Categorize users to distinguish Sagers from external community
    synapse_users AS (
        SELECT 
            id,
            CASE 
                WHEN email ILIKE '%@sagebase.org'
                  OR email ILIKE '%@sagebionetworks.org' THEN 'Sager'
                ELSE 'External' 
            END AS user_type
        FROM 
            synapse_data_warehouse.synapse.userprofile_latest
    )


SELECT
    project_name,

    -- Sage metrics
    COUNT_IF(synapse_users.user_type = 'Sager') AS sage_downloads,
    COUNT(DISTINCT CASE WHEN synapse_users.user_type = 'Sager' THEN dl.user_id END) AS sage_unique_users,
    
    -- External community metrics
    COUNT_IF(synapse_users.user_type = 'External') AS external_downloads,
    COUNT(DISTINCT CASE WHEN synapse_users.user_type = 'External' THEN dl.user_id END) AS external_unique_users
FROM 
    synapse_data_warehouse.synapse_event.objectdownload_event AS dl
INNER JOIN 
    data_analytics.mc2_center.mc2_projects AS mc2 
      ON dl.project_id = mc2.project_id
INNER JOIN 
    synapse_users 
      ON dl.user_id = synapse_users.id
WHERE 
    dl.file_handle_id IN (SELECT file_handle_id FROM data_analytics.mc2_center.mc2_nodes WHERE node_type = 'file')
GROUP BY
    1
ORDER BY 
    4 DESC;  """

    return sql_query


execute_query(query_1_1())


@st.fragment
def cell_1_1():
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
                key=f"refresh_button_cell_1_1",
                help="Refresh download_counts_by_project_(all-time) data",
            ):
                execute_query.clear(query_1_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_1_1())).result(
                    "pandas"
                )

            if any(df.columns.duplicated()):
                new_names = []
                name_indexes = {}
                for name in df.columns:
                    name_index = name_indexes.get(name, 0) + 1
                    name_indexes[name] = name_index
                    new_names.append(f"{name}_{name_index}" if name_index > 1 else name)
                df.columns = new_names

            if len(df) == 1 and len(df.columns) == 1:
                st.metric(
                    label=df.columns[0],
                    value=str(df.iloc[0, 0]),
                    label_visibility="collapsed",
                )
            else:
                st.dataframe(df, width="stretch", hide_index=True)
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 1: Single Cell
cell_1_1()


def query_2_1() -> str:
    sql_query = r"""
WITH 
    -- Get file names and IDs for the MC2 projects
    mc2_file_nodes AS (
        SELECT 
            id,
            name AS filename,
            file_handle_id,
            project_name
        FROM 
            data_analytics.mc2_center.mc2_nodes
        WHERE 
            node_type = 'file'
            AND filename NOT ILIKE 'synapse_storage_manifest_%view.csv'
    ),
    -- Aggregate downloads by file
    file_counts AS (
        SELECT
            project_name,
            'syn' || id::STRING AS synid,
            filename,
            COUNT(dl.record_date) AS total_downloads,
            COUNT(DISTINCT dl.user_id) AS total_unique_users,
            MAX(dl.record_date) AS latest_activity
        FROM 
            synapse_data_warehouse.synapse_event.objectdownload_event AS dl
        INNER JOIN 
            mc2_file_nodes ON dl.file_handle_id = mc2_file_nodes.file_handle_id 
        GROUP BY 
            1, 2, 3
    ),
    -- Rank files within each project
    ranked_files AS (
        SELECT 
            *,
            ROW_NUMBER() OVER (
                PARTITION BY project_name ORDER BY total_downloads DESC
            ) AS rank
        FROM 
            file_counts
    )

SELECT 
    synid,
    filename,
    project_name,
    total_downloads,
    total_unique_users,
    latest_activity
FROM 
    ranked_files
WHERE 
    rank <= 3
ORDER BY 
    3 ASC;  """

    return sql_query


execute_query(query_2_1())


@st.fragment
def cell_2_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown(
                    "### Top 3 Downloaded Files by Project (excludes manifest files)"
                )
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_1",
                help="Refresh top_3_downloaded_files_by_project_(excludes_manifest_files) data",
            ):
                execute_query.clear(query_2_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_2_1())).result(
                    "pandas"
                )

            if any(df.columns.duplicated()):
                new_names = []
                name_indexes = {}
                for name in df.columns:
                    name_index = name_indexes.get(name, 0) + 1
                    name_indexes[name] = name_index
                    new_names.append(f"{name}_{name_index}" if name_index > 1 else name)
                df.columns = new_names

            if len(df) == 1 and len(df.columns) == 1:
                st.metric(
                    label=df.columns[0],
                    value=str(df.iloc[0, 0]),
                    label_visibility="collapsed",
                )
            else:
                st.dataframe(df, width="stretch", hide_index=True)
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 2: Single Cell
cell_2_1()


def query_3_1() -> str:
    sql_query = r"""
WITH 
    -- Categorize users to distinguish Sagers from external community
    synapse_users AS (
        SELECT 
            id,
            CASE 
                WHEN email ILIKE '%@sagebase.org'
                  OR email ILIKE '%@sagebionetworks.org' THEN 'Sager'
                ELSE 'External' 
            END AS user_type
        FROM 
            synapse_data_warehouse.synapse.userprofile_latest
    )


SELECT
    date_trunc('MONTH', record_date) AS month_of_download,

    -- Sage metrics
    COUNT_IF(synapse_users.user_type = 'Sager') AS sage_downloads,
    COUNT(DISTINCT CASE WHEN synapse_users.user_type = 'Sager' THEN dl.user_id END) AS sage_unique_users,

    -- External community metrics
    COUNT_IF(synapse_users.user_type = 'External') AS external_downloads,
    COUNT(DISTINCT CASE WHEN synapse_users.user_type = 'External' THEN dl.user_id END) AS external_unique_users
FROM 
    synapse_data_warehouse.synapse_event.objectdownload_event AS dl
INNER JOIN 
    synapse_users 
      ON dl.user_id = synapse_users.id
WHERE 
    dl.project_id IN (SELECT project_id FROM data_analytics.mc2_center.mc2_projects)
    AND dl.file_handle_id IN (SELECT file_handle_id FROM data_analytics.mc2_center.mc2_nodes WHERE node_type = 'file')
GROUP BY
    1
ORDER BY
    1 DESC
    NULLS LAST;
  """

    return sql_query


execute_query(query_3_1())


@st.fragment
def cell_3_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Download Counts by Month")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_1",
                help="Refresh download_counts_by_month data",
            ):
                execute_query.clear(query_3_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_3_1())).result(
                    "pandas"
                )

            if any(df.columns.duplicated()):
                new_names = []
                name_indexes = {}
                for name in df.columns:
                    name_index = name_indexes.get(name, 0) + 1
                    name_indexes[name] = name_index
                    new_names.append(f"{name}_{name_index}" if name_index > 1 else name)
                df.columns = new_names

            # Prepare data for line chart with aggregation
            if len(df) > 0:
                df = (
                    df.groupby(by="MONTH_OF_DOWNLOAD", sort=False)
                    .agg(
                        col1=("SAGE_DOWNLOADS", "sum"),
                        col2=("EXTERNAL_DOWNLOADS", "sum"),
                    )
                    .rename(
                        columns={
                            "col1": "SAGE_DOWNLOADS (sum)",
                            "col2": "EXTERNAL_DOWNLOADS (sum)",
                        }
                    )
                    .reset_index()
                )

                st.line_chart(
                    df.set_index("MONTH_OF_DOWNLOAD"),
                    width="stretch",
                    height=400,
                    x_label="MONTH_OF_DOWNLOAD",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_3_2() -> str:
    sql_query = r"""
WITH 
    -- Categorize users to distinguish Sagers from external community
    synapse_users AS (
        SELECT 
            id,
            CASE 
                WHEN email ILIKE '%@sagebase.org'
                  OR email ILIKE '%@sagebionetworks.org' THEN 'Sager'
                ELSE 'External' 
            END AS user_type
        FROM 
            synapse_data_warehouse.synapse.userprofile_latest
    )


SELECT
    date_trunc('MONTH', record_date) AS month_of_download,

    -- Sage metrics
    COUNT_IF(synapse_users.user_type = 'Sager') AS sage_downloads,
    COUNT(DISTINCT CASE WHEN synapse_users.user_type = 'Sager' THEN dl.user_id END) AS sage_unique_users,

    -- External community metrics
    COUNT_IF(synapse_users.user_type = 'External') AS external_downloads,
    COUNT(DISTINCT CASE WHEN synapse_users.user_type = 'External' THEN dl.user_id END) AS external_unique_users
FROM 
    synapse_data_warehouse.synapse_event.objectdownload_event AS dl
INNER JOIN 
    synapse_users 
      ON dl.user_id = synapse_users.id
WHERE 
    dl.project_id IN (SELECT project_id FROM data_analytics.mc2_center.mc2_projects)
    AND dl.file_handle_id IN (SELECT file_handle_id FROM data_analytics.mc2_center.mc2_nodes WHERE node_type = 'file')
GROUP BY
    1
ORDER BY
    1 DESC
    NULLS LAST;
  """

    return sql_query


execute_query(query_3_2())


@st.fragment
def cell_3_2():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Download Counts by Month")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_2",
                help="Refresh download_counts_by_month data",
            ):
                execute_query.clear(query_3_2())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_3_2())).result(
                    "pandas"
                )

            if any(df.columns.duplicated()):
                new_names = []
                name_indexes = {}
                for name in df.columns:
                    name_index = name_indexes.get(name, 0) + 1
                    name_indexes[name] = name_index
                    new_names.append(f"{name}_{name_index}" if name_index > 1 else name)
                df.columns = new_names

            if len(df) == 1 and len(df.columns) == 1:
                st.metric(
                    label=df.columns[0],
                    value=str(df.iloc[0, 0]),
                    label_visibility="collapsed",
                )
            else:
                st.dataframe(df, width="stretch", hide_index=True, height=400)
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 3: 2 Cells
col3_1, col3_2 = st.columns(2)
with col3_1:
    cell_3_1()
with col3_2:
    cell_3_2()


def query_4_1() -> str:
    sql_query = r"""
WITH 
    -- Filter for only non-Sagers on Synapse
    non_sagers AS (
        SELECT 
            id,
            user_name
        FROM 
            synapse_data_warehouse.synapse.userprofile_latest
        WHERE
            email NOT ILIKE '%@sagebase.org'
            AND email NOT ILIKE '%@sagebionetworks.org'
    )


SELECT
    id AS user_id,
    user_name,
    COUNT(dl.record_date) AS number_of_downloads,
    MAX(dl.record_date) AS latest_download_activity
FROM 
    synapse_data_warehouse.synapse_event.objectdownload_event AS dl
INNER JOIN 
    non_sagers
      ON dl.user_id = non_sagers.id
WHERE 
    dl.project_id IN (SELECT project_id FROM data_analytics.mc2_center.mc2_projects)
    AND dl.file_handle_id IN (SELECT file_handle_id FROM data_analytics.mc2_center.mc2_nodes WHERE node_type = 'file')
GROUP BY
    1, 2
ORDER BY
    3 DESC;
  """

    return sql_query


execute_query(query_4_1())


@st.fragment
def cell_4_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Download Counts by External User")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_1",
                help="Refresh download_counts_by_external_user data",
            ):
                execute_query.clear(query_4_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_4_1())).result(
                    "pandas"
                )

            if any(df.columns.duplicated()):
                new_names = []
                name_indexes = {}
                for name in df.columns:
                    name_index = name_indexes.get(name, 0) + 1
                    name_indexes[name] = name_index
                    new_names.append(f"{name}_{name_index}" if name_index > 1 else name)
                df.columns = new_names

            if len(df) == 1 and len(df.columns) == 1:
                st.metric(
                    label=df.columns[0],
                    value=str(df.iloc[0, 0]),
                    label_visibility="collapsed",
                )
            else:
                st.dataframe(df, width="stretch", hide_index=True)
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 4: Single Cell
cell_4_1()


def query_5_1() -> str:
    sql_query = r"""
WITH 
    -- Filter for only non-Sagers
    non_sagers AS (
        SELECT
            id AS user_id
        FROM 
            synapse_data_warehouse.synapse.userprofile_latest
        WHERE
            email NOT ILIKE '%@sagebase.org'
            AND email NOT ILIKE '%@sagebionetworks.org'
    ),
    
    -- Pre-calculate external downloads per file
    external_dl_counts AS (
        SELECT 
            dl.file_handle_id,
            dl.project_id,
            COUNT(dl.record_date) AS external_downloads,
            COUNT(DISTINCT dl.user_id) AS external_unique_users
        FROM 
            synapse_data_warehouse.synapse_event.objectdownload_event AS dl
        INNER JOIN
            non_sagers AS ns
                ON dl.user_id = ns.user_id
        GROUP BY 
            1, 
            2
    ),

    -- Refine scope of nodes to only MC2 "datasets"
    mc2_dataset_nodes AS (
        SELECT 
            id,
            file_handle_id,
            name AS dataset_name,
            project_id,
            project_name
        FROM
            data_analytics.mc2_center.mc2_nodes
        WHERE
            annotations:annotations:portal.value[0]::string = 'CCKP'
            AND annotations:annotations:entityType.value[0]::string = 'dataset'
    ),

    -- Combine direct files annotated with 'dataset' with nested files inside dataset folders
    mc2_dataset_files AS (
        -- File nodes
        SELECT 
            id AS file_entity_id, 
            file_handle_id, 
            dataset_name, 
            dataset_name AS file_name,
            project_id, 
            project_name
        FROM
            mc2_dataset_nodes
        WHERE
            file_handle_id IS NOT NULL
        
        UNION ALL
        
        -- Nested files inside folder / dataset entities
        SELECT 
            child.id AS file_entity_id,
            child.file_handle_id,
            parent.dataset_name,
            child.name AS file_name,
            parent.project_id,
            parent.project_name
        FROM
            data_analytics.mc2_center.mc2_nodes child
        INNER JOIN
            mc2_dataset_nodes parent 
                ON child.parent_id = parent.id
        WHERE 
            parent.file_handle_id IS NULL     -- Only look inside folder/dataset entities
            AND child.file_handle_id IS NOT NULL  -- Ensure the child entities are actually files
    )

-- List dataset files that have been downloaded
SELECT
    'syn' || f.file_entity_id::string AS file_synid,
    f.file_name,
    f.dataset_name,
    f.project_name,
    COALESCE(edc.external_downloads, 0) AS external_downloads,
    COALESCE(edc.external_unique_users, 0) AS external_unique_users
FROM
    mc2_dataset_files f
INNER JOIN 
    external_dl_counts edc
        ON f.file_handle_id = edc.file_handle_id 
        AND f.project_id = edc.project_id
ORDER BY
    3 ASC,
    5 DESC;  """

    return sql_query


execute_query(query_5_1())


@st.fragment
def cell_5_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### External Download Counts by Dataset")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_1",
                help="Refresh external_download_counts_by_dataset data",
            ):
                execute_query.clear(query_5_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_5_1())).result(
                    "pandas"
                )

            if any(df.columns.duplicated()):
                new_names = []
                name_indexes = {}
                for name in df.columns:
                    name_index = name_indexes.get(name, 0) + 1
                    name_indexes[name] = name_index
                    new_names.append(f"{name}_{name_index}" if name_index > 1 else name)
                df.columns = new_names

            if len(df) == 1 and len(df.columns) == 1:
                st.metric(
                    label=df.columns[0],
                    value=str(df.iloc[0, 0]),
                    label_visibility="collapsed",
                )
            else:
                st.dataframe(df, width="stretch", hide_index=True, height=400)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_5_2() -> str:
    sql_query = r"""
WITH 
    -- Categorize users to distinguish Sagers from external community
    synapse_users AS (
        SELECT 
            id,
            CASE 
                WHEN email ILIKE '%@sagebase.org'
                  OR email ILIKE '%@sagebionetworks.org' THEN 'Sager'
                ELSE 'External' 
            END AS user_type
        FROM 
            synapse_data_warehouse.synapse.userprofile_latest
    )


SELECT
    project_name,

    -- Sage metrics
    COUNT_IF(synapse_users.user_type = 'Sager') AS sage_downloads,
    COUNT(DISTINCT CASE WHEN synapse_users.user_type = 'Sager' THEN dl.user_id END) AS sage_unique_users,
    
    -- External community metrics
    COUNT_IF(synapse_users.user_type = 'External') AS external_downloads,
    COUNT(DISTINCT CASE WHEN synapse_users.user_type = 'External' THEN dl.user_id END) AS external_unique_users
FROM 
    synapse_data_warehouse.synapse_event.objectdownload_event AS dl
INNER JOIN 
    data_analytics.mc2_center.mc2_projects AS mc2 
      ON dl.project_id = mc2.project_id
INNER JOIN 
    synapse_users 
      ON dl.user_id = synapse_users.id
WHERE 
    dl.file_handle_id IN (SELECT file_handle_id FROM data_analytics.mc2_center.mc2_nodes WHERE node_type = 'file')
GROUP BY
    1
ORDER BY 
    4 DESC;  """

    return sql_query


execute_query(query_5_2())


@st.fragment
def cell_5_2():
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
                key=f"refresh_button_cell_5_2",
                help="Refresh download_counts_by_project_(all-time) data",
            ):
                execute_query.clear(query_5_2())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_5_2())).result(
                    "pandas"
                )

            if any(df.columns.duplicated()):
                new_names = []
                name_indexes = {}
                for name in df.columns:
                    name_index = name_indexes.get(name, 0) + 1
                    name_indexes[name] = name_index
                    new_names.append(f"{name}_{name_index}" if name_index > 1 else name)
                df.columns = new_names

            # Prepare data for bar chart
            if len(df) > 0:
                df = df[["PROJECT_NAME", "SAGE_DOWNLOADS"]]

                df["/* Order Key (Generated by Snowflake) */"] = df.drop(
                    columns="PROJECT_NAME"
                ).sum(axis=1)

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["PROJECT_NAME"]):
                    datetime_primary_column = df["PROJECT_NAME"]
                elif df["PROJECT_NAME"].dtype == "object" and isinstance(
                    df["PROJECT_NAME"].get(df["PROJECT_NAME"].first_valid_index()),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["PROJECT_NAME"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["PROJECT_NAME"] = df["PROJECT_NAME"].astype("string")

                st.bar_chart(
                    df,
                    x="PROJECT_NAME",
                    y=[
                        c
                        for c in df.columns
                        if c != "PROJECT_NAME"
                        and c != "/* Order Key (Generated by Snowflake) */"
                    ],
                    sort="-/* Order Key (Generated by Snowflake) */",
                    width="stretch",
                    height=400,
                    horizontal=True,
                    stack=False,
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 5: 2 Cells
col5_1, col5_2 = st.columns(2)
with col5_1:
    cell_5_1()
with col5_2:
    cell_5_2()


def query_6_1() -> str:
    sql_query = r"""
WITH 
    -- Categorize users to distinguish Sagers from external community
    synapse_users AS (
        SELECT 
            id,
            CASE 
                WHEN email ILIKE '%@sagebase.org'
                  OR email ILIKE '%@sagebionetworks.org' THEN 'Sager'
                ELSE 'External' 
            END AS user_type
        FROM 
            synapse_data_warehouse.synapse.userprofile_latest
    ),
    -- Get file names and IDs for the MC2 Project (id: syn7080714)
    mc2_project_file_nodes AS (
        SELECT 
            id,
            name AS filename,
            file_handle_id,
            project_name
        FROM 
            data_analytics.mc2_center.mc2_nodes
        WHERE 
            node_type = 'file'
            AND filename NOT ILIKE 'synapse_storage_manifest_%view.csv'
            AND project_name = 'Multi-Consortia Coordinating (MC2) Center'
    ),
    -- Aggregate downloads by file
    mc2_project_file_counts AS (
        SELECT
            mc2.project_name,
            'syn' || mc2.id::STRING AS synid,
            mc2.filename,
    
            -- Sage metrics
            COUNT_IF(synapse_users.user_type = 'Sager') AS sage_downloads,
            COUNT(DISTINCT CASE WHEN synapse_users.user_type = 'Sager' THEN dl.user_id END) AS sage_unique_users,
    
            -- External community metrics
            COUNT_IF(synapse_users.user_type = 'External') AS external_downloads,
            COUNT(DISTINCT CASE WHEN synapse_users.user_type = 'External' THEN dl.user_id END) AS external_unique_users
        FROM 
            synapse_data_warehouse.synapse_event.objectdownload_event AS dl
        INNER JOIN 
            mc2_project_file_nodes AS mc2 ON dl.file_handle_id = mc2.file_handle_id 
        INNER JOIN 
            synapse_users ON dl.user_id = synapse_users.id
        GROUP BY 
            1, 2, 3
    )

SELECT 
    synid,
    filename,
    project_name,
    sage_downloads,
    sage_unique_users,
    external_downloads,
    external_unique_users
FROM 
    mc2_project_file_counts
ORDER BY
    6 DESC;  """

    return sql_query


execute_query(query_6_1())


@st.fragment
def cell_6_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Download Counts in MC2 Project (syn7080714)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_1",
                help="Refresh download_counts_in_mc2_project_(syn7080714) data",
            ):
                execute_query.clear(query_6_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_6_1())).result(
                    "pandas"
                )

            if any(df.columns.duplicated()):
                new_names = []
                name_indexes = {}
                for name in df.columns:
                    name_index = name_indexes.get(name, 0) + 1
                    name_indexes[name] = name_index
                    new_names.append(f"{name}_{name_index}" if name_index > 1 else name)
                df.columns = new_names

            if len(df) == 1 and len(df.columns) == 1:
                st.metric(
                    label=df.columns[0],
                    value=str(df.iloc[0, 0]),
                    label_visibility="collapsed",
                )
            else:
                st.dataframe(df, width="stretch", hide_index=True)
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 6: Single Cell
cell_6_1()


# Footer
st.markdown("---")
st.markdown(
    "*Dashboard loaded: {}*".format(dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
)
