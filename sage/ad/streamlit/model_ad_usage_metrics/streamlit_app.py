import argparse
import datetime as dt
import streamlit as st
import pandas as pd
import altair as alt
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
st.set_page_config(page_title="model-AD Usage Metrics", layout="wide")

# Title
st.title("model-AD Usage Metrics")
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

# Parameter input widgets arranged in a row
(param_col_1,) = st.columns(1)

with param_col_1:
    # Parameter: daterange (relative)
    st.markdown("**Date range**")
    default_start = dt.datetime.now().date() - dt.timedelta(days=30 * 6)
    default_end = dt.datetime.now().date()
    input_daterange = st.date_input(
        "Date range",
        value=(default_start, default_end),
        label_visibility="collapsed",
        key="daterange_param",
    )

st.markdown("---")


@st.cache_data(ttl="23h50m")
def execute_query(query: str) -> str:
    return session.sql(query).collect_nowait().query_id


def query_1_1() -> str:
    sql_query = r"""
-- The Synapse IDs in this query come from
-- The ADTR portal backend table with Synapse folder dataset ids listed when filtered for Program = MODEL-AD.
-- TODO: there can probably be an improvement to automatically query for folders with "program = model-AD"
-- But that may not be accurate

WITH RECURSIVE all_nodes
    -- Column list of the "view"
    (
        ID,
        PARENT_ID,
        -- NAME,
        -- NODE_TYPE,
        FILE_HANDLE_ID,
        ENTITY_ID
    ) 
    AS 
    -- Common Table Expression
    (
        -- Anchor Clause
        SELECT
            ID,
            PARENT_ID,
            -- NAME,
            -- NODE_TYPE,
            FILE_HANDLE_ID,
            ID AS ENTITY_ID
        FROM
            synapse_data_warehouse.synapse.node_latest
        WHERE
            ID IN (
                9850001, 15811463, 16798076, 17095980, 18634479, 21784897, 21595258, 21595255, 18693211, 20730014, 21983020, 22964685, 22313528, 22341543, 25316706, 21863375, 26943950, 50670633, 50944316, 27207345, 51713891, 58863147, 51534997, 27210656, 66318332, 66318364, 68527429, 26943727, 61250684, 65941765, 22341542, 61849889
            )
            
        UNION ALL
        
        -- Recursive Clause
        SELECT
            node.ID,
            node.PARENT_ID,
            -- node.NAME,
            -- node.NODE_TYPE,
            node.FILE_HANDLE_ID,
            all_nodes.ENTITY_ID
        FROM
            synapse_data_warehouse.synapse.node_latest AS node
        JOIN 
            all_nodes 
        ON 
            node.PARENT_ID = all_nodes.ID
)
SELECT
    all_nodes.ENTITY_ID AS STUDY_ID,
    node_latest.name as study_name,
    count(*) as number_of_files,
    sum(file_latest.content_size) / power(2, 30) as size_in_gib
FROM
    all_nodes
join
    synapse_data_warehouse.synapse.node_latest
    on all_nodes.entity_id = node_latest.id
join
    synapse_data_warehouse.synapse.file_latest
    on all_nodes.file_handle_id = file_latest.id
GROUP BY
    all_nodes.ENTITY_ID,
    node_latest.name
order by
    study_name;  """

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
                st.markdown("### Current Study overview")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_1",
                help="Refresh current_study_overview data",
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
-- 1. recursively grab all the subfolders and files that live within these MODEL-AD folders
with recursive all_nodes as (

    -- base of tree: start with the base query, which grabs all the MODEL-AD folders retrieved from the portal table result provided by Karina
    select
        id,
        file_handle_id,
        node_type,
        parent_id
    from
        synapse_data_warehouse.synapse.node_latest
    where
        id in (9850001, 15811463, 16798076, 17095980, 18634479, 21784897, 21595258, 21595255, 18693211, 20730014, 21983020, 22964685, 22313528, 22341543, 25316706, 21863375, 26943950, 50670633, 50944316, 27207345, 51713891, 58863147, 51534997, 27210656, 66318332, 66318364, 68527429, 26943727, 61250684, 65941765, 22341542, 61849889)

    union all

    -- recursively retrieve all subfolders and files within the base folders above ^
    select
        node_latest.id,
        node_latest.file_handle_id,
        node_latest.node_type,
        node_latest.parent_id
    from
        synapse_data_warehouse.synapse.node_latest
    -- the CTE itself needs to be directly referred in FROM clause, so let's join the original results with the recursion results
    -- by matching up the parent_id (original results) to the newly found ids
    join
        all_nodes
    on
        node_latest.parent_id = all_nodes.id
),
-- 2. match up all_nodes.id with objectdownload_event.associaton_object_id to get ALL download records
-- but we don't want to count repeat downloads by the same user on the same day, so select distinct
all_downloads_except_repeats as (

    select
        user_id,
        association_object_id,
        record_date,
        all_nodes.file_handle_id
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    join
        all_nodes
    on
        objectdownload_event.association_object_id = all_nodes.id

),
-- 3. now let's get just the EXTERNAL downloads by filtering users whose e-mails are sagebase e-mails. this is not the most thorough
-- approach (exhibit A: Tom has like 8 different synapse accounts), but it's enough for an estimate. let's just make that clear in the final table
external_downloads as (

    select
        user_id,
        association_object_id,
        record_date,
        file_handle_id
    from
        all_downloads_except_repeats
    join
        synapse_data_warehouse.synapse.userprofile_latest
        on all_downloads_except_repeats.user_id = userprofile_latest.id
    where
        userprofile_latest.email not like '%@sagebase.org'
    and
        userprofile_latest.email not like '%@sagebionetworks.org'

),
-- 4. compute the total downloads
total_count as (

    select
        year(record_date) as year,
        count(*) as total_download_count,
        count(distinct user_id) as total_user_count,
        sum(file_latest.content_size) / power(2, 30) as total_data_egress
    from
        all_downloads_except_repeats
    join
        synapse_data_warehouse.synapse.file_latest
    on
        all_downloads_except_repeats.file_handle_id = file_latest.id
    group by
        year
),
-- 5. compute the estimated external downloads
estimated_external_count as (

    select
        year(record_date) as year,
        count(*) as estimated_external_download_count,
        count(distinct user_id) as estimated_external_user_count,
        sum(file_latest.content_size) / power(2, 30) as estimated_external_data_egress
    from
        external_downloads
    join
        synapse_data_warehouse.synapse.file_latest
    on
        external_downloads.file_handle_id = file_latest.id
    group by
        year

)
-- 6. put everything in a final table
select
    coalesce(tc.year, ec.year) as year,
    tc.total_download_count,
    ec.estimated_external_download_count,
    tc.total_user_count,
    ec.estimated_external_user_count,
    tc.total_data_egress,
    ec.estimated_external_data_egress
