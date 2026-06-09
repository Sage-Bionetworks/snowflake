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
        return Session.builder.config("connection_name", "default").create()

    return get_active_session()


# Set page config
st.set_page_config(page_title="Synapse Usage Metrics", layout="wide")

# Title
st.title("Synapse Usage Metrics")
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
-- Top downloaded public projects for September 2023
    -- count(DISTINCT USER_ID) AS NUMBER_OF_UNIQUE_USERS_DOWNLOADED,
    -- sum(content_size) / power(2, 40) as data_download_size_in_tebibytes,
    -- count(*) AS DOWNLOADS_PER_PROJECT,
    -- count(DISTINCT FD_FILE_HANDLE_ID) AS NUMBER_OF_UNIQUE_FILES_DOWNLOADED
WITH DEDUP_FILEHANDLE AS (
    SELECT DISTINCT
        FILEDOWNLOAD.PROJECT_ID,
        count(DISTINCT FILEDOWNLOAD.USER_ID) AS NUMBER_OF_UNIQUE_USERS_DOWNLOADED,
        count(distinct FILEDOWNLOAD.USER_ID, FILEDOWNLOAD.FILE_HANDLE_ID, FILEDOWNLOAD.RECORD_DATE) as DOWNLOADS_PER_PROJECT,
        sum(file_latest.content_size) / power(2, 40) as data_download_size_in_tebibytes,
        count(distinct FILEDOWNLOAD.FILE_HANDLE_ID) as NUMBER_OF_UNIQUE_FILES_DOWNLOADED
    FROM
      synapse_data_warehouse.synapse_event.objectdownload_event AS FILEDOWNLOAD
    inner join
        synapse_data_warehouse.synapse.file_latest
    on
        FILEDOWNLOAD.file_handle_id = file_latest.id
    group by
        FILEDOWNLOAD.PROJECT_ID
)
, project_summary as (
    select
        project_id,
        sum(content_size) / power(2, 30) as size_in_gib
    from
        synapse_data_warehouse.synapse.node_latest
    inner join
        synapse_data_warehouse.synapse.file_latest
        on node_latest.file_handle_id = file_latest.id
    group by
        project_id
)
SELECT
    'https://www.synapse.org/#!Synapse:syn' || cast(node_latest.project_id as varchar) as project,
    node_latest.name,
    node_latest.is_public,
    project_summary.size_in_gib,
    DEDUP_FILEHANDLE.NUMBER_OF_UNIQUE_USERS_DOWNLOADED,
    DEDUP_FILEHANDLE.data_download_size_in_tebibytes,
    DEDUP_FILEHANDLE.DOWNLOADS_PER_PROJECT,
    DEDUP_FILEHANDLE.NUMBER_OF_UNIQUE_FILES_DOWNLOADED
FROM
    DEDUP_FILEHANDLE
RIGHT JOIN
    synapse_data_warehouse.synapse.node_latest
    ON DEDUP_FILEHANDLE.project_id = node_latest.id
LEFT JOIN
    project_summary
    ON node_latest.project_id = project_summary.project_id
where
    node_latest.node_type = 'project'
ORDER BY
    data_download_size_in_tebibytes DESC NULLS LAST;  """

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
                st.markdown("### Project all time download activity")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_1",
                help="Refresh project_all_time_download_activity data",
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
with file_stats as (
    select
        node_latest.id as node_id,
        node_latest.file_handle_id,
        file_latest.content_size
    from
        synapse_data_warehouse.synapse.node_latest
    inner join
        synapse_data_warehouse.synapse.file_latest
    on
        file_latest.id = node_latest.file_handle_id
)
select
    count(*) as number_of_nodes,
    sum(content_size) / POWER(2, 40) as number_of_terabytes
from
    file_stats;
          """

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
                st.markdown("### synapse file info")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_1",
                help="Refresh synapse_file_info data",
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
                st.dataframe(df, width="stretch", hide_index=True, height=400)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_2_2() -> str:
    sql_query = r"""
WITH FILE_EXTENSIONS AS (
    SELECT split_part(NAME, '.', -1) AS FILEEXT
    FROM SYNAPSE_DATA_WAREHOUSE.SYNAPSE.NODE_LATEST
    WHERE NODE_TYPE not in ('project', 'folder')
)

SELECT
    FILEEXT,
    count(*) AS NUMBER_OF_FILES
FROM FILE_EXTENSIONS
GROUP BY FILEEXT
ORDER BY NUMBER_OF_FILES DESC
limit 1000;
  """

    return sql_query


