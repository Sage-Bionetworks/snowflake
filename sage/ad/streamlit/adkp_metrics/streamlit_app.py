import argparse
import datetime as dt
import streamlit as st
import pandas as pd
from snowflake.snowpark import Session
import snowflake.snowpark.context as snowpark_context

# Set page config
st.set_page_config(page_title="ADKP Metrics", layout="wide")

# Title
st.title("ADKP Metrics")


# Initialize session configured for local dev and Streamlit in Snowflake
def read_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--local-dev", action="store_true")
    return parser.parse_args()


def get_session(local_dev: bool) -> Session:
    if local_dev:
        return Session.builder.config("connection_name", "default").create()
    return snowpark_context.get_active_session()


args = read_args()
session = get_session(args.local_dev)
try:
    session.query_tag = "__generated_streamlit"
except Exception:
    pass

# Parameter input widgets arranged in a row
(param_col_1,) = st.columns(1)

with param_col_1:
    # Parameter: datebucket
    st.markdown("**Date bucket**")
    input_datebucket = st.selectbox(
        "Date bucket",
        options=["Second", "Minute", "Hour", "Day", "Week", "Month", "Quarter", "Year"],
        index=7,
        label_visibility="collapsed",
        key="datebucket_param",
    )

st.markdown("---")


@st.cache_data(ttl="23h50m")
def execute_query(query: str) -> str:
    return session.sql(query).collect_nowait().query_id


def query_1_1() -> str:
    sql_query = r"""
select
    min(record_date) as earliest_download_record,
    max(record_date) as latest_download_record
from
    synapse_data_warehouse.synapse_event.objectdownload_event
where
    project_id in (
        2580853
    );
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
                st.markdown("### Download record date range")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_1",
                help="Refresh download_record_date_range data",
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
    sql_query = r"""

    SELECT
        count(distinct(FILE_LATEST.ID)) as TOTAL_FILES,
        round(sum(FILE_LATEST.CONTENT_SIZE) / power(2, 40), 2) AS TOTAL_SIZE_IN_TB
        -- round(sum(FILE_LATEST.CONTENT_SIZE) / power(2, 30) * 0.023 * 12, 2) AS PRICE_PER_YEAR
    FROM
        SYNAPSE_DATA_WAREHOUSE.SYNAPSE.FILE_LATEST
    join
        synapse_data_warehouse.synapse.node_latest
        on file_latest.id = node_latest.file_handle_id
    where
        node_latest.project_id = 2580853  """

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
                st.markdown("### Portal Summary - files, volume, storage cost")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_2",
                help="Refresh portal_summary_-_files,_volume,_storage_cost data",
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


def query_1_3() -> str:
    sql_query = r"""

SELECT
    node_latest.annotations:annotations:dataType:value as datatype,
    count(*) as number_of_files,
    sum(file_latest.content_size) / power(2, 30) as size_in_gib
    -- round(sum(FILE_LATEST.CONTENT_SIZE) / power(2, 30) * 0.023 * 12, 2) AS PRICE_PER_YEAR
FROM
    SYNAPSE_DATA_WAREHOUSE.SYNAPSE.FILE_LATEST
join
    synapse_data_warehouse.synapse.node_latest
    on file_latest.id = node_latest.file_handle_id
where
    node_latest.project_id = 2580853
group by
    datatype  """

    return sql_query


execute_query(query_1_3())


@st.fragment
def cell_1_3():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Portal Summary - data type distribution")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_3",
                help="Refresh portal_summary_-_data_type_distribution data",
            ):
                execute_query.clear(query_1_3())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_1_3())).result(
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


# Row 1: 3 Cells
col1_1, col1_2, col1_3 = st.columns(3)
with col1_1:
    cell_1_1()
with col1_2:
    cell_1_2()
with col1_3:
    cell_1_3()


def query_2_1() -> str:
    sql_query = r"""
with dedup_downloads as (
    select
        user_id, record_date, file_handle_id
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    where project_id = 2580853
        
), file_size as(
    select
        id,
        content_size  
    from synapse_data_warehouse.synapse.file_latest
)
select
    count(*) AS number_of_downloads,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    round(sum(file_size.content_size) / power(2, 50), 2) AS PB_downloaded
from
    dedup_downloads
left join
    file_size
    on dedup_downloads.file_handle_id = file_size.id
;
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
    sql_query = r"""
with dedup_downloads as (
    select
        user_id, record_date, file_handle_id, 
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    where project_id = 2580853
        
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
    count(*) AS number_of_downloads,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    round(sum(file_size.content_size) / power(2, 50), 2) AS PB_downloaded
from
    dedup_downloads
inner join
    external_users
    on dedup_downloads.user_id = external_users.user_id
left join
    file_size
    on dedup_downloads.file_handle_id = file_size.id
;  """

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
                st.markdown("### All time non-Sage downloads")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_2",
                help="Refresh all_time_non-sage_downloads data",
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


# Row 2: 2 Cells
col2_1, col2_2 = st.columns(2)
with col2_1:
    cell_2_1()
with col2_2:
    cell_2_2()


