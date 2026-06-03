import argparse
import datetime as dt
import pandas as pd
import streamlit as st
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
st.set_page_config(page_title="NF Usage Metrics", layout="wide")

# Title
st.title("NF Usage Metrics")
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

-- get latest projects https://www.synapse.org/#!Synapse:syn51489960/tables/query/eyJzcWwiOiJTRUxFQ1QgZGlzdGluY3QocHJvamVjdElkKSBGUk9NIHN5bjUxNDg5OTYwIiwgImluY2x1ZGVFbnRpdHlFdGFnIjp0cnVlLCAibGltaXQiOjI1fQ==
with nf_projects as (
    -- select distinct cast(replace(NF.projectid, 'syn', '') as INTEGER) as project_id from sage.portal_raw.NF
    select
        cast(scopes.value as integer) as project_id
    from
        synapse_data_warehouse.synapse.node_latest,
        lateral flatten(input => node_latest.scope_ids) scopes
    where
        id = 16858331
)
select
    min(record_date) as min_dl_date,
    max(record_date) as max_dl_date
from
  synapse_data_warehouse.synapse_event.objectdownload_event
inner join
    nf_projects
  on objectdownload_event.project_id = nf_projects.project_id

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
    sql_query = r"""

with nf_projects as (
  -- select distinct cast(replace(NF.projectid, 'syn', '') as INTEGER) as project_id from sage.portal_raw.NF
    select
        cast(scopes.value as integer) as project_id
    from
        synapse_data_warehouse.synapse.node_latest,
        lateral flatten(input => node_latest.scope_ids) scopes
    where id = 16858331
)    
select
    count(*) as number_of_files,
    sum(file_latest.content_size) / power(2, 40) AS TOTAL_SIZE_IN_TiB,
    sum(file_latest.content_size) / power(2, 30) * 0.023 * 12 AS annual_price_estimate
from
    synapse_data_warehouse.synapse.node_latest
inner join
    nf_projects
    on node_latest.project_id = nf_projects.project_id
inner join
    synapse_data_warehouse.synapse.file_latest
    on node_latest.file_handle_id = file_latest.id;

  """

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
                st.markdown("### Storage summary")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_2",
                help="Refresh storage_summary data",
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

with nf_projects as (
  -- select distinct cast(replace(NF.projectid, 'syn', '') as INTEGER) as project_id from sage.portal_raw.NF
    select
        cast(scopes.value as integer) as project_id
    from
        synapse_data_warehouse.synapse.node_latest,
        lateral flatten(input => node_latest.scope_ids) scopes
    where id = 16858331
)    
select
    node_latest.annotations:annotations:dataType:value[0] as datatype,
    count(*) as number_of_files,
    sum(file_latest.content_size) / power(2, 30) as size_in_gib
from
    synapse_data_warehouse.synapse.node_latest
inner join
    nf_projects
    on node_latest.project_id = nf_projects.project_id
inner join
    synapse_data_warehouse.synapse.file_latest
    on node_latest.file_handle_id = file_latest.id
group by
    datatype
  """

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
                st.markdown("### Datatype storage summary")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_3",
                help="Refresh datatype_storage_summary data",
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

with nf_projects as (
    select
        cast(scopes.value as integer) as project_id
    from
        synapse_data_warehouse.synapse.node_latest,
        lateral flatten(input => node_latest.scope_ids) scopes
    where id = 16858331
)    
select
    count(distinct record_date, user_id, file_handle_id) as number_of_downloads,
    count(distinct user_id) as number_of_unique_users_downloaded
from
  synapse_data_warehouse.synapse_event.objectdownload_event
inner join
    nf_projects
  on objectdownload_event.project_id = nf_projects.project_id;  """

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