execute_query(query_2_2())


@st.fragment
def cell_2_2():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Top 50 File Extensions Distribution")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_2",
                help="Refresh top_50_file_extensions_distribution data",
            ):
                execute_query.clear(query_2_2())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_2_2())).result(
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


def query_2_3() -> str:
    sql_query = r"""
select
    bucket,
    count(*) as number_of_files,
    sum(content_size) / power(2, 40) as number_of_tebibytes
from
    synapse_data_warehouse.synapse.file_latest
group by
    bucket
order by
    number_of_tebibytes DESC  """

    return sql_query


execute_query(query_2_3())


@st.fragment
def cell_2_3():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Distribution of files in bucket")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_3",
                help="Refresh distribution_of_files_in_bucket data",
            ):
                execute_query.clear(query_2_3())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_2_3())).result(
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


# Row 2: 3 Cells
col2_1, col2_2, col2_3 = st.columns(3)
with col2_1:
    cell_2_1()
with col2_2:
    cell_2_2()
with col2_3:
    cell_2_3()


def query_3_1() -> str:
    sql_query = r"""
with file_stats as (
    select
        node_latest.file_handle_id,
        node_latest.is_public,
        node_latest.is_controlled,
        node_latest.is_restricted,
        file_latest.content_size
    from
        synapse_data_warehouse.synapse.node_latest
    inner join
        synapse_data_warehouse.synapse.file_latest
    on
        file_latest.id = node_latest.file_handle_id
)
select
    is_public,
    count(*) as number_of_files,
    sum(content_size) / POWER(2, 40) as number_of_terabytes
from
    file_stats
group by
    is_public
order by
    number_of_terabytes DESC;

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
                st.markdown("### Public/Private entities")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_1",
                help="Refresh public/private_entities data",
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


def query_3_2() -> str:
    sql_query = r"""
select
    status,
    count(*) as number_of_files,
    sum(content_size) / power(2, 40) as number_of_terabytes
from
    synapse_data_warehouse.synapse.file_latest
group by
    status
order by
    number_of_files DESC  """

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
                st.markdown("### File handle status (all file handles)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_2",
                help="Refresh file_handle_status_(all_file_handles) data",
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


def query_3_3() -> str:
    sql_query = r"""
select
  -- annotations:annotations as expanded_annotations,
    COUNT(CASE WHEN annotations:annotations != '{}' THEN 1 END) * 1.0 / COUNT(*) AS ratio_empty_annotations

from
    synapse_data_warehouse.synapse.node_latest
  """

    return sql_query


execute_query(query_3_3())


@st.fragment
def cell_3_3():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Annotation Usage")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_3",
                help="Refresh annotation_usage data",
            ):
                execute_query.clear(query_3_3())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_3_3())).result(
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


def query_3_4() -> str:
    sql_query = r"""
select
    node_type,
    COUNT(*) as number_of_entities
from
    synapse_data_warehouse.synapse.node_latest
group by
    node_type
order by
    number_of_entities DESC;
  """

    return sql_query


execute_query(query_3_4())


@st.fragment
def cell_3_4():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Entity Type Distribution")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_4",
                help="Refresh entity_type_distribution data",
            ):
                execute_query.clear(query_3_4())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_3_4())).result(
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


# Row 3: 4 Cells
col3_1, col3_2, col3_3, col3_4 = st.columns(4)
with col3_1:
    cell_3_1()
with col3_2:
    cell_3_2()
with col3_3:
    cell_3_3()
with col3_4:
    cell_3_4()


def query_4_1() -> str:
    sql_query = r"""
with file_stats as (
    select
        node_latest.file_handle_id,
        node_latest.is_public,
        node_latest.is_controlled,
        node_latest.is_restricted,
        file_latest.content_size
    from
        synapse_data_warehouse.synapse.node_latest
    inner join
        synapse_data_warehouse.synapse.file_latest
    on
        file_latest.id = node_latest.file_handle_id
)
select
    is_public, is_controlled, is_restricted,
    count(*) as number_of_files,
    sum(content_size) / POWER(2, 40) as number_of_terabytes
from
    file_stats
group by
    is_public, is_controlled, is_restricted
order by
    number_of_terabytes DESC;

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
                st.markdown("### Governance distribution")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_1",
                help="Refresh governance_distribution data",
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
SELECT
    ORIGIN,
    count(*) AS NUMBER_OF_REQUESTS,
    count(DISTINCT USER_ID) AS NUMBER_OF_UNIQUE_USERS
FROM
  synapse_data_warehouse.synapse_event.access_event
WHERE
    ORIGIN LIKE '%synapse.org'
    AND ORIGIN NOT LIKE '%staging%'
    AND ORIGIN NOT LIKE '%tst%'
    AND ORIGIN NOT LIKE '%portal-prod%'
GROUP BY ORIGIN
ORDER BY NUMBER_OF_REQUESTS DESC;
  """

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
                st.markdown("### Synapse traffic from portals")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_1",
                help="Refresh synapse_traffic_from_portals data",
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
SELECT
    CLIENT,
    count(*) AS NUMBER_OF_CALLS,
    count(distinct user_id) as number_of_unique_users
FROM
  synapse_data_warehouse.synapse_event.access_event
WHERE
    CLIENT not in ('ELB_HEALTHCHECKER', 'STACK')
GROUP BY
    CLIENT
ORDER BY
    NUMBER_OF_CALLS DESC;  """

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
                st.markdown("### Distribution of client calls")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_2",
                help="Refresh distribution_of_client_calls data",
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


# Row 5: 2 Cells
col5_1, col5_2 = st.columns(2)
with col5_1:
    cell_5_1()
with col5_2:
    cell_5_2()


def query_6_1() -> str:
    sql_query = r"""
WITH USER AS (
    SELECT ID AS PROFILE_ID
    FROM
        SYNAPSE_DATA_WAREHOUSE.SYNAPSE.USERPROFILE_LATEST
    WHERE
        EMAIL NOT LIKE '%@sagebase.org'
)
SELECT
    count(distinct USER_ID)
FROM
  synapse_data_warehouse.synapse_event.access_event
WHERE
    USER_ID IN (SELECT PROFILE_ID FROM USER);
  """

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
                st.markdown("### Number of all time non-sage synapse users")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_1",
                help="Refresh number_of_all_time_non-sage_synapse_users data",
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
                st.dataframe(df, width="stretch", hide_index=True, height=400)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_6_2() -> str:
    sql_query = r"""
select
    location,
    count(*) as number_of_users
from
    synapse_data_warehouse.synapse.userprofile_latest
group by
    location
order by
    number_of_users DESC;  """

    return sql_query


execute_query(query_6_2())


@st.fragment
def cell_6_2():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Location distribution based on user profile")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_2",
                help="Refresh location_distribution_based_on_user_profile data",
            ):
                execute_query.clear(query_6_2())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_6_2())).result(
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


def query_6_3() -> str:
    sql_query = r"""
select
    company,
    count(*) as number_of_users
from
    synapse_data_warehouse.synapse.userprofile_latest
group by company
order by number_of_users DESC;  """

    return sql_query


execute_query(query_6_3())


@st.fragment
def cell_6_3():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Company distribution based on user profile")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_3",
                help="Refresh company_distribution_based_on_user_profile data",
            ):
                execute_query.clear(query_6_3())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_6_3())).result(
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


# Row 6: 3 Cells
col6_1, col6_2, col6_3 = st.columns(3)
with col6_1:
    cell_6_1()
with col6_2:
    cell_6_2()
with col6_3:
    cell_6_3()


def query_7_1() -> str:
    sql_query = r"""
with non_sage as (
    select
        distinct email, record_date
    from
      synapse_data_warehouse.synapse_event.fileupload_event AS fileupload
    join
        synapse_data_warehouse.synapse.userprofile_latest
        on fileupload.user_id = userprofile_latest.id
)
select
    date_trunc('month', record_date) as year_month,
    count(distinct email) as number_of_users,
    COUNT(DISTINCT CASE 
                      WHEN email NOT LIKE '%@sagebase.org' 
                           AND email NOT LIKE '%@sagebionetworks.org'
                      THEN email
                  END) AS number_of_non_sage_users
from
    non_sage
group by
    date_trunc('month', record_date)
order by 
    year_month DESC  """

    return sql_query


execute_query(query_7_1())


@st.fragment
def cell_7_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Monthy active users: uploads")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_7_1",
                help="Refresh monthy_active_users:_uploads data",
            ):
                execute_query.clear(query_7_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_7_1())).result(
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


def query_7_2() -> str:
    sql_query = r"""
with non_sage as (
    select
        distinct email, record_date
    from
      synapse_data_warehouse.synapse_event.objectdownload_event AS filedownload
    join
        synapse_data_warehouse.synapse.userprofile_latest
        on filedownload.user_id = userprofile_latest.id
)
select
    date_trunc('month', record_date) as year_month,
    count(distinct email) as number_of_users,
    COUNT(DISTINCT CASE 
                      WHEN email NOT LIKE '%@sagebase.org' 
                           AND email NOT LIKE '%@sagebionetworks.org'
                      THEN email
                  END) AS number_of_non_sage_users
from
    non_sage
group by
    date_trunc('month', record_date)
order by 
    year_month DESC  """

    return sql_query


execute_query(query_7_2())


@st.fragment
def cell_7_2():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Monthy active users: downloads")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_7_2",
                help="Refresh monthy_active_users:_downloads data",
            ):
                execute_query.clear(query_7_2())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_7_2())).result(
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


# Row 7: 2 Cells
col7_1, col7_2 = st.columns(2)
with col7_1:
    cell_7_1()
with col7_2:
    cell_7_2()


def query_8_1() -> str:
    sql_query = r"""

select
    table_catalog, table_schema, table_name, row_count, last_altered
from
  synapse_data_warehouse.information_schema.tables
where
    table_schema = 'SYNAPSE';  """

    return sql_query


execute_query(query_8_1())


@st.fragment
def cell_8_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Tables last Updated time")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_8_1",
                help="Refresh tables_last_updated_time data",
            ):
                execute_query.clear(query_8_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_8_1())).result(
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


# Row 8: Single Cell
cell_8_1()


def query_9_1() -> str:
    sql_query = r"""
-- for projects created in the last week,
-- project creator and current storage size

with project_aggregate_stats as (
    select
        node_latest.project_id,
        max(node_latest.modified_on) as last_updated_at,
        min(node_latest.created_on) as created_at,
        sum(file_latest.content_size) /  power(2, 30) as data_size_in_gib,
        -- sum(file_latest.content_size) as data_size_in_bytes,
        -- ARRAY_AGG(distinct file_latest.bucket) AS buckets,
        node_latest.is_public
    from
        synapse_data_warehouse.synapse.node_latest
    left join
        synapse_data_warehouse.synapse.file_latest
        on node_latest.file_handle_id = file_latest.id
    where
        node_latest.project_id in (
            select 
                id
            from
                synapse_data_warehouse.synapse.node_latest
            where
                node_type='project' and
                created_on >= current_date - interval '1 week'
        )
    group by
        node_latest.project_id,
        node_latest.is_public
)
select
    'https://www.synapse.org/Synapse:syn' || project_aggregate_stats.project_id as link,
    node_latest.name,
    -- node_latest.created_by,
    -- userprofile_latest.user_name,
    userprofile_latest.email as CREATOR,
    project_aggregate_stats.*,
from
    project_aggregate_stats
join
    synapse_data_warehouse.synapse.node_latest
    on project_aggregate_stats.project_id = node_latest.id
join
    synapse_data_warehouse.synapse.userprofile_latest
    on node_latest.created_by = userprofile_latest.id
order by
    last_updated_at desc;  """

    return sql_query


execute_query(query_9_1())


@st.fragment
def cell_9_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Projects created in the last week")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_9_1",
                help="Refresh projects_created_in_the_last_week data",
            ):
                execute_query.clear(query_9_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_9_1())).result(
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


# Row 9: Single Cell
cell_9_1()


def query_10_1() -> str:
    sql_query = r"""

with latest_datasets as (
    select 
        node_latest.name,
        creator.email as creator,
        node_latest.id,
        project_info.name as project_name,
        CASE 
            WHEN node_latest.annotations:annotations:contentType:value IS NULL
            THEN node_latest.node_type 
            ELSE 'dataset annotation'
        END AS contenttype,
        node_latest.node_type,
        node_latest.created_on,
        node_latest.is_public,
        node_latest.items
    from
        synapse_data_warehouse.synapse.node_latest
    join
        synapse_data_warehouse.synapse.node_latest project_info on
        node_latest.project_id = project_info.id
    join
        synapse_data_warehouse.synapse.userprofile_latest creator on
        node_latest.created_by = creator.id
    where
        (
            node_latest.annotations:annotations:contentType:value = ['dataset'] or
            -- node_latest.node_type in ('dataset', 'datasetcollection')
            node_latest.node_type in ('dataset')

        ) and
        node_latest.created_on >= current_date - interval '1 week'
), -- extract the list of items as outlined in a dataset
dataset_objects as (
    SELECT
        latest_datasets.id as dataset_id,
        REPLACE(item.value:entityId::STRING, 'syn', '') as id
    FROM
        latest_datasets,
        LATERAL FLATTEN(input => latest_datasets.items) item
    where
        latest_datasets.contenttype = 'dataset'
), -- Extract the list of nested entities under the folder
folder_objects AS (
    -- Base case: Start from folder_objects
    select
        id as dataset_id,
        id,
    from
        latest_datasets
    where
        node_type = 'folder'
    
    UNION ALL
    
    -- Recursive case: Find nested children
    SELECT 
        rf.dataset_id,
        nl.id,
    FROM 
        synapse_data_warehouse.synapse.node_latest nl
    JOIN 
        folder_objects rf 
    ON 
        nl.parent_id = rf.id
), -- Concatenate all dataset entities
dataset_entities as (
    select
        *
    from
        dataset_objects

    UNION

    select
        *
    from
        folder_objects
), -- obtain the content size for each entity in the dataset
dataset_entity_file_handle_ids as (
    select
        dataset_entities.*,
        node_latest.file_handle_id,
        node_latest.modified_on,
        node_latest.annotations:annotations as annotations,
        file_latest.content_size
    from
        dataset_entities
    join
        synapse_data_warehouse.synapse.node_latest
        on dataset_entities.id = node_latest.id
    join
        synapse_data_warehouse.synapse.file_latest
        on node_latest.file_handle_id = file_latest.id
), -- get each dataset size
dataset_entity_metric as (
    select
        dataset_id,
        sum(content_size) / power(2, 30) as size_in_gib,
        count(id) as number_of_files,
        max(modified_on) as last_updated_on,
        COUNT(CASE WHEN annotations != {} THEN 1 END) * 100 / count(*) as percent_annotated
        
    from
        dataset_entity_file_handle_ids
    group by
        dataset_id
)
select
    'https://www.synapse.org/Synapse:syn' || latest_datasets.id as link,
    latest_datasets.* EXCLUDE items,
    dataset_entity_metric.* EXCLUDE dataset_id
from
    latest_datasets
join
    dataset_entity_metric
    on latest_datasets.id = dataset_entity_metric.dataset_id;


  """

    return sql_query


execute_query(query_10_1())


@st.fragment
def cell_10_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Datasets created in the last week")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_10_1",
                help="Refresh datasets_created_in_the_last_week data",
            ):
                execute_query.clear(query_10_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_10_1())).result(
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


# Row 10: Single Cell
cell_10_1()


# Footer
st.markdown("---")
st.markdown(
    "*Dashboard loaded: {}*".format(dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
)
