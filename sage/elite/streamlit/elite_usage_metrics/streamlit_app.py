import argparse
import datetime as dt
import pandas as pd
import streamlit as st
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session

# Set page config
st.set_page_config(page_title="ELITE Usage Metrics (Main)", layout="wide")

# Title
st.title("ELITE Usage Metrics (Main)")
st.markdown(
    '<p style="color: #cc0000; font-size: 0.85rem; margin-top: -0.4rem;">'
    "This app is "
    '<a href="https://github.com/Sage-Bionetworks/snowflake/blob/dev/STREAMLIT.md" target="_blank">managed on Github</a>. '
    "Any local edits will not be retained."
    "</p>",
    unsafe_allow_html=True,
)

ELITE_PROJECT_IDS = (
    27229419,
    52072575,
    52072939,
    52237024,
    52642213,
    53124793,
)
ELITE_PROJECT_IDS_SQL = ", ".join(str(project_id) for project_id in ELITE_PROJECT_IDS)


# Initialize session configured for generated Streamlit apps
def read_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--local-dev",
        action="store_true",
        help="Run locally using the 'default' Snowflake connection.",
    )
    return parser.parse_args()


def get_session(local_dev: bool) -> Session:
    if local_dev:
        return Session.builder.config("connection_name", "default").create()

    return get_active_session()


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
    sql_query = f"""
-- get latest projects https://www.synapse.org/#!Synapse:syn51489960/tables/query/eyJzcWwiOiJTRUxFQ1QgZGlzdGluY3QocHJvamVjdElkKSBGUk9NIHN5bjUxNDg5OTYwIiwgImluY2x1ZGVFbnRpdHlFdGFnIjp0cnVlLCAibGltaXQiOjI1fQ==

select
    min(record_date) as min_dl_date,
    max(record_date) as max_dl_date
from
    synapse_data_warehouse.synapse_event.objectdownload_event
where
    project_id in ({ELITE_PROJECT_IDS_SQL})
;
  """

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
                st.markdown("### Download times")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_1",
                help="Refresh download_times data",
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
                st.dataframe(df, width="stretch", hide_index=True, height=400)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_1_2() -> str:
    sql_query = f"""
-- Data volume across all node types in ELITE projects by project and total

--!! This is potentially an underestimate !!--
-- Only the file handle associated with the most recent version
-- of the node (e.g., file entity) is considered in the computation
-- Once `synapse_event.file_event` table is available, we can compute
-- the data volume of file handles spanning all versions of versionable
-- entities. Note: This likely applies primarily to versioned file entities.
WITH elite_node AS (
  SELECT
    file_handle_id,
    project_id
  FROM synapse_data_warehouse.synapse.node_latest
  WHERE project_id IN ({ELITE_PROJECT_IDS_SQL})
),

file_size AS (
  SELECT
    id            AS file_handle_id,
    content_size
  FROM synapse_data_warehouse.synapse.file_latest
),

project_name AS (
  SELECT
    id,
    name
  FROM synapse_data_warehouse.synapse.node_latest
  WHERE id IN ({ELITE_PROJECT_IDS_SQL})
),

per_project AS (
  SELECT
    pn.name                                        AS project,
    ROUND(SUM(fs.content_size) / POWER(2,30))   AS appx_data_volume_GiB,
    -- 0.23 is the us-east-1 S3 $/GiB rate for first 50 TB / Month	
    -- 12 is the number of months in a year
    ROUND(SUM(fs.content_size) / POWER(2,30) * 0.023 * 12) AS APPX_ANNUAL_S3_STORAGE_COST
  FROM elite_node ed
  JOIN project_name pn   ON pn.id            = ed.project_id
  LEFT JOIN file_size fs ON ed.file_handle_id = fs.file_handle_id
  GROUP BY pn.name
)

SELECT
  project,
  appx_data_volume_GiB,
  APPX_ANNUAL_S3_STORAGE_COST
FROM per_project

UNION ALL

SELECT
  'All Projects' AS project,
  ROUND(
    SUM(fs.content_size) / POWER(2,30)
  ) AS appx_data_volume_GiB,
  ROUND(SUM(fs.content_size) / POWER(2,30) * 0.023 * 12) AS APPX_ANNUAL_S3_STORAGE_COST
FROM elite_node ed
LEFT JOIN file_size fs
  ON ed.file_handle_id = fs.file_handle_id

ORDER BY
  appx_data_volume_GiB DESC;  """

    return sql_query