from
    total_count tc
full outer join
    estimated_external_count ec
on
    tc.year = ec.year
order by
    year desc;  """

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
                st.markdown("### Downloads, Unique Users, and Data Egress (Per Year)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_1",
                help="Refresh downloads,_unique_users,_and_data_egress_(per_year) data",
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
-- 1. recursively grab all the subfolders and files that live within these MODEL-AD folders
with recursive all_nodes as (

    -- base of tree: start with the base query, which grabs all the MODEL-AD folders retrieved from the portal table result provided by Karina
    select
        id,
        file_handle_id,
        node_type,
        parent_id
    from
        synapse_data_warehouse.synapse.node_latest
    where
        id in (9850001, 15811463, 16798076, 17095980, 18634479, 21784897, 21595258, 21595255, 18693211, 20730014, 21983020, 22964685, 22313528, 22341543, 25316706, 21863375, 26943950, 50670633, 50944316, 27207345, 51713891, 58863147, 51534997, 27210656, 66318332, 66318364, 68527429, 26943727, 61250684, 65941765, 22341542, 61849889)

    union all

    -- recursively retrieve all subfolders and files within the base folders above ^
    select
        node_latest.id,
        node_latest.file_handle_id,
        node_latest.node_type,
        node_latest.parent_id
    from
        synapse_data_warehouse.synapse.node_latest
    -- the CTE itself needs to be directly referred in FROM clause, so let's join the original results with the recursion results
    -- by matching up the parent_id (original results) to the newly found ids
    join
        all_nodes
    on
        node_latest.parent_id = all_nodes.id
),
-- 2. match up all_nodes.id with objectdownload_event.associaton_object_id to get ALL download records
-- but we don't want to count repeat downloads by the same user on the same day, so select distinct
all_downloads_except_repeats as (

    select
        user_id,
        association_object_id,
        record_date
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    join
        all_nodes
    on
        objectdownload_event.association_object_id = all_nodes.id

),
-- 3. now let's get just the EXTERNAL downloads by filtering users whose e-mails are sagebase e-mails. this is not the most thorough
-- approach (exhibit A: Tom has like 8 different synapse accounts), but it's enough for an estimate. let's just make that clear in the final table
external_downloads as (

    select
        user_id,
        association_object_id,
        record_date
    from
        all_downloads_except_repeats
    join
        synapse_data_warehouse.synapse.userprofile_latest
        on all_downloads_except_repeats.user_id = userprofile_latest.id
    where
        userprofile_latest.email not like '%@sagebase.org'
    and
        userprofile_latest.email not like '%@sagebionetworks.org'

),
-- 4. compute the total downloads
total_count as (

    select
        year(record_date) as year,
        count(*) as total_download_count,
        count(distinct user_id) as total_user_count
    from
        all_downloads_except_repeats
    group by
        year
),
-- 5. compute the estimated external downloads
estimated_external_count as (

    select
        year(record_date) as year,
        count(*) as estimated_external_download_count,
        count(distinct user_id) as estimated_external_user_count
    from
        external_downloads
    group by
        year

)
-- 6. put everything in a final table
select
    coalesce(tc.year, ec.year) as year,
    tc.total_download_count,
    ec.estimated_external_download_count,
    tc.total_user_count,
    ec.estimated_external_user_count
from
    total_count tc
full outer join
    estimated_external_count ec
on
    tc.year = ec.year
order by
    year desc;  """

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
                st.markdown("### Total vs. External Downloads (Per Year)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_1",
                help="Refresh total_vs._external_downloads_(per_year) data",
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
                    df.groupby(by="YEAR", sort=False)
                    .agg(
                        col1=("TOTAL_DOWNLOAD_COUNT", "sum"),
                        col2=("ESTIMATED_EXTERNAL_DOWNLOAD_COUNT", "sum"),
                    )
                    .rename(
                        columns={
                            "col1": "TOTAL_DOWNLOAD_COUNT (sum)",
                            "col2": "ESTIMATED_EXTERNAL_DOWNLOAD_COUNT (sum)",
                        }
                    )
                    .reset_index()
                )

                st.line_chart(
                    df.set_index("YEAR"),
                    width="stretch",
                    height=400,
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_3_2() -> str:
    sql_query = r"""
-- 1. recursively grab all the subfolders and files that live within these MODEL-AD folders
with recursive all_nodes as (

    -- base of tree: start with the base query, which grabs all the MODEL-AD folders retrieved from the portal table result provided by Karina
    select
        id,
        file_handle_id,
        parent_id,
        name as study
    from
        synapse_data_warehouse.synapse.node_latest
    where
        id in (9850001, 15811463, 16798076, 17095980, 18634479, 21784897, 21595258, 21595255, 18693211, 20730014, 21983020, 22964685, 22313528, 22341543, 25316706, 21863375, 26943950, 50670633, 50944316, 27207345, 51713891, 58863147, 51534997, 27210656, 66318332, 66318364, 68527429, 26943727, 61250684, 65941765, 22341542, 61849889)

    union all

    -- recursively retrieve all subfolders and files within the base folders above ^
    select
        node_latest.id,
        node_latest.file_handle_id,
        node_latest.parent_id,
        all_nodes.study
    from
        synapse_data_warehouse.synapse.node_latest
    -- the CTE itself needs to be directly referred in FROM clause, so let's join the original results with the recursion results
    -- by matching up the parent_id (original results) to the newly found ids
    join
        all_nodes
    on
        node_latest.parent_id = all_nodes.id
),
-- 2. match up all_nodes.id with objectdownload_event.associaton_object_id to get ALL download records
-- but we don't want to count repeat downloads by the same user on the same day, so select distinct
all_downloads_except_repeats as (

    select
        user_id,
        association_object_id,
        record_date,
        all_nodes.file_handle_id,
        all_nodes.study
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    join
        all_nodes
    on
        objectdownload_event.association_object_id = all_nodes.id

),
-- 3. now let's get just the EXTERNAL downloads by filtering users whose e-mails are sagebase e-mails. this is not the most thorough
-- approach (exhibit A: Tom has like 8 different synapse accounts), but it's enough for an estimate. let's just make that clear in the final table
external_downloads as (

    select
        user_id,
        association_object_id,
        record_date,
        file_handle_id,
        study
    from
        all_downloads_except_repeats
    join
        synapse_data_warehouse.synapse.userprofile_latest
    on
        all_downloads_except_repeats.user_id = userprofile_latest.id
    where
        userprofile_latest.email not like '%@sagebase.org'
    and
        userprofile_latest.email not like '%@sagebionetworks.org'
),
-- 4. compute the total downloads and data egress
total_count as (

    select
        study,
        year(all_downloads_except_repeats.record_date) as year,
        count(*) as total_download_count,
        count(distinct all_downloads_except_repeats.user_id) as total_user_count,
        sum(file_latest.content_size) / power(2, 30) as total_data_egress
    from
        all_downloads_except_repeats
    join
        synapse_data_warehouse.synapse.file_latest
    on
        all_downloads_except_repeats.file_handle_id = file_latest.id
    group by
        study, year
),
-- 5. compute the estimated external downloads and data egress
estimated_external_count as (

    select
        study,
        year(external_downloads.record_date) as year,
        count(*) as estimated_external_download_count,
        count(distinct external_downloads.user_id) as estimated_external_user_count,
        sum(file_latest.content_size) / power(2, 30) as estimated_external_data_egress
    from
        external_downloads
    join
        synapse_data_warehouse.synapse.file_latest
    on
        external_downloads.file_handle_id = file_latest.id
    group by
        study, year

)
-- 6. put everything in a final table
select
    coalesce(tc.year, ec.year) as year,
  sum(tc.total_download_count) as total_download_count,
  sum(ec.estimated_external_download_count) as estimated_external_download_count,
  sum(tc.total_user_count) as total_user_count,
  sum(ec.estimated_external_user_count) as estimated_external_user_count,
  sum(tc.total_data_egress) as total_data_egress,
  sum(ec.estimated_external_data_egress) as estimated_external_data_egress
from
    total_count tc
full outer join
    estimated_external_count ec
on
    tc.study = ec.study and tc.year = ec.year
group by
  coalesce(tc.year, ec.year)
order by
  coalesce(tc.year, ec.year) desc;  """

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
                st.markdown(
                    "### Total vs. External Data Egress vs. Downloads (Per Year)"
                )
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_2",
                help="Refresh total_vs._external_data_egress_vs._downloads_(per_year) data",
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
                    df.groupby(by="YEAR", sort=False)
                    .agg(
                        col1=("TOTAL_DOWNLOAD_COUNT", "sum"),
                        col2=("ESTIMATED_EXTERNAL_DOWNLOAD_COUNT", "sum"),
                        col3=("TOTAL_DATA_EGRESS", "sum"),
                        col4=("ESTIMATED_EXTERNAL_DATA_EGRESS", "sum"),
                    )
                    .rename(
                        columns={
                            "col1": "TOTAL_DOWNLOAD_COUNT (sum)",
                            "col2": "ESTIMATED_EXTERNAL_DOWNLOAD_COUNT (sum)",
                            "col3": "TOTAL_DATA_EGRESS (sum)",
                            "col4": "ESTIMATED_EXTERNAL_DATA_EGRESS (sum)",
                        }
                    )
                    .reset_index()
                )

                st.line_chart(
                    df.set_index("YEAR"),
                    width="stretch",
                    height=400,
                    x_label="YEAR",
                    y_label="DL COUNT (#) / DATA EGRESS (GiB)",
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
    sql_query = r"""
-- 1. recursively grab all the subfolders and files that live within these MODEL-AD folders
with recursive all_nodes as (

    -- base of tree: start with the base query, which grabs all the MODEL-AD folders retrieved from the portal table result provided by Karina
    select
        id,
        file_handle_id,
        parent_id,
        name as study
    from
        synapse_data_warehouse.synapse.node_latest
    where
        id in (9850001, 15811463, 16798076, 17095980, 18634479, 21784897, 21595258, 21595255, 18693211, 20730014, 21983020, 22964685, 22313528, 22341543, 25316706, 21863375, 26943950, 50670633, 50944316, 27207345, 51713891, 58863147, 51534997, 27210656, 66318332, 66318364, 68527429, 26943727, 61250684, 65941765, 22341542, 61849889)

    union all

    -- recursively retrieve all subfolders and files within the base folders above ^
    select
        node_latest.id,
        node_latest.file_handle_id,
        node_latest.parent_id,
        all_nodes.study
    from
        synapse_data_warehouse.synapse.node_latest
    -- the CTE itself needs to be directly referred in FROM clause, so let's join the original results with the recursion results
    -- by matching up the parent_id (original results) to the newly found ids
    join
        all_nodes
    on
        node_latest.parent_id = all_nodes.id
),
-- 2. match up all_nodes.id with objectdownload_event.associaton_object_id to get ALL download records
-- but we don't want to count repeat downloads by the same user on the same day, so select distinct
all_downloads_except_repeats as (

    select
        user_id,
        association_object_id,
        record_date,
        all_nodes.file_handle_id,
        all_nodes.study
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    join
        all_nodes
    on
        objectdownload_event.association_object_id = all_nodes.id

),
-- 3. now let's get just the EXTERNAL downloads by filtering users whose e-mails are sagebase e-mails. this is not the most thorough
-- approach (exhibit A: Tom has like 8 different synapse accounts), but it's enough for an estimate. let's just make that clear in the final table
external_downloads as (

    select
        user_id,
        association_object_id,
        record_date,
        file_handle_id,
        study
    from
        all_downloads_except_repeats
    join
        synapse_data_warehouse.synapse.userprofile_latest
    on
        all_downloads_except_repeats.user_id = userprofile_latest.id
    where
        userprofile_latest.email not like '%@sagebase.org'
    and
        userprofile_latest.email not like '%@sagebionetworks.org'
),
-- 4. compute the total downloads and data egress
total_count as (

    select
        study,
        year(all_downloads_except_repeats.record_date) as year,
        count(*) as total_download_count,
        count(distinct all_downloads_except_repeats.user_id) as total_user_count,
        sum(file_latest.content_size) / power(2, 30) as total_data_egress
    from
        all_downloads_except_repeats
    join
        synapse_data_warehouse.synapse.file_latest
    on
        all_downloads_except_repeats.file_handle_id = file_latest.id
    group by
        study, year
),
-- 5. compute the estimated external downloads and data egress
estimated_external_count as (

    select
        study,
        year(external_downloads.record_date) as year,
        count(*) as estimated_external_download_count,
        count(distinct external_downloads.user_id) as estimated_external_user_count,
        sum(file_latest.content_size) / power(2, 30) as estimated_external_data_egress
    from
        external_downloads
    join
        synapse_data_warehouse.synapse.file_latest
    on
        external_downloads.file_handle_id = file_latest.id
    group by
        study, year

)
-- 6. put everything in a final table
select
    coalesce(tc.study, ec.study) as study,
    coalesce(tc.year, ec.year) as year,
    tc.total_download_count,
    ec.estimated_external_download_count,
    tc.total_user_count,
    ec.estimated_external_user_count,
    tc.total_data_egress,
    ec.estimated_external_data_egress
from
    total_count tc
full outer join
    estimated_external_count ec
on
    tc.study = ec.study and tc.year = ec.year
order by
    year desc, total_download_count desc;  """

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
                    "### Downloads, Unique Users, and Data Egress (Per Study Per Year)"
                )
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_1",
                help="Refresh downloads,_unique_users,_and_data_egress_(per_study_per_year) data",
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
-- 1. recursively grab all the subfolders and files that live within these MODEL-AD folders
with recursive all_nodes as (

    -- base of tree: start with the base query, which grabs all the MODEL-AD folders retrieved from the portal table result provided by Karina
    select
        id,
        file_handle_id,
        parent_id,
        name as study
    from
        synapse_data_warehouse.synapse.node_latest
    where
        id in (9850001, 15811463, 16798076, 17095980, 18634479, 21784897, 21595258, 21595255, 18693211, 20730014, 21983020, 22964685, 22313528, 22341543, 25316706, 21863375, 26943950, 50670633, 50944316, 27207345, 51713891, 58863147, 51534997, 27210656, 66318332, 66318364, 68527429, 26943727, 61250684, 65941765, 22341542, 61849889)

    union all

    -- recursively retrieve all subfolders and files within the base folders above ^
    select
        node_latest.id,
        node_latest.file_handle_id,
        node_latest.parent_id,
        all_nodes.study
    from
        synapse_data_warehouse.synapse.node_latest
    -- the CTE itself needs to be directly referred in FROM clause, so let's join the original results with the recursion results
    -- by matching up the parent_id (original results) to the newly found ids
    join
        all_nodes
    on
        node_latest.parent_id = all_nodes.id
),
-- 2. match up all_nodes.id with objectdownload_event.associaton_object_id to get ALL download records
-- but we don't want to count repeat downloads by the same user on the same day, so select distinct
all_downloads_except_repeats as (

    select
        user_id,
        association_object_id,
        record_date,
        all_nodes.study
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    join
        all_nodes
    on
        objectdownload_event.association_object_id = all_nodes.id

),
-- 3. now let's get just the EXTERNAL downloads by filtering users whose e-mails are sagebase e-mails. this is not the most thorough
-- approach (exhibit A: Tom has like 8 different synapse accounts), but it's enough for an estimate. let's just make that clear in the final table
external_downloads as (

    select
        user_id,
        association_object_id,
        record_date,
        study
    from
        all_downloads_except_repeats
    join
        synapse_data_warehouse.synapse.userprofile_latest
    on
        all_downloads_except_repeats.user_id = userprofile_latest.id
    where
        userprofile_latest.email not like '%@sagebase.org'
    and
        userprofile_latest.email not like '%@sagebionetworks.org'
),
-- 4. compute the total downloads
total_count as (

    select
        study,
        year(record_date) as year,
        count(*) as total_download_count,
        count(distinct user_id) as total_user_count
    from
        all_downloads_except_repeats
    group by
        study, year
),
-- 5. compute the estimated external downloads
estimated_external_count as (

    select
        study,
        year(record_date) as year,
        count(*) as estimated_external_download_count,
        count(distinct user_id) as estimated_external_user_count
    from
        external_downloads
    group by
        study, year

)
-- 6. put everything in a final table
select
    coalesce(tc.study, ec.study) as study,
    coalesce(tc.year, ec.year) as year,
    tc.total_download_count,
    ec.estimated_external_download_count,
    tc.total_user_count,
    ec.estimated_external_user_count