with nf_projects as (
    select
        cast(scopes.value as integer) as project_id
    from
        synapse_data_warehouse.synapse.node_latest,
        lateral flatten(input => node_latest.scope_ids) scopes
    where
        id = 16858331
), nonsage_users AS (
    SELECT
        ID
    FROM
        SYNAPSE_DATA_WAREHOUSE.SYNAPSE.USERPROFILE_LATEST
    WHERE
        EMAIL NOT LIKE '%@sagebase.org'
), dedup_downloads as (
    select
        distinct record_date, user_id, file_handle_id
    from
      synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        nonsage_users
    on
      objectdownload_event.user_id = nonsage_users.id
    inner join
        nf_projects
      on objectdownload_event.project_id = nf_projects.project_id
)
select
    count(RECORD_DATE) as number_of_downloads,
    count(DISTINCT USER_ID) as number_of_unique_users_downloaded
from
    dedup_downloads;  """

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
                st.markdown("### All time non-sage downloads")
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


def query_2_3() -> str:
    sql_query = r"""
WITH nf_projects AS (
    SELECT
        CAST(scopes.value AS INTEGER) AS project_id
    FROM
        synapse_data_warehouse.synapse.node_latest nl,
        LATERAL FLATTEN(input => nl.scope_ids) scopes
    WHERE
        nl.id = 16858331
), nonsage_users AS (
    SELECT
        ID
    FROM
        SYNAPSE_DATA_WAREHOUSE.SYNAPSE.USERPROFILE_LATEST
    WHERE
        EMAIL NOT LIKE '%@sagebase.org'
), dedup_downloads AS (
    SELECT
        DISTINCT fd.record_date,
        fd.user_id,
        fd.file_handle_id
    FROM
      synapse_data_warehouse.synapse_event.objectdownload_event AS fd
        INNER JOIN nonsage_users nu
            ON fd.user_id = nu.id
        INNER JOIN nf_projects np
            ON fd.project_id = np.project_id
    WHERE
        fd.record_date BETWEEN DATEADD(year, -1, CURRENT_DATE) AND CURRENT_DATE
)
SELECT
    COUNT(record_date) AS number_of_downloads,
    COUNT(DISTINCT user_id) AS number_of_unique_users_downloaded