execute_query(query_1_2())


@st.fragment
def cell_1_2():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Storage by Project")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_2",
                help="Refresh storage_by_project data",
            ):
                execute_query.clear(query_1_2())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_1_2())).result(
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


# Row 1: 2 Cells
col1_1, col1_2 = st.columns(2)
with col1_1:
    cell_1_1()
with col1_2:
    cell_1_2()


def query_2_1() -> str:
    sql_query = f"""

select
    count(distinct user_id) as number_of_unique_users,
    count(*) as number_of_downloads
from
    synapse_data_warehouse.synapse_event.objectdownload_event
where
    project_id in ({ELITE_PROJECT_IDS_SQL})  """

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
                st.markdown("### All time downloads")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_1",
                help="Refresh all_time_downloads data",
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
    sql_query = f"""

select
    count(distinct user_id) as number_of_unique_users,
    count(*) as number_of_downloads
from
    synapse_data_warehouse.synapse_event.objectdownload_event
where
    association_object_type = 'FileEntity' and 
    project_id in ({ELITE_PROJECT_IDS_SQL})  """

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
                st.markdown("### All time downloads - file entities only")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_2",
                help="Refresh all_time_downloads_-_file_entities_only data",
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
    sql_query = f"""
WITH USER AS (
    SELECT ID AS PROFILE_ID
    FROM
        SYNAPSE_DATA_WAREHOUSE.SYNAPSE.USERPROFILE_LATEST
    WHERE
        EMAIL NOT LIKE '%@sagebase.org'
)

select
    count(distinct user_id) as number_of_unique_users,
    count(*) as number_of_downloads
from
    synapse_data_warehouse.synapse_event.objectdownload_event
where
    project_id in ({ELITE_PROJECT_IDS_SQL})
    and
    USER_ID IN (SELECT PROFILE_ID FROM USER);  """

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
                st.markdown("### All time non-sage downloads")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_3",
                help="Refresh all_time_non-sage_downloads data",
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


def query_2_4() -> str:
    sql_query = f"""
WITH USER AS (
    SELECT ID AS PROFILE_ID
    FROM
        SYNAPSE_DATA_WAREHOUSE.SYNAPSE.USERPROFILE_LATEST
    WHERE
        EMAIL NOT ILIKE '%@sagebase.org'
)

select
    count(distinct user_id) as number_of_unique_users,
    count(*) as number_of_downloads
from
    synapse_data_warehouse.synapse_event.objectdownload_event
where
    association_object_type = 'FileEntity' 
    and 
    project_id in ({ELITE_PROJECT_IDS_SQL})
    and
    USER_ID IN (SELECT PROFILE_ID FROM USER)
;  """

    return sql_query


execute_query(query_2_4())


@st.fragment
def cell_2_4():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### All time non-sage downloads - file entity only")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_4",
                help="Refresh all_time_non-sage_downloads_-_file_entity_only data",
            ):
                execute_query.clear(query_2_4())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_2_4())).result(
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


# Row 2: 4 Cells
col2_1, col2_2, col2_3, col2_4 = st.columns(4)
with col2_1:
    cell_2_1()
with col2_2:
    cell_2_2()
with col2_3:
    cell_2_3()
with col2_4:
    cell_2_4()


def query_3_1() -> str:
    sql_query = f"""
--- ELITE Portal file/table download statistics
--- limit to non-Sage users
-- note: since file size data is derived from `synapse.file_latest`,
-- any file handles which no longer exist don't count towards the download volume total
with dedup_downloads as (
    select
        user_id, record_date, file_handle_id
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    where 
        project_id in ({ELITE_PROJECT_IDS_SQL})
), external_users as (
    select id as user_id
    from
        synapse_data_warehouse.synapse.userprofile_latest
    where
        email not ilike '%@sagebase.org' and email not ilike '%sagebionetworks.org'

), file_size as(
    select
        id,
        content_size  
    from synapse_data_warehouse.synapse.file_latest
)
select
    DATE_TRUNC('MONTH', record_date)::DATE as iso_date,
    count(*) AS number_of_downloads,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    round(sum(file_size.content_size) / power(2, 30), 2) AS GiB_downloaded
from
    dedup_downloads
inner join
    external_users on
    dedup_downloads.user_id = external_users.user_id
left join
    file_size on
    dedup_downloads.file_handle_id = file_size.id
group by
    iso_date
order by
    iso_date desc
;  """

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
                st.markdown("### All-Time Downloads (External Users)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_1",
                help="Refresh all-time_downloads_(external_users) data",
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
    sql_query = f"""
--- ELITE Portal file/table download statistics
--- limit to non-Sage users
-- note: since file size data is derived from `synapse.file_latest`,
-- any file handles which no longer exist don't count towards the download volume total
with dedup_downloads as (
    select
        user_id, record_date, file_handle_id
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    where 
        project_id in ({ELITE_PROJECT_IDS_SQL})
), external_users as (
    select id as user_id
    from
        synapse_data_warehouse.synapse.userprofile_latest
    where
        email not ilike '%@sagebase.org' and email not ilike '%sagebionetworks.org'

), file_size as(
    select
        id,
        content_size  
    from synapse_data_warehouse.synapse.file_latest
)
select
    DATE_TRUNC('MONTH', record_date)::DATE as iso_date,
    count(*) AS number_of_downloads,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    round(sum(file_size.content_size) / power(2, 30), 2) AS GiB_downloaded
from
    dedup_downloads
inner join
    external_users on
    dedup_downloads.user_id = external_users.user_id
left join
    file_size on
    dedup_downloads.file_handle_id = file_size.id
group by
    iso_date
order by
    iso_date desc
;  """

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
                st.markdown("### All-Time Downloads (External Users)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_2",
                help="Refresh all-time_downloads_(external_users) data",
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

            # Prepare data for line chart with aggregation
            if len(df) > 0:
                df = (
                    df.groupby(by="ISO_DATE", sort=False)
                    .agg(col1=("NUMBER_OF_UNIQUE_USERS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_UNIQUE_USERS (sum)"})
                    .reset_index()
                )

                st.area_chart(
                    df.set_index("ISO_DATE"),
                    width="stretch",
                    height=400,
                    x_label="ISO_DATE",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 3: 2 Cells
col3_1, col3_2 = st.columns(2)
with col3_1:
    cell_3_1()
with col3_2:
    cell_3_2()


def query_4_1() -> str:
    sql_query = f"""
--- ELITE Portal monthly downloads by study 
--- limit to non-Sage users
--- limit to file entities only (exclude tables)

with dedup_downloads as (
    select
        user_id, record_date, file_handle_id
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    where 
        association_object_type = 'FileEntity'
        and
        project_id in ({ELITE_PROJECT_IDS_SQL})
), external_users as (
    select id as user_id
    from
        synapse_data_warehouse.synapse.userprofile_latest
    where
        email not ilike '%@sagebase.org' and email not ilike '%sagebionetworks.org'

), file_size as(
    select
        id,
        content_size  
    from synapse_data_warehouse.synapse.file_latest
)
select
    date_trunc('month', record_date) as month,
    count(record_date) AS number_of_downloads,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    round(sum(file_size.content_size) / power(2, 30), 2) AS GiB_downloaded
from
    dedup_downloads
inner join
    external_users
on 
    dedup_downloads.user_id = external_users.user_id
left join
    file_size
on
    dedup_downloads.file_handle_id = file_size.id
group by
    month
order by
    month desc, number_of_unique_users desc
;  """

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
                st.markdown(
                    "### downloads per month (external users, file entities only)"
                )
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_1",
                help="Refresh downloads_per_month_(external_users,_file_entities_only) data",
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
    sql_query = f"""
with node_annotations as (
    select
        file_handle_id,
        annotations:annotations:study:value[0]::string as study,
    from
        synapse_data_warehouse.synapse_event.node_event
    where
        project_id in ({ELITE_PROJECT_IDS_SQL})
), dedup_downloads as (
    select
        objectdownload_event.user_id, objectdownload_event.record_date, objectdownload_event.file_handle_id, node_annotations.study
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
    on
        objectdownload_event.file_handle_id = node_annotations.file_handle_id
), external_users as (
    select id as user_id
    from
        synapse_data_warehouse.synapse.userprofile_latest
    where
        email not ilike '%@sagebase.org' and email not ilike '%sagebionetworks.org'

), file_size as(
    select
        id,
        content_size  
    from synapse_data_warehouse.synapse.file_latest
)
select
    DATE_TRUNC('MONTH', record_date)::DATE as iso_date,
    study,
    count(*) AS number_of_downloads,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    round(sum(file_size.content_size) / power(2, 30), 2) AS GiB_downloaded
from
    dedup_downloads
inner join
    external_users
    on dedup_downloads.user_id = external_users.user_id
left join
    file_size
    on dedup_downloads.file_handle_id = file_size.id
where
    study is not null
group by
    iso_date,
    study
order by
    iso_date desc, study
;  """

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
                st.markdown("### Monthly Downloads per Study (External Users)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_1",
                help="Refresh monthly_downloads_per_study_(external_users) data",
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

            # Prepare data for line chart with aggregation
            if len(df) > 0:
                df = (
                    df.groupby(by=["ISO_DATE", "STUDY"], sort=False)
                    .agg(col1=("NUMBER_OF_DOWNLOADS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_DOWNLOADS (sum)"})
                    .unstack(level=1)
                )

                df.columns = [
                    " | ".join(map(str, c[::-1])).replace(":", "_") for c in df.columns
                ]

                df = df.reset_index()

                st.line_chart(
                    df.set_index("ISO_DATE"),
                    width="stretch",
                    height=400,
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 5: Single Cell
cell_5_1()


def query_6_1() -> str:
    sql_query = f"""
--- Downloads from ELITE Portal Aug 1 2023 - June 10 2024
--- Excludes users with sagebase or sagebionetwork email domains
--- Excludes files labelled "resouceType = metadata" to avoid miscounting files annotated with multiple studies


-- WITH USER AS (
--     SELECT ID AS PROFILE_ID
--     FROM
--         SYNAPSE_DATA_WAREHOUSE.SYNAPSE.USERPROFILE_LATEST
--     WHERE
--         EMAIL NOT ILIKE '%@sagebase.org' AND EMAIL NOT ILIKE '%sagebionetworks.org'
-- )

-- SELECT
--     study,
--     COUNT(RECORD_DATE) as number_downloads,
--     count(distinct USER_ID) distinct_users_downloading,
--     count(distinct id) as total_files,
--     min(RECORD_DATE) as earliest_download_record
-- FROM
--     SAGE.PORTAL_DOWNLOADS.AD
-- WHERE
--     USER_ID IN (SELECT PROFILE_ID FROM USER)
--     AND resourceType != 'metadata'
-- GROUP BY
--     study
-- ORDER BY
--     distinct_users_downloading DESC;


--- AD Portal monthly downloads by study 
--- limit to non-Sage users
with node_annotations as (
    select
        file_handle_id,
        annotations:annotations:study:value[0]::string as study,
    from
        synapse_data_warehouse.synapse_event.node_event
    where
        project_id in ({ELITE_PROJECT_IDS_SQL})
), dedup_downloads as (
    select
        distinct objectdownload_event.user_id, objectdownload_event.record_date, objectdownload_event.file_handle_id, node_annotations.study
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
    on
        objectdownload_event.file_handle_id = node_annotations.file_handle_id
), external_users as (
    select id as user_id
    from
        synapse_data_warehouse.synapse.userprofile_latest
    where
        email not ilike '%@sagebase.org' and email not ilike '%sagebionetworks.org'

), file_size as(
    select
        id,
        content_size  
    from synapse_data_warehouse.synapse.file_latest
)
select
    study,
    count(*) AS number_of_downloads,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    round(sum(file_size.content_size) / power(2, 30), 2) AS GiB_downloaded
from
    dedup_downloads
inner join
    external_users
    on dedup_downloads.user_id = external_users.user_id
left join
    file_size
    on dedup_downloads.file_handle_id = file_size.id
where
    study is not null
group by
    study
order by
    number_of_downloads desc
;  """

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
                st.markdown("### All-time Downloads per Study (External Users)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_1",
                help="Refresh all-time_downloads_per_study_(external_users) data",
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


def query_7_1() -> str:
    sql_query = f"""
with specimens as (
    select
        annotations:annotations:specimenID:value as specimenID,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in ({ELITE_PROJECT_IDS_SQL})
)
select
    count(distinct specimenID)
from
    specimens;  """

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
                st.markdown("### Number of specimens")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_7_1",
                help="Refresh number_of_specimens data",
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
    sql_query = f"""
with specimens as (
    select
        annotations:annotations:specimenID:value as specimenID,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in ({ELITE_PROJECT_IDS_SQL})
)
select
    count(distinct specimenID)
from
    specimens;  """

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
                st.markdown("### Number of specimens")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_7_2",
                help="Refresh number_of_specimens data",
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

            # Display scatter chart
            if len(df) > 0:
                value_col = "COUNT(DISTINCT SPECIMENID)"
                chart_df = df[[value_col]].copy()
                chart_df[value_col] = pd.to_numeric(
                    chart_df[value_col], errors="coerce"
                )
                chart_df = chart_df.dropna(subset=[value_col]).reset_index(drop=True)
                chart_df["row_number"] = chart_df.index + 1

                st.scatter_chart(
                    chart_df.set_index("row_number")[[value_col]],
                    width="stretch",
                    height=400,
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 7: 2 Cells
col7_1, col7_2 = st.columns(2)
with col7_1:
    cell_7_1()
with col7_2:
    cell_7_2()


def query_8_1() -> str:
    sql_query = f"""
-- why do we have so many non-sage downloads and so few external downloads?

select
    user_id,
    count(*) as downloads_per_user
from
    synapse_data_warehouse.synapse_event.objectdownload_event
where
    project_id in ({ELITE_PROJECT_IDS_SQL})
group by user_id
order by downloads_per_user desc
;

  """

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
                st.markdown("### ELITE user status exploration")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_8_1",
                help="Refresh elite_user_status_exploration data",
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
                st.dataframe(df, width="stretch", hide_index=True, height=400)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_8_2() -> str:
    sql_query = f"""
select
    file_handle_id,
    annotations,
from
    synapse_data_warehouse.synapse.node_latest
where
    project_id in ({ELITE_PROJECT_IDS_SQL})  """

    return sql_query


execute_query(query_8_2())


@st.fragment
def cell_8_2():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### 2024-11-25 10:42am")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_8_2",
                help="Refresh 2024-11-25_10:42am data",
            ):
                execute_query.clear(query_8_2())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_8_2())).result(
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


# Row 8: 2 Cells
col8_1, col8_2 = st.columns(2)
with col8_1:
    cell_8_1()
with col8_2:
    cell_8_2()


def query_9_1() -> str:
    sql_query = f"""

with node_annotations as (
    select
        file_handle_id,
        annotations:annotations:study:value[0] as study,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in ({ELITE_PROJECT_IDS_SQL})
), dedup_downloads as (
    select
        objectdownload_event.user_id, objectdownload_event.record_date, objectdownload_event.file_handle_id, node_annotations.study
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
        on objectdownload_event.file_handle_id = node_annotations.file_handle_id
    where
        objectdownload_event.record_date BETWEEN DATE('2024-01-01') AND DATE('2024-12-31')
        -- filedownload.record_date >= DATE('2024-12-31')

), external_users as (
    select id as user_id
    from
        synapse_data_warehouse.synapse.userprofile_latest
    where
        email not ilike '%@sagebase.org' and email not ilike '%sagebionetworks.org'

), file_size as(
    select
        id,
        content_size  
    from synapse_data_warehouse.synapse.file_latest
)
select
    study,
    count(record_date) AS number_of_total_downloads,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    round(sum(file_size.content_size) / power(2, 30), 2) AS total_GiB_downloaded
from
    dedup_downloads
inner join
    external_users
    on dedup_downloads.user_id = external_users.user_id
left join
    file_size
    on dedup_downloads.file_handle_id = file_size.id
where
    study is not null
group by
    study
order by
    number_of_unique_users desc, study desc
;  """

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
                st.markdown("### 2025-01-28 12:16am")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_9_1",
                help="Refresh 2025-01-28_12:16am data",
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


# Footer
st.markdown("---")
st.markdown(
    "*Dashboard loaded: {}*".format(dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
)