from
    total_count tc
full outer join
    estimated_external_count ec
on
    tc.study = ec.study and tc.year = ec.year
order by
    year desc, total_download_count;  """

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
                st.markdown(
                    "### (Estimated) External Download Count (Per Study Per Year)"
                )
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_1",
                help="Refresh (estimated)_external_download_count_(per_study_per_year) data",
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

            # Display heatmap chart
            if len(df) > 0:
                df = (
                    df.groupby(by=["STUDY", "YEAR"], sort=False)
                    .agg(col1=("ESTIMATED_EXTERNAL_DOWNLOAD_COUNT", "sum"))
                    .rename(columns={"col1": "ESTIMATED_EXTERNAL_DOWNLOAD_COUNT (sum)"})
                    .reset_index()
                )

                value_col = "ESTIMATED_EXTERNAL_DOWNLOAD_COUNT (sum)"
                median_value = df[value_col].median()

                base = alt.Chart(df).encode(
                    x=alt.X(field="YEAR", type="nominal", title="YEAR"),
                    y=alt.Y(field="STUDY", type="nominal", title="STUDY"),
                )
                heatmap = base.mark_rect().encode(
                    color=alt.Color(
                        field=value_col,
                        type="quantitative",
                        scale=alt.Scale(scheme="blues"),
                        title="ESTIMATED_EXTERNAL_DOWNLOAD_COUNT (sum)",
                    )
                )
                text = base.mark_text(baseline="middle").encode(
                    text=alt.Text(field=value_col, type="quantitative", format=".1f"),
                    color=alt.condition(
                        f'datum["{value_col}"] > {median_value}',
                        alt.value("white"),
                        alt.value("black"),
                    ),
                )
                chart = (heatmap + text).properties(height=400)
                st.altair_chart(chart, width="stretch")
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_5_2() -> str:
    sql_query = r"""