FROM
    dedup_downloads;
  """

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
                st.markdown("### Downloads last 12 months")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_3",
                help="Refresh downloads_last_12_months data",
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
WITH nf_projects AS (
    SELECT
        CAST(scopes.value AS INTEGER) AS project_id
    FROM
        synapse_data_warehouse.synapse.node_latest,
        LATERAL FLATTEN(input => node_latest.scope_ids) scopes
    WHERE
        id = 16858331
), node_annotations AS (
    SELECT
        file_handle_id,
        annotations:annotations:fundingAgency:value[0] AS fundingAgency
    FROM
        synapse_data_warehouse.synapse.node_latest
    INNER JOIN
        nf_projects ON node_latest.project_id = nf_projects.project_id
), dedup_downloads AS (
    SELECT
    DISTINCT objectdownload_event.record_date,
    objectdownload_event.user_id,
    objectdownload_event.file_handle_id,
        node_annotations.fundingAgency
    FROM
      synapse_data_warehouse.synapse_event.objectdownload_event
    INNER JOIN
      node_annotations ON objectdownload_event.file_handle_id = node_annotations.file_handle_id
    INNER JOIN
      nf_projects ON objectdownload_event.project_id = nf_projects.project_id
    WHERE
      objectdownload_event.user_id NOT IN (
            3421893, 3389310, 3342573, 3434950, 3459953, 
            3514384, 3510065, 3324230, 3460442, 3458117, 
            3434599, 3440247, 3342492, 3481671, 3489628
        ) -- Exclude specific user IDs
)
SELECT
    DATE_TRUNC('MONTH', record_date) AS month_of_download,
    COUNT(record_date) AS number_of_downloads,
    COUNT(DISTINCT user_id) AS number_of_unique_users
FROM
    dedup_downloads
WHERE
    fundingAgency LIKE '%NTAP%'  -- Filter for NTAP in fundingAgency
GROUP BY
  month_of_download
ORDER BY
  month_of_download DESC;
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
                st.markdown("### Downloads Per Month - NTAP")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_1",
                help="Refresh downloads_per_month_-_ntap data",
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
WITH nf_projects AS (
    SELECT
        CAST(scopes.value AS INTEGER) AS project_id
    FROM
        synapse_data_warehouse.synapse.node_latest,
        LATERAL FLATTEN(input => node_latest.scope_ids) scopes
    WHERE
        id = 16858331
), node_annotations AS (
    SELECT
        file_handle_id,
        annotations:annotations:fundingAgency:value[0] AS fundingAgency
    FROM
        synapse_data_warehouse.synapse.node_latest
    INNER JOIN
        nf_projects ON node_latest.project_id = nf_projects.project_id
), dedup_downloads AS (
    SELECT
    DISTINCT objectdownload_event.record_date,
    objectdownload_event.user_id,
    objectdownload_event.file_handle_id,
        node_annotations.fundingAgency
    FROM
      synapse_data_warehouse.synapse_event.objectdownload_event
    INNER JOIN
      node_annotations ON objectdownload_event.file_handle_id = node_annotations.file_handle_id
    INNER JOIN
      nf_projects ON objectdownload_event.project_id = nf_projects.project_id
    WHERE
      objectdownload_event.user_id NOT IN (
            3421893, 3389310, 3342573, 3434950, 3459953, 
            3514384, 3510065, 3324230, 3460442, 3458117, 
            3434599, 3440247, 3342492, 3481671, 3489628
        ) -- Exclude specific user IDs
)
SELECT
    DATE_TRUNC('MONTH', record_date) AS month_of_download,
    COUNT(record_date) AS number_of_downloads,
    COUNT(DISTINCT user_id) AS number_of_unique_users
FROM
    dedup_downloads
WHERE
    fundingAgency LIKE '%NTAP%'  -- Filter for NTAP in fundingAgency
GROUP BY
  month_of_download
ORDER BY
  month_of_download DESC;
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
                st.markdown("### Downloads Per Month - NTAP")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_2",
                help="Refresh downloads_per_month_-_ntap data",
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
                df["MONTH_OF_DOWNLOAD"] = (
                    pd.to_datetime(df["MONTH_OF_DOWNLOAD"])
                    .dt.to_period("M")
                    .dt.start_time
                )

                df = (
                    df.groupby(by="MONTH_OF_DOWNLOAD", sort=False)
                    .agg(col1=("NUMBER_OF_DOWNLOADS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_DOWNLOADS (sum)"})
                    .reset_index()
                )

                st.line_chart(
                    df.set_index("MONTH_OF_DOWNLOAD"),
                    width="stretch",
                    height=400,
                    y_label="Number of Downloads",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_3_3() -> str:
    sql_query = r"""
WITH nf_projects AS (
    SELECT
        CAST(scopes.value AS INTEGER) AS project_id
    FROM
        synapse_data_warehouse.synapse.node_latest,
        LATERAL FLATTEN(input => node_latest.scope_ids) scopes
    WHERE
        id = 16858331
), node_annotations AS (
    SELECT
        file_handle_id,
        annotations:annotations:fundingAgency:value[0] AS fundingAgency,
        nf_projects.project_id AS project_id  -- Ensure project_id is included here if needed
    FROM
        synapse_data_warehouse.synapse.node_latest
    INNER JOIN
        nf_projects ON node_latest.project_id = nf_projects.project_id
), dedup_downloads AS (
    SELECT
    DISTINCT objectdownload_event.record_date,
    objectdownload_event.user_id,
    objectdownload_event.file_handle_id,
        node_annotations.fundingAgency,
        node_annotations.project_id  -- Include project_id in the selection
    FROM
      synapse_data_warehouse.synapse_event.objectdownload_event
    INNER JOIN
      node_annotations ON objectdownload_event.file_handle_id = node_annotations.file_handle_id
)
SELECT
    DATE_TRUNC('YEAR', record_date) AS year_of_download,
  COUNT(*) AS number_of_downloads,
  COUNT(DISTINCT user_id) AS number_of_unique_users,
  COUNT(DISTINCT project_id) AS number_of_unique_projects  -- Corrected field name
FROM
    dedup_downloads
WHERE
    fundingAgency LIKE '%CTF%'  -- Filter for CTF in fundingAgency