def query_3_1() -> str:
    # Transform :datebucket parameter - convert to DATE_TRUNC call
    expr_datebucket = f"DATE_TRUNC('{input_datebucket}', RECORD_DATE)"

    sql_query = rf"""
-- Distribution of downloads, users, and TB downloaded over months
with dedup_downloads as (
    select 
        objectdownload_event.user_id,
        objectdownload_event.file_handle_id,
        objectdownload_event.record_date,
        file_latest.content_size
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    join
        synapse_data_warehouse.synapse.file_latest
        on objectdownload_event.file_handle_id = file_latest.id
    where
        project_id = 2580853
)
SELECT
    {expr_datebucket} as MONTH_OF_DL,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct USER_ID) UNIQUE_USERS,
    round(sum(content_size) / power(2, 40), 2) AS TB_DOWNLOADED
FROM
    dedup_downloads
GROUP BY
    MONTH_OF_DL
ORDER BY
    MONTH_OF_DL DESC
    NULLS LAST;  """

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
                st.markdown("### downloads per month")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_1",
                help="Refresh downloads_per_month data",
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
--- Downloads from AD Portal Jan 1 2022 - Oct 18 2023
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
        annotations:annotations:study:value[0] as study,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
        )
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.study
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations on
        objectdownload_event.file_handle_id = node_annotations.file_handle_id
), external_users as (
    select
        id as user_id
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
    count(record_date) AS number_of_downloads,
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
    number_of_unique_users desc, study desc
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
                st.markdown("### Downloads per study")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_2",
                help="Refresh downloads_per_study data",
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

--- Excludes files labelled "resouceType = metadata" to avoid miscounting files annotated with multiple studies

with node_annotations as (
    select
        file_handle_id,
        annotations:annotations:dataType:value[0] as dataType,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
        )
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.dataType
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
    on
        objectdownload_event.file_handle_id = node_annotations.file_handle_id
), external_users as (
    select
        id as user_id
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
    dataType,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    count(record_date) AS number_of_downloads,
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
    dataType is not null
group by
    dataType
order by
    number_of_unique_users desc, dataType desc
-- ;


-- SELECT
--     datatype,
--     COUNT(RECORD_DATE) as number_downloads,
--     count(distinct USER_ID) distinct_users_downloading,
--     count(distinct id) as total_files,
--     number_downloads/total_files as mean_downloads_per_file
-- FROM
--     SAGE.PORTAL_DOWNLOADS.AD
-- WHERE
--     resourceType != 'metadata' AND datatype != '[]' AND NOT datatype LIKE '%,%'
-- GROUP BY
--     datatype
-- ORDER BY
--     distinct_users_downloading DESC;  """

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
                st.markdown("### Total downloads by datatype")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_3",
                help="Refresh total_downloads_by_datatype data",
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


# Row 3: 3 Cells
col3_1, col3_2, col3_3 = st.columns(3)
with col3_1:
    cell_3_1()
with col3_2:
    cell_3_2()
with col3_3:
    cell_3_3()


def query_4_1() -> str:
    sql_query = r"""
with individuals as (
    select
        annotations:annotations:individualID:value as individualID,
        annotations:annotations:species:value[0] as species
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
        )
)
select
    case 
        when grouping(species) = 1 then 'Total'
        else species
    end species,
    count(distinct individualID)
from
    individuals
where individualID is not null
group by 
    rollup(species)
order by count(distinct individualID) desc;  """

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
                st.markdown("### unique individuals from annotations")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_1",
                help="Refresh unique_individuals_from_annotations data",
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
                st.dataframe(df, width="stretch", hide_index=True, height=400)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_4_2() -> str:
    sql_query = r"""
with specimens as (
    select
        annotations:annotations:specimenID:value as specimenID,
        annotations:annotations:species:value[0] as species
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
        )
)
select
    case 
        when grouping(species) = 1 then 'Total'
        else species
    end species,
    count(distinct specimenID)
from
    specimens
where
    specimenID is not null
group by 
    rollup(species)
order by
    count(distinct specimenID) desc;  """

    return sql_query


execute_query(query_4_2())


@st.fragment
def cell_4_2():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### unique specimens from annotations")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_2",
                help="Refresh unique_specimens_from_annotations data",
            ):
                execute_query.clear(query_4_2())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_4_2())).result(
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


def query_4_3() -> str:
    # Transform :datebucket parameter - convert to DATE_TRUNC call
    expr_datebucket = f"DATE_TRUNC('{input_datebucket}', RECORD_DATE)"

    sql_query = rf"""
-- Distribution of downloads, users, and TB downloaded over months
with dedup_downloads as (
    select 
        objectdownload_event.user_id,
        objectdownload_event.file_handle_id,
        objectdownload_event.record_date,
        file_latest.content_size
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    join
        synapse_data_warehouse.synapse.file_latest
        on objectdownload_event.file_handle_id = file_latest.id
    where
        project_id = 2580853
)
SELECT
    {expr_datebucket} as MONTH_OF_DL,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct USER_ID) UNIQUE_USERS,
    round(sum(content_size) / power(2, 40), 2) AS TB_DOWNLOADED
FROM
    dedup_downloads
GROUP BY
    MONTH_OF_DL
ORDER BY
    MONTH_OF_DL DESC
    NULLS LAST;  """

    return sql_query


execute_query(query_4_3())


@st.fragment
def cell_4_3():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### downloads per month")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_3",
                help="Refresh downloads_per_month data",
            ):
                execute_query.clear(query_4_3())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_4_3())).result(
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
                    df.groupby(by="MONTH_OF_DL", sort=False)
                    .agg(col1=("NUMBER_OF_DOWNLOADS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_DOWNLOADS (sum)"})
                    .reset_index()
                )

                st.area_chart(
                    df.set_index("MONTH_OF_DL"),
                    width="stretch",
                    height=400,
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 4: 3 Cells
col4_1, col4_2, col4_3 = st.columns(3)
with col4_1:
    cell_4_1()
with col4_2:
    cell_4_2()
with col4_3:
    cell_4_3()


def query_5_1() -> str:
    sql_query = r"""