-- 1. recursively grab all the subfolders and files that live within these MODEL-AD folders
with recursive all_nodes as (

    -- base of tree: start with the base query, which grabs all the MODEL-AD folders retrieved from the portal table result provided by Karina
    select
        id,
        file_handle_id,
        parent_id,
        name as study
    from
        synapse_data_warehouse.synapse.node_latest
    where
        id in (9850001, 15811463, 16798076, 17095980, 18634479, 21784897, 21595258, 21595255, 18693211, 20730014, 21983020, 22964685, 22313528, 22341543, 25316706, 21863375, 26943950, 50670633, 50944316, 27207345, 51713891, 58863147, 51534997, 27210656, 66318332, 66318364, 68527429, 26943727, 61250684, 65941765, 22341542, 61849889)

    union all

    -- recursively retrieve all subfolders and files within the base folders above ^
    select
        node_latest.id,
        node_latest.file_handle_id,
        node_latest.parent_id,
        all_nodes.study
    from
        synapse_data_warehouse.synapse.node_latest
    -- the CTE itself needs to be directly referred in FROM clause, so let's join the original results with the recursion results
    -- by matching up the parent_id (original results) to the newly found ids
    join
        all_nodes
    on
        node_latest.parent_id = all_nodes.id
),
-- 2. match up all_nodes.id with objectdownload_event.associaton_object_id to get ALL download records
-- but we don't want to count repeat downloads by the same user on the same day, so select distinct
all_downloads_except_repeats as (

    select
        user_id,
        association_object_id,
        record_date,
        all_nodes.study
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    join
        all_nodes
    on
        objectdownload_event.association_object_id = all_nodes.id

),
-- 3. now let's get just the EXTERNAL downloads by filtering users whose e-mails are sagebase e-mails. this is not the most thorough
-- approach (exhibit A: Tom has like 8 different synapse accounts), but it's enough for an estimate. let's just make that clear in the final table
external_downloads as (

    select
        user_id,
        association_object_id,
        record_date,
        study
    from
        all_downloads_except_repeats
    join
        synapse_data_warehouse.synapse.userprofile_latest
    on
        all_downloads_except_repeats.user_id = userprofile_latest.id
    where
        userprofile_latest.email not like '%@sagebase.org'
    and
        userprofile_latest.email not like '%@sagebionetworks.org'
),
-- 4. compute the total downloads
total_count as (

    select
        study,
        year(record_date) as year,
        count(*) as total_download_count,
        count(distinct user_id) as total_user_count
    from
        all_downloads_except_repeats
    group by
        study, year
),
-- 5. compute the estimated external downloads
estimated_external_count as (

    select
        study,
        year(record_date) as year,
        count(*) as estimated_external_download_count,
        count(distinct user_id) as estimated_external_user_count
    from
        external_downloads
    group by
        study, year

)
-- 6. put everything in a final table
select
    coalesce(tc.study, ec.study) as study,
    coalesce(tc.year, ec.year) as year,
    tc.total_download_count,
    ec.estimated_external_download_count,
    tc.total_user_count,
    ec.estimated_external_user_count