GROUP BY
  year_of_download
ORDER BY
  year_of_download DESC;
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
                st.markdown("### Downloads Per Month - CTF")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_3",
                help="Refresh downloads_per_month_-_ctf data",
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

            # Prepare data for line chart with aggregation
            if len(df) > 0:
                df = (
                    df.groupby(by="YEAR_OF_DOWNLOAD", sort=False)
                    .agg(col1=("NUMBER_OF_DOWNLOADS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_DOWNLOADS (sum)"})
                    .reset_index()
                )

                st.line_chart(
                    df.set_index("YEAR_OF_DOWNLOAD"),
                    width="stretch",
                    height=400,
                    y_label="Number of Downloads",
                )
            else:
                st.warning("No data available")
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
with nf_projects as (
    select
        cast(scopes.value as integer) as project_id
    from
        synapse_data_warehouse.synapse.node_latest,
        lateral flatten(input => node_latest.scope_ids) scopes
    where
        id = 16858331
), node_annotations as (
    select
        file_handle_id,
        annotations:annotations:fundingAgency:value[0] as fundingAgency
    from
        synapse_data_warehouse.synapse.node_latest
    inner join
        nf_projects
        on node_latest.project_id = nf_projects.project_id
), dedup_downloads as (
    select
    distinct objectdownload_event.user_id, objectdownload_event.record_date, objectdownload_event.file_handle_id, node_annotations.fundingAgency
    from
      synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
    on
      objectdownload_event.file_handle_id = node_annotations.file_handle_id
)
SELECT
    fundingAgency,
    YEAR(record_date) as year_of_download,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) as number_of_unique_users
FROM
    dedup_downloads
GROUP BY
    year_of_download, fundingAgency
ORDER BY
    year_of_download DESC, fundingAgency DESC NULLS LAST;
    

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
                st.markdown("### Annual downloads per funding agency")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_1",
                help="Refresh annual_downloads_per_funding_agency data",
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
with nf_projects as (
    select
        cast(scopes.value as integer) as project_id
    from
        synapse_data_warehouse.synapse.node_latest,
        lateral flatten(input => node_latest.scope_ids) scopes
    where
        id = 16858331
), node_annotations as (
    select
        file_handle_id,
        annotations:annotations:fundingAgency:value[0] as fundingAgency
    from
        synapse_data_warehouse.synapse.node_latest
    inner join
        nf_projects
        on node_latest.project_id = nf_projects.project_id
), dedup_downloads as (
    select
    distinct objectdownload_event.user_id, objectdownload_event.record_date, objectdownload_event.file_handle_id, node_annotations.fundingAgency
    from
      synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
    on
      objectdownload_event.file_handle_id = node_annotations.file_handle_id
)
SELECT
    fundingAgency,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) as number_of_unique_users
FROM
    dedup_downloads
GROUP BY
    fundingAgency
ORDER BY
  NUMBER_OF_DOWNLOADS DESC
  NULLS LAST;
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
                st.markdown("### Number of downloads per funding agency")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_1",
                help="Refresh number_of_downloads_per_funding_agency data",
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
with nf_projects as (
    select
        cast(scopes.value as integer) as project_id
    from
        synapse_data_warehouse.synapse.node_latest,
        lateral flatten(input => node_latest.scope_ids) scopes
    where
        id = 16858331
), node_annotations as (
    select
        file_handle_id,
        annotations:annotations:fundingAgency:value[0] as fundingAgency
    from
        synapse_data_warehouse.synapse.node_latest
    inner join
        nf_projects
        on node_latest.project_id = nf_projects.project_id
), dedup_downloads as (
    select
    distinct objectdownload_event.user_id, objectdownload_event.record_date, objectdownload_event.file_handle_id, node_annotations.fundingAgency
    from
      synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
    on
      objectdownload_event.file_handle_id = node_annotations.file_handle_id
)
SELECT
    fundingAgency,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) as number_of_unique_users
FROM
    dedup_downloads
GROUP BY
    fundingAgency