-- Distribution of downloads, users, and TB downloaded over months
with dedup_downloads as (
    select 
        objectdownload_event.user_id,
        objectdownload_event.file_handle_id,
        objectdownload_event.record_date,
        file_latest.content_size
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    join
        synapse_data_warehouse.synapse.file_latest
        on objectdownload_event.file_handle_id = file_latest.id
    where
        project_id = 2580853
)
SELECT
    date_trunc('MONTH', RECORD_DATE) AS MONTH_OF_DL,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct USER_ID) UNIQUE_USERS,
    round(sum(content_size) / power(2, 40), 2) AS TB_DOWNLOADED
FROM
    dedup_downloads
GROUP BY
    MONTH_OF_DL
ORDER BY
    MONTH_OF_DL DESC
    NULLS LAST;  """

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
                st.markdown("### unique users per month")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_1",
                help="Refresh unique_users_per_month data",
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

            # Calculate metric for scorecard
            if len(df) > 0:
                value = df["UNIQUE_USERS"].mean()
                st.metric(label="UNIQUE_USERS", value=f"{value:,.0f}")
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_5_2() -> str:
    sql_query = r"""
-- Distribution of downloads, users, and TB downloaded over months
with dedup_downloads as (
    select 
        objectdownload_event.user_id,
        objectdownload_event.file_handle_id,
        objectdownload_event.record_date,
        file_latest.content_size
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    join
        synapse_data_warehouse.synapse.file_latest
        on objectdownload_event.file_handle_id = file_latest.id
    where
        project_id = 2580853
)

SELECT
    date_trunc('MONTH', RECORD_DATE) AS MONTH_OF_DL,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct USER_ID) UNIQUE_USERS,
    round(sum(content_size) / power(2, 40), 2) AS TB_DOWNLOADED
FROM
    dedup_downloads
GROUP BY
    MONTH_OF_DL