from
    total_count tc
full outer join
    estimated_external_count ec
on
    tc.study = ec.study and tc.year = ec.year
order by
    year desc;  """

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
                st.markdown("### (Estimated) External User Count (Per Study Per Year)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_2",
                help="Refresh (estimated)_external_user_count_(per_study_per_year) data",
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

            # Display heatmap chart
            if len(df) > 0:
                df = (
                    df.groupby(by=["STUDY", "YEAR"], sort=False)
                    .agg(col1=("ESTIMATED_EXTERNAL_USER_COUNT", "sum"))
                    .rename(columns={"col1": "ESTIMATED_EXTERNAL_USER_COUNT (sum)"})
                    .reset_index()
                )

                value_col = "ESTIMATED_EXTERNAL_USER_COUNT (sum)"
                median_value = df[value_col].median()

                base = alt.Chart(df).encode(
                    x=alt.X(field="YEAR", type="nominal", title="YEAR"),
                    y=alt.Y(field="STUDY", type="nominal", title="STUDY"),
                )
                heatmap = base.mark_rect().encode(
                    color=alt.Color(
                        field=value_col,
                        type="quantitative",
                        scale=alt.Scale(scheme="blues"),
                        title="TOTAL USER COUNT",
                    )
                )
                text = base.mark_text(baseline="middle").encode(
                    text=alt.Text(field=value_col, type="quantitative", format=".1f"),
                    color=alt.condition(
                        f'datum["{value_col}"] > {median_value}',
                        alt.value("white"),
                        alt.value("black"),
                    ),
                )
                chart = (heatmap + text).properties(height=400)
                st.altair_chart(chart, width="stretch")
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
    # Transform :daterange parameter - convert to range comparison
    if isinstance(input_daterange, tuple) and len(input_daterange) == 2:
        start_date, end_date = input_daterange
        expr_daterange = (
            f"objectdownload_event.record_date BETWEEN '{start_date}' AND '{end_date}'"
        )
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange = f"objectdownload_event.record_date >= '{start_date}'"
    else:
        expr_daterange = "TRUE"

    sql_query = rf"""