ORDER BY
  NUMBER_OF_DOWNLOADS DESC
  NULLS LAST;
  """

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
                st.markdown("### Number of downloads per funding agency")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_2",
                help="Refresh number_of_downloads_per_funding_agency data",
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
                df = (
                    df.groupby(by="FUNDINGAGENCY", sort=False)
                    .agg(col1=("NUMBER_OF_DOWNLOADS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_DOWNLOADS (sum)"})
                    .reset_index()
                )

                df["/* Order Key (Generated by Snowflake) */"] = df["FUNDINGAGENCY"]

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["FUNDINGAGENCY"]):
                    datetime_primary_column = df["FUNDINGAGENCY"]
                elif df["FUNDINGAGENCY"].dtype == "object" and isinstance(
                    df["FUNDINGAGENCY"].get(df["FUNDINGAGENCY"].first_valid_index()),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["FUNDINGAGENCY"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["FUNDINGAGENCY"] = df["FUNDINGAGENCY"].astype("string")

                st.bar_chart(
                    df,
                    x="FUNDINGAGENCY",
                    y=[
                        c
                        for c in df.columns
                        if c != "FUNDINGAGENCY"
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
with nf_projects as (
    select
        cast(scopes.value as integer) as project_id
    from
        synapse_data_warehouse.synapse.node_latest,
        lateral flatten(input => node_latest.scope_ids) scopes
    where
        id = 16858331
), node_annotations as (
    select
        file_handle_id,
        annotations:annotations:assay:value[0] as assay,
        annotations:annotations:type:value[0] as filetype
    from
        synapse_data_warehouse.synapse.node_latest
    inner join
        nf_projects
        on node_latest.project_id = nf_projects.project_id
), dedup_downloads as (
    select
    distinct objectdownload_event.user_id, objectdownload_event.record_date, objectdownload_event.file_handle_id, node_annotations.assay
    from
      synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
    on
      objectdownload_event.file_handle_id = node_annotations.file_handle_id
)
SELECT
    assay,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) as number_of_unique_users
FROM
    dedup_downloads
GROUP BY
    assay
ORDER BY
    number_of_downloads DESC
    NULLS LAST;

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
                st.markdown("### Number of downloads per assay")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_1",
                help="Refresh number_of_downloads_per_assay data",
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
with nf_projects as (
    select
        cast(scopes.value as integer) as project_id
    from
        synapse_data_warehouse.synapse.node_latest,
        lateral flatten(input => node_latest.scope_ids) scopes
    where
        id = 16858331
), node_annotations as (
    select
        file_handle_id,
        annotations:annotations:assay:value[0] as assay,
        annotations:annotations:type:value[0] as filetype
    from
        synapse_data_warehouse.synapse.node_latest
    inner join
        nf_projects
        on node_latest.project_id = nf_projects.project_id
), dedup_downloads as (
    select
    distinct objectdownload_event.user_id, objectdownload_event.record_date, objectdownload_event.file_handle_id, node_annotations.assay
    from
      synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
    on
      objectdownload_event.file_handle_id = node_annotations.file_handle_id
)
SELECT
    assay,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) as number_of_unique_users
FROM
    dedup_downloads
GROUP BY
    assay
ORDER BY
    number_of_downloads DESC
    NULLS LAST;

  """

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
                st.markdown("### Number of downloads per assay")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_2",
                help="Refresh number_of_downloads_per_assay data",
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
                    df.groupby(by="ASSAY", sort=False)
                    .agg(col1=("NUMBER_OF_DOWNLOADS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_DOWNLOADS (sum)"})
                    .reset_index()
                )

                df["/* Order Key (Generated by Snowflake) */"] = df.drop(
                    columns="ASSAY"
                ).sum(axis=1)

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["ASSAY"]):
                    datetime_primary_column = df["ASSAY"]
                elif df["ASSAY"].dtype == "object" and isinstance(
                    df["ASSAY"].get(df["ASSAY"].first_valid_index()), dt.date
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["ASSAY"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["ASSAY"] = df["ASSAY"].astype("string")

                st.bar_chart(
                    df,
                    x="ASSAY",
                    y=[
                        c
                        for c in df.columns
                        if c != "ASSAY"
                        and c != "/* Order Key (Generated by Snowflake) */"
                    ],
                    sort="-/* Order Key (Generated by Snowflake) */",
                    width="stretch",
                    height=400,
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
with nf_projects as (
    select
        cast(scopes.value as integer) as project_id
    from
        synapse_data_warehouse.synapse.node_latest,
        lateral flatten(input => node_latest.scope_ids) scopes
    where
        id = 16858331
), node_annotations as (
    select
        file_handle_id,
        annotations:annotations:specimenID:value[0] as specimenID
    from
        synapse_data_warehouse.synapse.node_latest
    inner join
        nf_projects
        on node_latest.project_id = nf_projects.project_id
), dedup_downloads as (
    select
    distinct objectdownload_event.user_id, objectdownload_event.record_date, objectdownload_event.file_handle_id, node_annotations.specimenID
    from
    synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
    on
    objectdownload_event.file_handle_id = node_annotations.file_handle_id
)
SELECT
    specimenID,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) as number_of_unique_users
FROM
    dedup_downloads
GROUP BY
    specimenID
ORDER BY
    number_of_downloads DESC
    NULLS LAST;

  """

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
                st.markdown("### Number of downloads per specimen")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_7_1",
                help="Refresh number_of_downloads_per_specimen data",
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
with nf_projects as (
    select
        cast(scopes.value as integer) as project_id
    from
        synapse_data_warehouse.synapse.node_latest,
        lateral flatten(input => node_latest.scope_ids) scopes
    where
        id = 16858331
), node_annotations as (
    select
        file_handle_id,
        annotations:annotations:dataType:value[0] as dataType
    from
        synapse_data_warehouse.synapse.node_latest
    inner join
        nf_projects
        on node_latest.project_id = nf_projects.project_id
), dedup_downloads as (
    select
    distinct objectdownload_event.user_id, objectdownload_event.record_date, objectdownload_event.file_handle_id, node_annotations.dataType
    from
    synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
    on
    objectdownload_event.file_handle_id = node_annotations.file_handle_id
)
SELECT
    dataType,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) as number_of_unique_users
FROM
    dedup_downloads
GROUP BY
    dataType
ORDER BY
    number_of_downloads DESC
    NULLS LAST;

  """

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
                st.markdown("### Number of downloads per datatype")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_7_2",
                help="Refresh number_of_downloads_per_datatype data",
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
    # Transform :daterange parameter - convert to range comparison
    if isinstance(input_daterange, tuple) and len(input_daterange) == 2:
        start_date, end_date = input_daterange
        expr_daterange = (
            f"access_event.record_date BETWEEN '{start_date}' AND '{end_date}'"
        )
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange = f"access_event.record_date >= '{start_date}'"
    else:
        expr_daterange = "TRUE"

    sql_query = rf"""

-- get latest projects https://www.synapse.org/#!Synapse:syn51489960/tables/query/eyJzcWwiOiJTRUxFQ1QgZGlzdGluY3QocHJvamVjdElkKSBGUk9NIHN5bjUxNDg5OTYwIiwgImluY2x1ZGVFbnRpdHlFdGFnIjp0cnVlLCAibGltaXQiOjI1fQ==
with nf_projects as (
    -- select distinct cast(replace(NF.projectid, 'syn', '') as INTEGER) as project_id from sage.portal_raw.NF
    select
        cast(scopes.value as integer) as project_id
    from
        synapse_data_warehouse.synapse.node_latest,
        lateral flatten(input => node_latest.scope_ids) scopes
    where
        id = 16858331
), nodes as (
    select
        node_latest.id
    from
        synapse_data_warehouse.synapse.node_latest
    inner join
        nf_projects
        on node_latest.project_id = nf_projects.project_id
), emails as (
    select
    distinct access_event.user_id
    from
    synapse_data_warehouse.synapse_event.access_event
    inner join
        nodes
    on access_event.entity_id = nodes.id
    where
        {expr_daterange}
)
select
    userprofile_latest.id,
    userprofile_latest.email,
    'NF' as portal
from
    emails
inner join
    synapse_data_warehouse.synapse.userprofile_latest
    on emails.user_id = userprofile_latest.id
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
                st.markdown("### Users that viewed portal")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_8_1",
                help="Refresh users_that_viewed_portal data",
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


WITH nf_projects as (
    SELECT
        cast(scopes.value as integer) as project_id
    FROM
        synapse_data_warehouse.synapse.node_latest,
        lateral flatten(input => node_latest.scope_ids) scopes
    WHERE 
        id = 16858331
), 
annotation_type_count_synapse as (
    SELECT 
        NODE_TYPE,
        COUNT(CASE WHEN annotations:annotations != {} THEN 1 END) AS annotated_count,
        COUNT(CASE WHEN annotations is NULL or annotations:annotations = {} THEN 1 END) AS non_annotated_count,
        COUNT(*) as total_type_count,
    FROM 
        synapse_data_warehouse.synapse.node_latest
    WHERE
        project_id NOT IN (SELECT project_id FROM nf_projects)
    GROUP BY 
        NODE_TYPE
), 
annotation_type_count_nf as (
    SELECT 
        NODE_TYPE,
        COUNT(CASE WHEN annotations:annotations != {} THEN 1 END) AS annotated_count,
        COUNT(CASE WHEN annotations is NULL or annotations:annotations = {} THEN 1 END) AS non_annotated_count,
        COUNT(*) as total_type_count,
    FROM 
        synapse_data_warehouse.synapse.node_latest
    WHERE
        project_id IN (SELECT project_id FROM nf_projects)
    GROUP BY 
        NODE_TYPE
)
SELECT 
    annotation_type_count_synapse.NODE_TYPE,
    (annotation_type_count_nf.annotated_count / annotation_type_count_nf.total_type_count) * 100 as percent_annotated_nf,
    (annotation_type_count_nf.non_annotated_count / annotation_type_count_nf.total_type_count) * 100 as percent_not_annotated_nf,
    annotation_type_count_nf.total_type_count as count_nf,
    (annotation_type_count_synapse.annotated_count / annotation_type_count_synapse.total_type_count) * 100 as percent_annotated_synapse,
    (annotation_type_count_synapse.non_annotated_count / annotation_type_count_synapse.total_type_count) * 100 as percent_not_annotated_synapse,
    annotation_type_count_synapse.total_type_count as count_synapse
FROM
    annotation_type_count_synapse
LEFT JOIN
    annotation_type_count_nf
ON
    annotation_type_count_nf.NODE_TYPE = annotation_type_count_synapse.NODE_TYPE  """

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
                st.markdown("### All time entity annotation percentage")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_9_1",
                help="Refresh all_time_entity_annotation_percentage data",
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
WITH nf_projects AS (
    SELECT
        CAST(scopes.value AS INTEGER) AS project_id
    FROM
        synapse_data_warehouse.synapse.node_latest,
        LATERAL FLATTEN(input => node_latest.scope_ids) scopes
    WHERE
        id = 16858331
),
ytd_downloads AS (
    SELECT
        record_date,
        user_id,
        file_handle_id,
        project_id -- Include project_id in the selection
    FROM
      synapse_data_warehouse.synapse_event.objectdownload_event
    WHERE
        EXTRACT(YEAR FROM record_date) = EXTRACT(YEAR FROM CURRENT_DATE)
)
SELECT
    COUNT(DISTINCT record_date || user_id || file_handle_id) AS number_of_downloads,
    COUNT(DISTINCT user_id) AS number_of_unique_users_downloaded
FROM
    ytd_downloads
INNER JOIN
    nf_projects
    ON
        ytd_downloads.project_id = nf_projects.project_id;
  """

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
                st.markdown("### Year to Date Downloads")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_9_2",
                help="Refresh year_to_date_downloads data",
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


# Row 9: 2 Cells
col9_1, col9_2 = st.columns(2)
with col9_1:
    cell_9_1()
with col9_2:
    cell_9_2()


# Footer
st.markdown("---")
st.markdown(
    "*Dashboard loaded: {}*".format(dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
)