ORDER BY
    MONTH_OF_DL DESC
    NULLS LAST;  """

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
                st.markdown("### TB downloaded per month")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_2",
                help="Refresh tb_downloaded_per_month data",
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

            # Prepare data for line chart with aggregation
            if len(df) > 0:
                df = (
                    df.groupby(by="MONTH_OF_DL", sort=False)
                    .agg(col1=("NUMBER_OF_DOWNLOADS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_DOWNLOADS (sum)"})
                    .reset_index()
                )

                st.area_chart(
                    df.set_index("MONTH_OF_DL"),
                    width="stretch",
                    height=400,
                    x_label="MONTH",
                    y_label="TB_DOWNLOADED",
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

--- Excludes files labelled "resouceType = metadata" to avoid miscounting files annotated with multiple studies

with node_annotations as (
    select
        file_handle_id,
        annotations:annotations:dataType:value[0] as dataType,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
        )
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.dataType
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
    on
        objectdownload_event.file_handle_id = node_annotations.file_handle_id
), external_users as (
    select
        id as user_id
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
    dataType,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    count(record_date) AS number_of_downloads,
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
    dataType is not null
group by
    dataType
order by
    number_of_unique_users desc, dataType desc
-- ;


-- SELECT
--     datatype,
--     COUNT(RECORD_DATE) as number_downloads,
--     count(distinct USER_ID) distinct_users_downloading,
--     count(distinct id) as total_files,
--     number_downloads/total_files as mean_downloads_per_file
-- FROM
--     SAGE.PORTAL_DOWNLOADS.AD
-- WHERE
--     resourceType != 'metadata' AND datatype != '[]' AND NOT datatype LIKE '%,%'
-- GROUP BY
--     datatype
-- ORDER BY
--     distinct_users_downloading DESC;  """

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
                st.markdown("### Total downloads by datatype")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_1",
                help="Refresh total_downloads_by_datatype data",
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

            # Prepare data for bar chart
            if len(df) > 0:
                df = (
                    df.groupby(by="DATATYPE", sort=False)
                    .agg(col1=("NUMBER_OF_DOWNLOADS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_DOWNLOADS (sum)"})
                    .reset_index()
                )

                df["/* Order Key (Generated by Snowflake) */"] = df.drop(
                    columns="DATATYPE"
                ).sum(axis=1)

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["DATATYPE"]):
                    datetime_primary_column = df["DATATYPE"]
                elif df["DATATYPE"].dtype == "object" and isinstance(
                    df["DATATYPE"].get(df["DATATYPE"].first_valid_index()), dt.date
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["DATATYPE"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["DATATYPE"] = df["DATATYPE"].astype("string")

                st.bar_chart(
                    df,
                    x="DATATYPE",
                    y=[
                        c
                        for c in df.columns
                        if c != "DATATYPE"
                        and c != "/* Order Key (Generated by Snowflake) */"
                    ],
                    sort="-/* Order Key (Generated by Snowflake) */",
                    width="stretch",
                    height=400,
                    horizontal=True,
                    stack=False,
                    x_label="NUMBER_DOWNLOADS",
                    y_label="DATATYPE",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_6_2() -> str:
    sql_query = r"""

--- Excludes files labelled "resouceType = metadata" to avoid miscounting files annotated with multiple studies

with node_annotations as (
    select
        file_handle_id,
        annotations:annotations:dataType:value[0] as dataType,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
        )
), dedup_downloads as (
    select
        distinct filedownload.user_id, filedownload.record_date, filedownload.file_handle_id, node_annotations.dataType
    from
    synapse_data_warehouse.synapse_event.objectdownload_event filedownload
    inner join
        node_annotations
    on
        filedownload.file_handle_id = node_annotations.file_handle_id
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
    dataType,
    count(record_date) AS number_of_downloads,
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
    dataType is not null
group by
    dataType
order by
    number_of_unique_users desc, dataType desc;  """

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
                st.markdown("### Unique users downloading by datatype")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_2",
                help="Refresh unique_users_downloading_by_datatype data",
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

            # Prepare data for bar chart
            if len(df) > 0:
                df = (
                    df.groupby(by="DATATYPE", sort=False)
                    .agg(col1=("NUMBER_OF_UNIQUE_USERS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_UNIQUE_USERS (sum)"})
                    .reset_index()
                )

                df["/* Order Key (Generated by Snowflake) */"] = df.drop(
                    columns="DATATYPE"
                ).sum(axis=1)

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["DATATYPE"]):
                    datetime_primary_column = df["DATATYPE"]
                elif df["DATATYPE"].dtype == "object" and isinstance(
                    df["DATATYPE"].get(df["DATATYPE"].first_valid_index()), dt.date
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["DATATYPE"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["DATATYPE"] = df["DATATYPE"].astype("string")

                st.bar_chart(
                    df,
                    x="DATATYPE",
                    y=[
                        c
                        for c in df.columns
                        if c != "DATATYPE"
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


# Row 6: 2 Cells
col6_1, col6_2 = st.columns(2)
with col6_1:
    cell_6_1()
with col6_2:
    cell_6_2()


def query_7_1() -> str:
    sql_query = r"""

--- Excludes Sage users

with node_annotations as (
    select
        file_handle_id,
        annotations:annotations:dataType:value[0] as dataType,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
        )
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.dataType
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations on
        objectdownload_event.file_handle_id = node_annotations.file_handle_id
), external_users as (
    select id as user_id
    from
        synapse_data_warehouse.synapse.userprofile_latest
    where
        email not ilike '%@sagebase.org' and email not ilike '%sagebionetworks.org'
), annotation_count as (
  select count(file_handle_id) as total_annotations
  from node_annotations
)
select
    dataType,
  round(count(record_date) / max(annotation_count.total_annotations), 2) as mean_downloads_per_file
from
    dedup_downloads
cross join
  annotation_count
inner join
    external_users
    on dedup_downloads.user_id = external_users.user_id
where
    dataType is not null
group by
    dataType
order by
    mean_downloads_per_file desc, dataType desc;  """

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
                st.markdown("### Mean downloads per file by datatype")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_7_1",
                help="Refresh mean_downloads_per_file_by_datatype data",
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

            # Prepare data for bar chart
            if len(df) > 0:
                df = df[["DATATYPE", "MEAN_DOWNLOADS_PER_FILE"]]

                df["/* Order Key (Generated by Snowflake) */"] = df.drop(
                    columns="DATATYPE"
                ).sum(axis=1)

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["DATATYPE"]):
                    datetime_primary_column = df["DATATYPE"]
                elif df["DATATYPE"].dtype == "object" and isinstance(
                    df["DATATYPE"].get(df["DATATYPE"].first_valid_index()), dt.date
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["DATATYPE"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["DATATYPE"] = df["DATATYPE"].astype("string")

                st.bar_chart(
                    df,
                    x="DATATYPE",
                    y=[
                        c
                        for c in df.columns
                        if c != "DATATYPE"
                        and c != "/* Order Key (Generated by Snowflake) */"
                    ],
                    sort="-/* Order Key (Generated by Snowflake) */",
                    width="stretch",
                    height=400,
                    horizontal=True,
                    stack=False,
                    x_label="MEAN_DOWNLOADS_PER_FILE",
                    y_label="DATATYPE",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_7_2() -> str:
    sql_query = r"""

--- Excludes files labelled "resouceType = metadata" to avoid miscounting files annotated with multiple studies

with node_annotations as (
    select
        file_handle_id,
        annotations:annotations:dataType:value[0] as dataType,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
        )
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.dataType
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations on
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
    dataType,
    count(record_date) AS number_of_downloads,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    round(sum(file_size.content_size) / power(2, 40), 2) AS TB_downloaded
from
    dedup_downloads
inner join
    external_users
    on dedup_downloads.user_id = external_users.user_id
left join
    file_size
    on dedup_downloads.file_handle_id = file_size.id
where
    dataType is not null
group by
    dataType
order by
    number_of_unique_users desc, dataType desc;  """

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
                st.markdown("### Volume downloaded (TB) by data type")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_7_2",
                help="Refresh volume_downloaded_(tb)_by_data_type data",
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

            # Prepare data for bar chart
            if len(df) > 0:
                df = df[["DATATYPE", "TB_DOWNLOADED"]]

                df["/* Order Key (Generated by Snowflake) */"] = df.drop(
                    columns="DATATYPE"
                ).sum(axis=1)

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["DATATYPE"]):
                    datetime_primary_column = df["DATATYPE"]
                elif df["DATATYPE"].dtype == "object" and isinstance(
                    df["DATATYPE"].get(df["DATATYPE"].first_valid_index()), dt.date
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["DATATYPE"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["DATATYPE"] = df["DATATYPE"].astype("string")

                st.bar_chart(
                    df,
                    x="DATATYPE",
                    y=[
                        c
                        for c in df.columns
                        if c != "DATATYPE"
                        and c != "/* Order Key (Generated by Snowflake) */"
                    ],
                    sort="-/* Order Key (Generated by Snowflake) */",
                    width="stretch",
                    height=400,
                    horizontal=True,
                    stack=False,
                    x_label="TB_DOWNLOADED",
                    y_label="DATATYPE",
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
    sql_query = r"""
-- Distribution of downloads, users, and TB downloaded over months
with dedup_downloads as (
    select 
        objectdownload_event.user_id,
        objectdownload_event.file_handle_id,
        objectdownload_event.record_date,
        file_latest.content_size
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    join
        synapse_data_warehouse.synapse.file_latest
        on objectdownload_event.file_handle_id = file_latest.id
    where
        project_id = 2580853
)
SELECT
    date_trunc('MONTH', RECORD_DATE) AS MONTH_OF_DL,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct USER_ID) UNIQUE_USERS,
    round(sum(content_size) / power(2, 40), 2) AS TB_DOWNLOADED
FROM
    dedup_downloads
GROUP BY
    MONTH_OF_DL
ORDER BY
    MONTH_OF_DL DESC
    NULLS LAST;  """

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
                st.markdown("### unique users per month")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_8_1",
                help="Refresh unique_users_per_month data",
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
    sql_query = r"""
select 
    record_date,
    sum("'TRUE'") AS internal_users,
    sum("'FALSE'") AS external_users
    from sage.ad.user_frequency
    pivot(count(user_id) for sage_internal in ('TRUE', 'FALSE'))
        as p
    group by record_date
    order by
        record_date desc;  """

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
                st.markdown("### internal vs external AD portal users")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_8_2",
                help="Refresh internal_vs_external_ad_portal_users data",
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

            # Prepare data for line chart with aggregation
            if len(df) > 0:
                df = (
                    df.groupby(by="RECORD_DATE", sort=False)
                    .agg(col1=("INTERNAL_USERS", "sum"), col2=("EXTERNAL_USERS", "sum"))
                    .rename(
                        columns={
                            "col1": "INTERNAL_USERS (sum)",
                            "col2": "EXTERNAL_USERS (sum)",
                        }
                    )
                    .reset_index()
                )

                st.line_chart(
                    df.set_index("RECORD_DATE"),
                    width="stretch",
                    height=400,
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 8: 2 Cells
col8_1, col8_2 = st.columns(2)
with col8_1:
    cell_8_1()
with col8_2:
    cell_8_2()


def query_9_1() -> str:
    sql_query = r"""
--- AD Portal monthly downloads by study 
--- does NOT exclude users with a sagebionetworks email domain (not a great proxy for internal/external)

with node_annotations as (
    select
        file_handle_id,
        annotations:annotations:study:value[0]::string as study,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
        )
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.study
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations on
        objectdownload_event.file_handle_id = node_annotations.file_handle_id
        
), file_size as(
    select
        id,
        content_size  
    from synapse_data_warehouse.synapse.file_latest
)
select
    study,
    date_trunc('month', record_date) as month,
    count(record_date) AS number_of_downloads,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    round(sum(file_size.content_size) / power(2, 30), 2) AS GiB_downloaded
from
    dedup_downloads
left join
    file_size
on
    dedup_downloads.file_handle_id = file_size.id
where study is not null
group by
    month, study
order by
    month desc, number_of_unique_users desc, study desc
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
                st.markdown("### Study x Month - AD Portal Unique Users Downloading")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_9_1",
                help="Refresh study_x_month_-_ad_portal_unique_users_downloading data",
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
                st.dataframe(df, width="stretch", hide_index=True, height=400)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_9_2() -> str:
    sql_query = r"""
--- AD Portal monthly downloads by study 
--- does NOT exclude users with a sagebionetworks email domain (not a great proxy for internal/external)

with node_annotations as (
    select
        file_handle_id,
        annotations:annotations:study:value[0]::string as study,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
        )
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.study
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations on
        objectdownload_event.file_handle_id = node_annotations.file_handle_id
        
), file_size as(
    select
        id,
        content_size  
    from synapse_data_warehouse.synapse.file_latest
)
select
    study,
    date_trunc('month', record_date) as month,
    count(record_date) AS number_of_downloads,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    round(sum(file_size.content_size) / power(2, 30), 2) AS GiB_downloaded
from
    dedup_downloads
left join
    file_size
on
    dedup_downloads.file_handle_id = file_size.id
where study is not null
group by
    month, study
order by
    month desc, number_of_unique_users desc, study desc
;  """

    return sql_query


execute_query(query_9_2())


@st.fragment
def cell_9_2():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Study x Month - AD Portal Unique Users Downloading")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_9_2",
                help="Refresh study_x_month_-_ad_portal_unique_users_downloading data",
            ):
                execute_query.clear(query_9_2())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_9_2())).result(
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
                df = (
                    df.groupby(by=["MONTH", "STUDY"], sort=False)
                    .agg(col1=("NUMBER_OF_UNIQUE_USERS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_UNIQUE_USERS (sum)"})
                    .unstack(level=1)
                )

                df.columns = [
                    " | ".join(map(str, c[::-1])).replace(":", "_") for c in df.columns
                ]

                df = df.reset_index()

                df["/* Order Key (Generated by Snowflake) */"] = df["MONTH"]

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["MONTH"]):
                    datetime_primary_column = df["MONTH"]
                elif df["MONTH"].dtype == "object" and isinstance(
                    df["MONTH"].get(df["MONTH"].first_valid_index()), dt.date
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["MONTH"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["MONTH"] = df["MONTH"].astype("string")

                st.bar_chart(
                    df,
                    x="MONTH",
                    y=[
                        c
                        for c in df.columns
                        if c != "MONTH"
                        and c != "/* Order Key (Generated by Snowflake) */"
                    ],
                    sort="-/* Order Key (Generated by Snowflake) */",
                    width="stretch",
                    height=400,
                    horizontal=True,
                    stack=True,
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 9: 2 Cells
col9_1, col9_2 = st.columns(2)
with col9_1:
    cell_9_1()
with col9_2:
    cell_9_2()


def query_10_1() -> str:
    sql_query = r"""
select 
    --datebucket(RECORD_DATE) as MONTH_OF_DL,
    year(month_created) as year,
    monthname(month_created) as month,
    month_created as measurement_point, 
    simple_assay,
    round((cumulative_volume) / power(2, 40), 2) as cumulative_volume_TB
from 
    sage.ad.datatype_cumulative_volume
where 
    simple_assay is not null 
    and simple_assay not in ('', 'Blood Chemistry Measurement', 'polymeraseChainReaction')
    and year >= 2015
order by 
    measurement_point desc,
    cumulative_volume_TB desc
;
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
                st.markdown("### cumulative upload volume (TB) by data type")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_10_1",
                help="Refresh cumulative_upload_volume_(tb)_by_data_type data",
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

            # Prepare data for bar chart
            if len(df) > 0:
                df = (
                    df.groupby(by=["MEASUREMENT_POINT", "SIMPLE_ASSAY"], sort=False)
                    .agg(col1=("CUMULATIVE_VOLUME_TB", "sum"))
                    .rename(columns={"col1": "CUMULATIVE_VOLUME_TB (sum)"})
                    .unstack(level=1)
                )

                df.columns = [
                    " | ".join(map(str, c[::-1])).replace(":", "_") for c in df.columns
                ]

                df = df.reset_index()

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["MEASUREMENT_POINT"]):
                    datetime_primary_column = df["MEASUREMENT_POINT"]
                elif df["MEASUREMENT_POINT"].dtype == "object" and isinstance(
                    df["MEASUREMENT_POINT"].get(
                        df["MEASUREMENT_POINT"].first_valid_index()
                    ),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["MEASUREMENT_POINT"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["MEASUREMENT_POINT"] = df["MEASUREMENT_POINT"].astype("string")

                st.bar_chart(
                    df.set_index("MEASUREMENT_POINT"),
                    sort=True,
                    width="stretch",
                    height=400,
                    stack=True,
                    x_label="year-month",
                    y_label="CUMULATIVE_VOLUME (TB)",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 10: Single Cell
cell_10_1()


def query_11_1() -> str:
    sql_query = r"""
-- Grouping by the simplified combination assay/data type categories
-- how many total file downloads and total download volume since Jan 2022

select
    simple_assay,
    sum(total_downloads) as total_downloads,
    round(sum(content_size * total_downloads) / power(2, 40), 3) as total_download_volume_TB
from sage.ad.cumulative_downloads_simple_assay
where simple_assay is not null
group by simple_assay
order by total_downloads desc
;  """

    return sql_query


execute_query(query_11_1())


@st.fragment
def cell_11_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Combined Downloads by Data Type since Jan 2022")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_11_1",
                help="Refresh combined_downloads_by_data_type_since_jan_2022 data",
            ):
                execute_query.clear(query_11_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_11_1())).result(
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
                df = df[["SIMPLE_ASSAY", "TOTAL_DOWNLOADS"]]

                df["/* Order Key (Generated by Snowflake) */"] = df.drop(
                    columns="SIMPLE_ASSAY"
                ).sum(axis=1)

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["SIMPLE_ASSAY"]):
                    datetime_primary_column = df["SIMPLE_ASSAY"]
                elif df["SIMPLE_ASSAY"].dtype == "object" and isinstance(
                    df["SIMPLE_ASSAY"].get(df["SIMPLE_ASSAY"].first_valid_index()),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["SIMPLE_ASSAY"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["SIMPLE_ASSAY"] = df["SIMPLE_ASSAY"].astype("string")

                st.bar_chart(
                    df,
                    x="SIMPLE_ASSAY",
                    y=[
                        c
                        for c in df.columns
                        if c != "SIMPLE_ASSAY"
                        and c != "/* Order Key (Generated by Snowflake) */"
                    ],
                    sort="-/* Order Key (Generated by Snowflake) */",
                    width="stretch",
                    height=400,
                    horizontal=True,
                    stack=False,
                    x_label="TOTAL_DOWNLOADS",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_11_2() -> str:
    sql_query = r"""
-- Grouping by the simplified combination assay/data type categories
-- how many total file downloads and total download volume since Jan 2022

select
    simple_assay,
    sum(total_downloads) as total_downloads,
    round(sum(content_size * total_downloads) / power(2, 40), 3) as total_download_volume_TB
from sage.ad.cumulative_downloads_simple_assay
where simple_assay is not null
group by simple_assay
order by total_downloads desc
;  """

    return sql_query


execute_query(query_11_2())


@st.fragment
def cell_11_2():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown(
                    "### Combined Total Download Volume by Data Type since Jan 2022"
                )
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_11_2",
                help="Refresh combined_total_download_volume_by_data_type_since_jan_2022 data",
            ):
                execute_query.clear(query_11_2())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_11_2())).result(
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
                df = df[["SIMPLE_ASSAY", "TOTAL_DOWNLOAD_VOLUME_TB"]]

                df["/* Order Key (Generated by Snowflake) */"] = df.drop(
                    columns="SIMPLE_ASSAY"
                ).sum(axis=1)

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["SIMPLE_ASSAY"]):
                    datetime_primary_column = df["SIMPLE_ASSAY"]
                elif df["SIMPLE_ASSAY"].dtype == "object" and isinstance(
                    df["SIMPLE_ASSAY"].get(df["SIMPLE_ASSAY"].first_valid_index()),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["SIMPLE_ASSAY"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["SIMPLE_ASSAY"] = df["SIMPLE_ASSAY"].astype("string")

                st.bar_chart(
                    df,
                    x="SIMPLE_ASSAY",
                    y=[
                        c
                        for c in df.columns
                        if c != "SIMPLE_ASSAY"
                        and c != "/* Order Key (Generated by Snowflake) */"
                    ],
                    sort="-/* Order Key (Generated by Snowflake) */",
                    width="stretch",
                    height=400,
                    horizontal=True,
                    stack=False,
                    x_label="TOTAL_DOWNLOAD_VOLUME_TB",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 11: 2 Cells
col11_1, col11_2 = st.columns(2)
with col11_1:
    cell_11_1()
with col11_2:
    cell_11_2()


def query_12_1() -> str:
    sql_query = r"""
-- uploaded files by consortium

with file_size as (
    select
        id as file_handle_id,
        content_size
    from synapse_data_warehouse.synapse.file_latest
)
select
    trim(spl.value, '"[] ') as consortium,
    count(distinct nl.file_handle_id) as number_files,
    round(sum(content_size)/power(2, 40), 3) as data_volume_TB
from synapse_data_warehouse.synapse.node_latest nl
left join file_size as fs
    on nl.file_handle_id = fs.file_handle_id, lateral split_to_table(annotations:annotations:consortium:value::VARCHAR, ',') spl
where project_id = '2580853' and node_type = 'file' and is_public = 'true' and consortium != 'ROSMAP'
group by consortium
order by number_files desc;  """

    return sql_query


execute_query(query_12_1())


@st.fragment
def cell_12_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Contributed Data per Consortium")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_12_1",
                help="Refresh contributed_data_per_consortium data",
            ):
                execute_query.clear(query_12_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_12_1())).result(
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


def query_12_2() -> str:
    sql_query = r"""
with file_size as (
    select
        id as file_handle_id,
        content_size
    from synapse_data_warehouse.synapse.file_latest
)
select 
    trim(nl.annotations:annotations:organ:value[0], '"') as organ,
    round(sum(fs.content_size)/power(2, 40), 3) as data_volume_TB,
    count(distinct nl.file_handle_id) as number_files
from synapse_data_warehouse.synapse.node_latest nl
left join file_size as fs
    on nl.file_handle_id = fs.file_handle_id,
where project_id = '2580853' 
    and node_type = 'file' 
    and is_public = 'true'
    and annotations:annotations:species:value[0] = 'Human'
    and organ is not null
group by organ
order by data_volume_TB desc
;  """

    return sql_query


execute_query(query_12_2())


@st.fragment
def cell_12_2():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Human Data Volume by Organ")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_12_2",
                help="Refresh human_data_volume_by_organ data",
            ):
                execute_query.clear(query_12_2())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_12_2())).result(
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


# Row 12: 2 Cells
col12_1, col12_2 = st.columns(2)
with col12_1:
    cell_12_1()
with col12_2:
    cell_12_2()


def query_13_1() -> str:
    sql_query = r"""
-- average users per month
-- Distribution of downloads, users, and TB downloaded over months
with dedup_downloads as (
    select 
        distinct filedownload.user_id, filedownload.file_handle_id, filedownload.record_date, file_latest.content_size
    from
    synapse_data_warehouse.synapse_event.objectdownload_event filedownload
    join
        synapse_data_warehouse.synapse.file_latest
        on filedownload.file_handle_id = file_latest.id
    where
        project_id = 2580853
),

monthly_downloads as (
    SELECT
        date_trunc('MONTH', RECORD_DATE) AS MONTH_OF_DL,
        count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
        count(distinct USER_ID) UNIQUE_USERS,
        round(sum(content_size) / power(2, 40), 2) AS TB_DOWNLOADED
    FROM
        dedup_downloads
    GROUP BY
        MONTH_OF_DL
    ORDER BY
        MONTH_OF_DL DESC
        NULLS LAST
)
select 

    avg(number_of_downloads) as avg_downloads,
    avg(unique_users) as avg_unique_users,
    avg(tb_downloaded) as avg_tb_downloaded
from monthly_downloads;

  """

    return sql_query


execute_query(query_13_1())


@st.fragment
def cell_13_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### monthly average usage")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_13_1",
                help="Refresh monthly_average_usage data",
            ):
                execute_query.clear(query_13_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_13_1())).result(
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


# Row 13: Single Cell
cell_13_1()


def query_14_1() -> str:
    sql_query = r"""
--- Excludes Sage users, since 2022
--- excludes metadata files

with node_annotations as (
    select
        file_handle_id,
        annotations:annotations:dataType:value[0] as data_type,
        annotations:annotations:dataSubtype:value[0] as data_subtype,
        annotations:annotations:fileFormat:value[0] as file_format,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
        )
), dedup_downloads as (
    select
        distinct filedownload.user_id, 
        filedownload.record_date, 
        filedownload.file_handle_id, 
        node_annotations.data_type,
        node_annotations.data_subtype,
        node_annotations.file_format
    from
      synapse_data_warehouse.synapse_event.objectdownload_event filedownload
    inner join
        node_annotations
    on
        filedownload.file_handle_id = node_annotations.file_handle_id
), external_users as (
    select id as user_id
    from
        synapse_data_warehouse.synapse.userprofile_latest
    where
        email not ilike '%@sagebase.org' and email not ilike '%sagebionetworks.org'

)
select
    data_subtype,
    file_format,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    count(record_date) AS number_of_downloads
from
    dedup_downloads
inner join
    external_users
    on dedup_downloads.user_id = external_users.user_id
where
    data_type = 'geneExpression'
group by
data_subtype, file_format
order by
    number_of_unique_users desc;  """

    return sql_query


execute_query(query_14_1())


@st.fragment
def cell_14_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown(
                    "### gene expression downloads by file format and data subtype"
                )
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_14_1",
                help="Refresh gene_expression_downloads_by_file_format_and_data_subtype data",
            ):
                execute_query.clear(query_14_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_14_1())).result(
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


def query_14_2() -> str:
    sql_query = r"""
-- data usage for last 30 days from all buckets provisioned by the synapse-service-ad-data-curation-01 service account in the STRIDES service catalog

with bucket_info as (
    select 
        id as file_handle_id,
        bucket,
        content_size
    from synapse_data_warehouse.synapse.file_latest
    where bucket in ('ad-knowledge-portal-large', 
                    'ad-knowledge-portal-main', 
                    'diverse-cohorts', 
                    'exceptional-longevity', 
                    'scientific-wellness')
),
dedup_last_month_downloads as (
    select
        user_id, record_date, file_handle_id, 
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    where record_date between dateadd('month', -1, current_date()) and current_date()           
)
select
    case 
        when grouping(bucket) = 1 then 'Total All Buckets'
        else bucket
    end bucket,
    count(distinct dl.user_id, dl.record_date, dl.file_handle_id) AS number_of_downloads,
    count(distinct dl.user_id) as number_of_unique_users,
    sum(b.content_size)/power(2,30) as download_volume_gb,
    record_date
from bucket_info b
inner join dedup_last_month_downloads dl
    on b.file_handle_id = dl.file_handle_id
group by 
    dl.record_date, 
    rollup(bucket)
order by 
    dl.record_date
;

  """

    return sql_query


execute_query(query_14_2())


@st.fragment
def cell_14_2():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### STRIDES bucket downloads - previous 30 days")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_14_2",
                help="Refresh strides_bucket_downloads_-_previous_30_days data",
            ):
                execute_query.clear(query_14_2())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_14_2())).result(
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
                    df.groupby(by=["RECORD_DATE", "BUCKET"], sort=False)
                    .agg(col1=("NUMBER_OF_DOWNLOADS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_DOWNLOADS (sum)"})
                    .unstack(level=1)
                )

                df.columns = [
                    " | ".join(map(str, c[::-1])).replace(":", "_") for c in df.columns
                ]

                df = df.reset_index()

                st.line_chart(
                    df.set_index("RECORD_DATE"),
                    width="stretch",
                    height=400,
                    y_label="DOWNLOAD_VOLUME_GB",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 14: 2 Cells
col14_1, col14_2 = st.columns(2)
with col14_1:
    cell_14_1()
with col14_2:
    cell_14_2()


def query_15_1() -> str:
    sql_query = r"""
--- AD Portal monthly downloads by study 
--- does NOT exclude users with a sagebionetworks email domain (not a great proxy for internal/external)

with node_annotations as (
    select
        file_handle_id,
        annotations:annotations:study:value[0]::string as study,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
        )
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.study
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations on
        objectdownload_event.file_handle_id = node_annotations.file_handle_id
        
), file_size as(
    select
        id,
        content_size  
    from synapse_data_warehouse.synapse.file_latest
)
select
    study,
    record_date,
    count(record_date) AS number_of_downloads,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    round(sum(file_size.content_size) / power(2, 30), 2) AS GiB_downloaded
from
    dedup_downloads
left join
    file_size
on
    dedup_downloads.file_handle_id = file_size.id
where study is not null and record_date > DATE('2025-01-01')
group by
    record_date, study
order by
    record_date desc, GIB_DOWNLOADED desc, study desc  """

    return sql_query


execute_query(query_15_1())


@st.fragment
def cell_15_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### 2025-01-28 6:51am")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_15_1",
                help="Refresh 2025-01-28_6:51am data",
            ):
                execute_query.clear(query_15_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_15_1())).result(
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
                    df.groupby(by=["RECORD_DATE", "STUDY"], sort=False)
                    .agg(col1=("NUMBER_OF_DOWNLOADS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_DOWNLOADS (sum)"})
                    .unstack(level=1)
                )

                df.columns = [
                    " | ".join(map(str, c[::-1])).replace(":", "_") for c in df.columns
                ]

                df = df.reset_index()

                st.line_chart(
                    df.set_index("RECORD_DATE"),
                    width="stretch",
                    height=400,
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_15_2() -> str:
    sql_query = r"""
with individuals as (
    select
        annotations:annotations:individualID:value as individualID,
        annotations:annotations:species:value[0] as species
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
        )
)
select
    case 
        when grouping(species) = 1 then 'Total'
        else species
    end species,
    count(distinct individualID)
from
    individuals
where individualID is not null
group by 
    rollup(species)
order by count(distinct individualID) desc;  """

    return sql_query


execute_query(query_15_2())


@st.fragment
def cell_15_2():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### unique individuals from annotations")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_15_2",
                help="Refresh unique_individuals_from_annotations data",
            ):
                execute_query.clear(query_15_2())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_15_2())).result(
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
                df = df[["SPECIES", "COUNT(DISTINCT INDIVIDUALID)"]]

                df["/* Order Key (Generated by Snowflake) */"] = df.drop(
                    columns="SPECIES"
                ).sum(axis=1)

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["SPECIES"]):
                    datetime_primary_column = df["SPECIES"]
                elif df["SPECIES"].dtype == "object" and isinstance(
                    df["SPECIES"].get(df["SPECIES"].first_valid_index()), dt.date
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["SPECIES"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["SPECIES"] = df["SPECIES"].astype("string")

                st.bar_chart(
                    df,
                    x="SPECIES",
                    y=[
                        c
                        for c in df.columns
                        if c != "SPECIES"
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


# Row 15: 2 Cells
col15_1, col15_2 = st.columns(2)
with col15_1:
    cell_15_1()
with col15_2:
    cell_15_2()


def query_16_1() -> str:
    sql_query = r"""
select
    node_latest.name as entity_name,
    acl_latest.owner_id as entity_id,
    acl_latest.access_type,
    acl_latest.principal_id as user_or_team_id
from
    synapse_data_warehouse.synapse.node_latest
join
    synapse_data_warehouse.synapse.acl_latest on
    node_latest.id = acl_latest.owner_id
where
    node_latest.project_id = 2580853;  """

    return sql_query


execute_query(query_16_1())


@st.fragment
def cell_16_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Local sharing settings")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_16_1",
                help="Refresh local_sharing_settings data",
            ):
                execute_query.clear(query_16_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_16_1())).result(
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


# Row 16: Single Cell
cell_16_1()


# Footer
st.markdown("---")
st.markdown(
    "*Dashboard loaded: {}*".format(dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
)