-- The Synapse IDs in this query come from
-- The ADTR portal backend table with Synapse folder dataset ids listed when filtered for Program = MODEL-AD.
-- TODO: there can probably be an improvement to automatically query for folders with "program = model-AD"
-- But that may not be accurate

WITH RECURSIVE all_nodes
    -- Column list of the "view"
    (
        ID,
        PARENT_ID,
        -- NAME,
        -- NODE_TYPE,
        -- FILE_HANDLE_ID,
        ENTITY_ID
    ) 
    AS 
    -- Common Table Expression
    (
        -- Anchor Clause
        SELECT
            ID,
            PARENT_ID,
            -- NAME,
            -- NODE_TYPE,
            -- FILE_HANDLE_ID,
            ID AS ENTITY_ID
        FROM
            synapse_data_warehouse.synapse.node_latest
        WHERE
            ID IN (
                9850001, 15811463, 16798076, 17095980, 18634479, 21784897, 21595258, 21595255, 18693211, 20730014, 21983020, 22964685, 22313528, 22341543, 25316706, 21863375, 26943950, 50670633, 50944316, 27207345, 51713891, 58863147, 51534997, 27210656, 66318332, 66318364, 68527429, 26943727, 61250684, 65941765, 22341542, 61849889
            )
            
        UNION ALL
        
        -- Recursive Clause
        SELECT
            node.ID,
            node.PARENT_ID,
            -- node.NAME,
            -- node.NODE_TYPE,
            -- node.FILE_HANDLE_ID,
            all_nodes.ENTITY_ID
        FROM
            synapse_data_warehouse.synapse.node_latest AS node
        JOIN 
            all_nodes 
        ON 
            node.PARENT_ID = all_nodes.ID
), dedup_downloads as (
    select
        all_nodes.entity_id, objectdownload_event.user_id, objectdownload_event.file_handle_id, objectdownload_event.record_date
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    join
        all_nodes
        on objectdownload_event.association_object_id = all_nodes.id
    where
        {expr_daterange}
)
-- This is the "main select".
SELECT
    dedup_downloads.ENTITY_ID AS STUDY_ID,
    node_latest.name as study_name,
    count(distinct user_id) as number_of_unique_downloaders,
    count(*) as number_of_downloads
FROM
    dedup_downloads
join
    synapse_data_warehouse.synapse.node_latest
    on dedup_downloads.entity_id = node_latest.id
GROUP BY
    dedup_downloads.ENTITY_ID,
    node_latest.name
ORDER BY
    number_of_unique_downloaders desc;  """

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
                st.markdown("### Download metrics per filter range")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_1",
                help="Refresh download_metrics_per_filter_range data",
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
