import argparse
import datetime as dt
import streamlit as st
import pandas as pd
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session

# Set page config
st.set_page_config(page_title="Org metrics (2025 OKRs)", layout="wide")

# Title
st.title("Org metrics (2025 OKRs)")
st.markdown(
    '<p style="color: #cc0000; font-size: 0.85rem; margin-top: -0.4rem;">'
    "This app is "
    '<a href="https://github.com/Sage-Bionetworks/snowflake/blob/dev/STREAMLIT.md" target="_blank">managed on Github</a>. '
    "Any local edits will not be retained."
    "</p>",
    unsafe_allow_html=True,
)


# Initialize session configured for generated Streamlit apps
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


args = read_args()
session = get_session(args.local_dev)
try:
    session.query_tag = "__generated_streamlit"
except Exception:
    pass

# Parameter input widgets arranged in a row
(param_col_1,) = st.columns(1)

with param_col_1:
    # Parameter: daterange (absolute)
    st.markdown("**Date range**")
    input_daterange = st.date_input(
        "Date range",
        value=(
            dt.datetime.fromisoformat("2024-01-01T00:00:00.000Z").date(),
            dt.datetime.fromisoformat("2024-09-30T00:00:00.000Z").date(),
        ),
        label_visibility="collapsed",
        key="daterange_param",
    )

st.markdown("---")


@st.cache_data(ttl="23h50m")
def execute_query(query: str) -> str:
    return session.sql(query).collect_nowait().query_id


def query_1_1() -> str:
    sql_query = r"""
with FirstUploads as (
    select
        year(created_on) as year_created,
        created_by
    from synapse_data_warehouse.synapse.node_latest
    where year(created_on) > 2019
    group by year_created, created_by
)
select
    year_created,
    count(distinct created_by) as total_uploaders
from FirstUploads
group by year_created
order by year_created;  """

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
                st.markdown("### O1.KR1 - Number of users uploading (by year)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_1",
                help="Refresh o1.kr1_-_number_of_users_uploading_(by_year) data",
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

            # Prepare data for bar chart
            if len(df) > 0:
                df = (
                    df.groupby(by="YEAR_CREATED", sort=False)
                    .agg(col1=("TOTAL_UPLOADERS", "sum"))
                    .rename(columns={"col1": "TOTAL_UPLOADERS (sum)"})
                    .reset_index()
                )

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["YEAR_CREATED"]):
                    datetime_primary_column = df["YEAR_CREATED"]
                elif df["YEAR_CREATED"].dtype == "object" and isinstance(
                    df["YEAR_CREATED"].get(df["YEAR_CREATED"].first_valid_index()),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["YEAR_CREATED"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["YEAR_CREATED"] = df["YEAR_CREATED"].astype("string")

                st.bar_chart(
                    df.set_index("YEAR_CREATED"),
                    sort=True,
                    width="stretch",
                    height=400,
                    stack=False,
                    x_label="Day of year",
                    y_label="Unique uploaders",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_1_2() -> str:
    sql_query = r"""
with NewUploadersByDay as (
    with FirstUploads as (
        select
            min(created_on) as first_upload_in_year,
            year(created_on) as year_created,
            created_by
        from synapse_data_warehouse.synapse.node_latest
        where year(created_on) > 2019
        group by year_created, created_by
        order by first_upload_in_year
    )
    select 
        date_part('doy',first_upload_in_year) as day_of_year,
        year_created,
        count(created_by) as new_uploaders
    from FirstUploads
    group by
        day_of_year,
        year_created
)
select
    day_of_year,
    year_created,
    -- new_uploaders,
    (select sum(new_uploaders)
    from NewUploadersByDay t2
    where t2.year_created=NewUploadersByDay.year_created and
        t2.day_of_year <= NewUploadersByDay.day_of_year
    ) as cumulative_new_uploaders
from NewUploadersByDay
order by year_created, day_of_year;  """

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
                st.markdown("### O1.KR1 - Number of users uploading (YoY)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_2",
                help="Refresh o1.kr1_-_number_of_users_uploading_(yoy) data",
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

            # Prepare data for line chart with aggregation
            if len(df) > 0:
                df = (
                    df.groupby(by=["DAY_OF_YEAR", "YEAR_CREATED"], sort=False)
                    .agg(col1=("CUMULATIVE_NEW_UPLOADERS", "sum"))
                    .rename(columns={"col1": "CUMULATIVE_NEW_UPLOADERS (sum)"})
                    .unstack(level=1)
                )

                df.columns = [
                    " | ".join(map(str, c[::-1])).replace(":", "_") for c in df.columns
                ]

                df = df.reset_index()

                st.line_chart(
                    df.set_index("DAY_OF_YEAR"),
                    width="stretch",
                    height=400,
                    x_label="Day of year",
                    y_label="Unique uploaders",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 1: 2 Cells
col1_1, col1_2 = st.columns(2)
with col1_1:
    cell_1_1()
with col1_2:
    cell_1_2()


def query_2_1() -> str:
    sql_query = r"""
-- Active user = signed in user who visits Synapse or any portal

with monthly as (
    select 
        a.visit_year,
        a.visit_month,
        count(distinct a.user_id) as active_users
    from (
        select
            user_id, 
            year(record_date) as visit_year,
            month(record_date) as visit_month
        from 
            synapse_data_warehouse.synapse_event.access_event
        where record_date >= '2023-01-01'
    ) a
    group by a.visit_year, a.visit_month
)
select
    visit_year,
  cast(avg(active_users) as double) as avg_monthly_active_users
from monthly
group by visit_year
order by visit_year;  """

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
                st.markdown("### O3.KR1 - Average MAUs by calendar year")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_1",
                help="Refresh o3.kr1_-_average_maus_by_calendar_year data",
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

            # Prepare data for bar chart
            if len(df) > 0:
                df = (
                    df.groupby(by="VISIT_YEAR", sort=False)
                    .agg(col1=("AVG_MONTHLY_ACTIVE_USERS", "sum"))
                    .rename(columns={"col1": "AVG_MONTHLY_ACTIVE_USERS (sum)"})
                    .reset_index()
                )

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["VISIT_YEAR"]):
                    datetime_primary_column = df["VISIT_YEAR"]
                elif df["VISIT_YEAR"].dtype == "object" and isinstance(
                    df["VISIT_YEAR"].get(df["VISIT_YEAR"].first_valid_index()), dt.date
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["VISIT_YEAR"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["VISIT_YEAR"] = df["VISIT_YEAR"].astype("string")

                st.bar_chart(
                    df.set_index("VISIT_YEAR"),
                    sort=True,
                    width="stretch",
                    height=400,
                    stack=False,
                    x_label="Year",
                    y_label="Average MAUs",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_2_2() -> str:
    sql_query = r"""
-- Active user = signed in user who visits Synapse or any portal

select 
    a.visit_year,
    a.visit_month,
    count(distinct a.user_id) as active_users
from (
    select
        user_id, 
        year(record_date) as visit_year,
        month(record_date) as visit_month
    from 
        synapse_data_warehouse.synapse_event.access_event
    where record_date >= '2023-01-01'
) a
group by a.visit_year, a.visit_month
order by a.visit_year, a.visit_month;  """

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
                st.markdown("### O3.KR1 - MAUs (YoY comparison)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_2",
                help="Refresh o3.kr1_-_maus_(yoy_comparison) data",
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

            # Prepare data for line chart with aggregation
            if len(df) > 0:
                df = (
                    df.groupby(by=["VISIT_MONTH", "VISIT_YEAR"], sort=False)
                    .agg(col1=("ACTIVE_USERS", "sum"))
                    .rename(columns={"col1": "ACTIVE_USERS (sum)"})
                    .unstack(level=1)
                )

                df.columns = [
                    " | ".join(map(str, c[::-1])).replace(":", "_") for c in df.columns
                ]

                df = df.reset_index()

                st.line_chart(
                    df.set_index("VISIT_MONTH"),
                    width="stretch",
                    height=400,
                    x_label="Month",
                    y_label="MAUs",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 2: 2 Cells
col2_1, col2_2 = st.columns(2)
with col2_1:
    cell_2_1()
with col2_2:
    cell_2_2()


def query_3_1() -> str:
    sql_query = r"""
select 
    a.visit_year, a.visit_month,
    date_from_parts(a.visit_year, a.visit_month, 1) as first_day_of_month,
    count(a.user_id) as active_users
from (
    select distinct
        user_id, 
        year(record_date) as visit_year,
        month(record_date) as visit_month
    from 
        synapse_data_warehouse.synapse_event.access_event
    where record_date>='2023-01-01'
) a
group by
    a.visit_year, a.visit_month
order by
    a.visit_year, a.visit_month;  """

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
                st.markdown(
                    "### O3.KR1 - Monthly active users (signed in users who visit Synapse or any portal)"
                )
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_1",
                help="Refresh o3.kr1_-_monthly_active_users_(signed_in_users_who_visit_synapse_or_any_portal) data",
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
                    df.groupby(by="FIRST_DAY_OF_MONTH", sort=False)
                    .agg(col1=("ACTIVE_USERS", "sum"))
                    .rename(columns={"col1": "ACTIVE_USERS (sum)"})
                    .reset_index()
                )

                st.line_chart(
                    df.set_index("FIRST_DAY_OF_MONTH"),
                    width="stretch",
                    height=400,
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 3: Single Cell
cell_3_1()


def query_4_1() -> str:
    sql_query = r"""
-- Number of projects created each year that have not yet been deleted
-- Note from Tom:
-- I just realized these queries will fluctuate based on the current state of synapse.  
-- For example, if a project was created in 2023 but deleted in 2025, the metrics will no longer show up (using our latest queries) 
-- We will need to account for this when creating reports in the future.

select
    year(node_latest.created_on) as year_of_creation,
    count(*) as number_of_projects,
    -- count(distinct case 
    --     when email not like '%@sagebase.org' 
    --      and email not like '%@sagebionetworks.org' 
    --     then node_latest.id 
    -- end) as number_of_non_sage_created_projects
from
    synapse_data_warehouse.synapse.node_latest
left join
    synapse_data_warehouse.synapse.userprofile_latest
    on node_latest.created_by = userprofile_latest.id
where
    node_latest.created_on>=date('2023-01-01')
    and node_type = 'project'
group by
    year_of_creation
order by
    year_of_creation;  """

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
                st.markdown("### Number of projects created by year (approx)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_1",
                help="Refresh number_of_projects_created_by_year_(approx) data",
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

            # Prepare data for bar chart
            if len(df) > 0:
                df = (
                    df.groupby(by="YEAR_OF_CREATION", sort=False)
                    .agg(col1=("NUMBER_OF_PROJECTS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_PROJECTS (sum)"})
                    .reset_index()
                )

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["YEAR_OF_CREATION"]):
                    datetime_primary_column = df["YEAR_OF_CREATION"]
                elif df["YEAR_OF_CREATION"].dtype == "object" and isinstance(
                    df["YEAR_OF_CREATION"].get(
                        df["YEAR_OF_CREATION"].first_valid_index()
                    ),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["YEAR_OF_CREATION"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["YEAR_OF_CREATION"] = df["YEAR_OF_CREATION"].astype("string")

                st.bar_chart(
                    df.set_index("YEAR_OF_CREATION"),
                    sort=True,
                    width="stretch",
                    height=400,
                    stack=False,
                    x_label="Year",
                    y_label="Number of projects created",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_4_2() -> str:
    sql_query = r"""
-- Number of projects created each year that have not yet been deleted
-- Note from Tom:
-- I just realized these queries will fluctuate based on the current state of synapse.  
-- For example, if a project was created in 2023 but deleted in 2025, the metrics will no longer show up (using our latest queries) 
-- We will need to account for this when creating reports in the future.

with projects as (
    select
        node_latest.id as project_id,
        date(node_latest.created_on) as created_date,
        year(node_latest.created_on) as created_year,
        dayofyear(node_latest.created_on) as day_of_year
    from
        synapse_data_warehouse.synapse.node_latest
    where
        node_latest.created_on between date('2023-01-01') and date('2025-12-31')
        and node_type = 'project'
)
select
    created_year,
    day_of_year,
    count(*) over (
        partition by created_year
        order by day_of_year
        rows between unbounded preceding and current row
    ) as cumulative_projects
from projects
order by created_year, day_of_year;  """

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
                st.markdown("### Number of projects created YoY (approx)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_2",
                help="Refresh number_of_projects_created_yoy_(approx) data",
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

            # Prepare data for line chart with aggregation
            if len(df) > 0:
                df = (
                    df.groupby(by=["DAY_OF_YEAR", "CREATED_YEAR"], sort=False)
                    .agg(col1=("CUMULATIVE_PROJECTS", "max"))
                    .rename(columns={"col1": "CUMULATIVE_PROJECTS (max)"})
                    .unstack(level=1)
                )

                df.columns = [
                    " | ".join(map(str, c[::-1])).replace(":", "_") for c in df.columns
                ]

                df = df.reset_index()

                st.line_chart(
                    df.set_index("DAY_OF_YEAR"),
                    width="stretch",
                    height=400,
                    x_label="Year",
                    y_label="Number of projects created",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 4: 2 Cells
col4_1, col4_2 = st.columns(2)
with col4_1:
    cell_4_1()
with col4_2:
    cell_4_2()


def query_5_1() -> str:
    sql_query = r"""
WITH DistinctDownloads AS (
    SELECT DISTINCT
        user_id, 
        YEAR(record_date) AS download_year
    FROM 
        synapse_data_warehouse.synapse_event.objectdownload_event
    WHERE record_date >= '2023-01-01'
)
SELECT 
    download_year,
    COUNT(DISTINCT user_id) AS num_downloaders
FROM 
    DistinctDownloads
GROUP BY 
    download_year
ORDER BY 
    download_year;  """

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
                st.markdown("### O3.KR2 - Number of unique downloaders by year")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_1",
                help="Refresh o3.kr2_-_number_of_unique_downloaders_by_year data",
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

            # Prepare data for bar chart
            if len(df) > 0:
                df = (
                    df.groupby(by="DOWNLOAD_YEAR", sort=False)
                    .agg(col1=("NUM_DOWNLOADERS", "sum"))
                    .rename(columns={"col1": "NUM_DOWNLOADERS (sum)"})
                    .reset_index()
                )

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["DOWNLOAD_YEAR"]):
                    datetime_primary_column = df["DOWNLOAD_YEAR"]
                elif df["DOWNLOAD_YEAR"].dtype == "object" and isinstance(
                    df["DOWNLOAD_YEAR"].get(df["DOWNLOAD_YEAR"].first_valid_index()),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["DOWNLOAD_YEAR"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["DOWNLOAD_YEAR"] = df["DOWNLOAD_YEAR"].astype("string")

                st.bar_chart(
                    df.set_index("DOWNLOAD_YEAR"),
                    sort=True,
                    width="stretch",
                    height=400,
                    stack=False,
                    x_label="Month",
                    y_label="Unique downloaders",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_5_2() -> str:
    sql_query = r"""
with first_downloads as (
    select
        user_id,
        year(record_date) as download_year,
        min(date(record_date)) as first_download_in_year
    from synapse_data_warehouse.synapse_event.objectdownload_event
    where record_date >= '2023-01-01'
    group by user_id, year(record_date)
),
new_downloaders_by_day as (
    select
        download_year,
        date_part('doy', first_download_in_year) as day_of_year,
        count(*) as new_downloaders
    from first_downloads
    group by download_year, day_of_year
)
select
    download_year,
    day_of_year,
    sum(new_downloaders) over (
        partition by download_year
        order by day_of_year
        rows between unbounded preceding and current row
    ) as cumulative_unique_downloaders
from new_downloaders_by_day
order by download_year, day_of_year;  """

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
                st.markdown("### O3.KR2 - Number of users downloading (YoY)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_2",
                help="Refresh o3.kr2_-_number_of_users_downloading_(yoy) data",
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
                    df.groupby(by=["DAY_OF_YEAR", "DOWNLOAD_YEAR"], sort=False)
                    .agg(col1=("CUMULATIVE_UNIQUE_DOWNLOADERS", "sum"))
                    .rename(columns={"col1": "CUMULATIVE_UNIQUE_DOWNLOADERS (sum)"})
                    .unstack(level=1)
                )

                df.columns = [
                    " | ".join(map(str, c[::-1])).replace(":", "_") for c in df.columns
                ]

                df = df.reset_index()

                st.line_chart(
                    df.set_index("DAY_OF_YEAR"),
                    width="stretch",
                    height=400,
                    x_label="Month",
                    y_label="Unique downloaders",
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
SELECT
    year(timestamp) as year,
    count(DISTINCT USER_ID) AS NUMBER_OF_UNIQUE_USERS
FROM
    synapse_data_warehouse.synapse_event.access_event
WHERE
    ORIGIN='https://www.synapse.org'
    and year(timestamp)>2022
GROUP BY year(timestamp);  """

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
                st.markdown("### Visitors to Synapse.org")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_1",
                help="Refresh visitors_to_synapse.org data",
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
                    df.groupby(by="YEAR", sort=False)
                    .agg(col1=("NUMBER_OF_UNIQUE_USERS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_UNIQUE_USERS (sum)"})
                    .reset_index()
                )

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["YEAR"]):
                    datetime_primary_column = df["YEAR"]
                elif df["YEAR"].dtype == "object" and isinstance(
                    df["YEAR"].get(df["YEAR"].first_valid_index()), dt.date
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["YEAR"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["YEAR"] = df["YEAR"].astype("string")

                st.bar_chart(
                    df.set_index("YEAR"),
                    sort=True,
                    width="stretch",
                    height=400,
                    stack=False,
                    x_label="Month",
                    y_label="Unique visitors",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_6_2() -> str:
    sql_query = r"""
with first_seen as (
  select
      user_id,
      year(timestamp)                       as year,
      min(date(timestamp))                  as first_seen_in_year
  from synapse_data_warehouse.synapse_event.access_event
  where origin = 'https://www.synapse.org'
    and year(timestamp) > 2022
  group by user_id, year(timestamp)
),
new_users_by_day as (
  select
      year,
      date_part('doy', first_seen_in_year)  as day_of_year,
      count(*)                              as new_unique_users
  from first_seen
  group by year, day_of_year
)
select
    year,
    day_of_year,
    sum(new_unique_users) over (
      partition by year
      order by day_of_year
      rows between unbounded preceding and current row
    ) as cumulative_unique_users
from new_users_by_day
order by year, day_of_year;  """

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
                st.markdown("### Visitors to Synapse.org (YoY)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_2",
                help="Refresh visitors_to_synapse.org_(yoy) data",
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

            # Prepare data for line chart with aggregation
            if len(df) > 0:
                df = (
                    df.groupby(by=["DAY_OF_YEAR", "YEAR"], sort=False)
                    .agg(col1=("CUMULATIVE_UNIQUE_USERS", "sum"))
                    .rename(columns={"col1": "CUMULATIVE_UNIQUE_USERS (sum)"})
                    .unstack(level=1)
                )

                df.columns = [
                    " | ".join(map(str, c[::-1])).replace(":", "_") for c in df.columns
                ]

                df = df.reset_index()

                st.line_chart(
                    df.set_index("DAY_OF_YEAR"),
                    width="stretch",
                    height=400,
                    x_label="Month",
                    y_label="Unique visitors",
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
    # Transform :daterange parameter - convert to range comparison
    if isinstance(input_daterange, tuple) and len(input_daterange) == 2:
        start_date, end_date = input_daterange
        expr_daterange = f"record_date BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange = f"record_date >= '{start_date}'"
    else:
        expr_daterange = "TRUE"

    # Transform :daterange parameter - convert to range comparison
    if isinstance(input_daterange, tuple) and len(input_daterange) == 2:
        start_date, end_date = input_daterange
        expr_daterange_1 = f"record_date BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange_1 = f"record_date >= '{start_date}'"
    else:
        expr_daterange_1 = "TRUE"

    # Transform :daterange parameter - convert to range comparison
    if isinstance(input_daterange, tuple) and len(input_daterange) == 2:
        start_date, end_date = input_daterange
        expr_daterange_2 = f"record_date BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange_2 = f"record_date >= '{start_date}'"
    else:
        expr_daterange_2 = "TRUE"

    # Transform :daterange parameter - convert to range comparison
    if isinstance(input_daterange, tuple) and len(input_daterange) == 2:
        start_date, end_date = input_daterange
        expr_daterange_3 = f"record_date BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange_3 = f"record_date >= '{start_date}'"
    else:
        expr_daterange_3 = "TRUE"

    # Transform :daterange parameter - convert to range comparison
    if isinstance(input_daterange, tuple) and len(input_daterange) == 2:
        start_date, end_date = input_daterange
        expr_daterange_4 = f"record_date BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange_4 = f"record_date >= '{start_date}'"
    else:
        expr_daterange_4 = "TRUE"

    # Transform :daterange parameter - convert to range comparison
    if isinstance(input_daterange, tuple) and len(input_daterange) == 2:
        start_date, end_date = input_daterange
        expr_daterange_5 = f"record_date BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange_5 = f"record_date >= '{start_date}'"
    else:
        expr_daterange_5 = "TRUE"

    sql_query = rf"""
select
     DATE_TRUNC('MONTH', record_date) as download_month,
     count(distinct user_id),
     'views' as access_type
from
    synapse_data_warehouse.synapse_event.access_event
where
    {expr_daterange}
group by
    DATE_TRUNC('MONTH', record_date)
UNION
select
     DATE_TRUNC('MONTH', record_date) as download_month,
     count(distinct user_id),
     'filedownloads' as access_type
from
    synapse_data_warehouse.synapse_event.objectdownload_event
where
    {expr_daterange_1} and
    association_object_type = 'FileEntity'
group by
    DATE_TRUNC('MONTH', record_date)
UNION
select
     DATE_TRUNC('MONTH', record_date) as download_month,
     count(distinct user_id),
     'tabledownloads' as access_type
from
    synapse_data_warehouse.synapse_event.objectdownload_event
where
    {expr_daterange_2} and
    association_object_type = 'TableEntity'
group by
    DATE_TRUNC('MONTH', record_date)
UNION
select
     DATE_TRUNC('MONTH', record_date) as download_month,
     count(distinct user_id),
     'file_and_table_downloads' as access_type
from
    synapse_data_warehouse.synapse_event.objectdownload_event
where
    {expr_daterange_3} and
    association_object_type in ('TableEntity', 'FileEntity')
group by
    DATE_TRUNC('MONTH', record_date)
UNION
select
     DATE_TRUNC('MONTH', record_date) as download_month,
     count(distinct user_id),
     'wiki_downloads' as access_type
from
    synapse_data_warehouse.synapse_event.objectdownload_event
where
    {expr_daterange_4} and
    association_object_type in ('WikiAttachment')
group by
    DATE_TRUNC('MONTH', record_date)
UNION
select
     DATE_TRUNC('MONTH', record_date) as download_month,
     count(distinct user_id),
     'all_downloads' as access_type
from
    synapse_data_warehouse.synapse_event.objectdownload_event
where
    {expr_daterange_5}
group by
    DATE_TRUNC('MONTH', record_date);  """

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
                st.markdown("### Synapse Views vs Downloads (signed in users)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_7_1",
                help="Refresh synapse_views_vs_downloads_(signed_in_users) data",
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

            # Prepare data for line chart with aggregation
            if len(df) > 0:
                df = (
                    df.groupby(by=["DOWNLOAD_MONTH", "ACCESS_TYPE"], sort=False)
                    .agg(col1=("COUNT(DISTINCT USER_ID)", "sum"))
                    .rename(columns={"col1": "COUNT(DISTINCT USER_ID) (sum)"})
                    .unstack(level=1)
                )

                df.columns = [
                    " | ".join(map(str, c[::-1])).replace(":", "_") for c in df.columns
                ]

                df = df.reset_index()

                st.line_chart(
                    df.set_index("DOWNLOAD_MONTH"),
                    width="stretch",
                    height=400,
                    x_label="month",
                    y_label="number of unique users",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 7: Single Cell
cell_7_1()


def query_8_1() -> str:
    sql_query = r"""
select
    association_object_type,
    count(distinct user_id, file_handle_id, record_date) as number_of_downloads
from
    synapse_data_warehouse.synapse_event.objectdownload_event
group by
    association_object_type;  """

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
                st.markdown("### Distribution of downloads per object type")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_8_1",
                help="Refresh distribution_of_downloads_per_object_type data",
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

            # Prepare data for bar chart
            if len(df) > 0:
                df = (
                    df.groupby(by="ASSOCIATION_OBJECT_TYPE", sort=False)
                    .agg(col1=("NUMBER_OF_DOWNLOADS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_DOWNLOADS (sum)"})
                    .reset_index()
                )

                df["/* Order Key (Generated by Snowflake) */"] = df.drop(
                    columns="ASSOCIATION_OBJECT_TYPE"
                ).sum(axis=1)

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["ASSOCIATION_OBJECT_TYPE"]):
                    datetime_primary_column = df["ASSOCIATION_OBJECT_TYPE"]
                elif df["ASSOCIATION_OBJECT_TYPE"].dtype == "object" and isinstance(
                    df["ASSOCIATION_OBJECT_TYPE"].get(
                        df["ASSOCIATION_OBJECT_TYPE"].first_valid_index()
                    ),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["ASSOCIATION_OBJECT_TYPE"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["ASSOCIATION_OBJECT_TYPE"] = df[
                        "ASSOCIATION_OBJECT_TYPE"
                    ].astype("string")

                st.bar_chart(
                    df,
                    x="ASSOCIATION_OBJECT_TYPE",
                    y=[
                        c
                        for c in df.columns
                        if c != "ASSOCIATION_OBJECT_TYPE"
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


# Row 8: Single Cell
cell_8_1()


def query_9_1() -> str:
    sql_query = r"""
-- we don't distinguish between certified/uncertified users
-- we don't take into consideration UPLOADS - only downloads
-- we assume the user has access to their desired project before they make their first download
-- (i.e. they're not downloading from a random project they didn't initially come to Synapse for)
--create or replace temporary table temp_first_downloads as
-- FIRST WE GRAB ALL THE user profiles THAT WERE EVER CREATED
with user_ids as (
    select
        id,
        created_on
    from
      synapse_data_warehouse.synapse.userprofile_latest
    where
        change_type = 'CREATE'
),
-- THEN WE GRAB THE EARLIEST DOWNLOAD FOR EACH OF THESE user_ids AND project_ids
first_downloads_per_project as (
    select
        user_id,
        project_id,
        min(timestamp) AS download_timestamp,
    from
      synapse_data_warehouse.synapse_event.objectdownload_event
    where
        stack = 'prod'
    group by
        user_id,
        project_id
),
-- THEN WE GRAB THE EARLIEST DOWNLOAD PER user_ids
first_downloads_per_user as (
    select
        user_id,
        min(download_timestamp) as first_download_timestamp
    from
        first_downloads_per_project
    group by
        user_id
),
-- THEN WE GET THE PROJECT NAMES
project_names as (
    select
        name,
        project_id
    from
      synapse_data_warehouse.synapse.node_latest
    where
        node_type = 'project'
),
final_table_first_downloads as (
    select
        user_ids.id,
        user_ids.created_on,
        first_downloads_per_user.first_download_timestamp,
        first_downloads_per_project.project_id,
        project_names.name
    from
        first_downloads_per_user
    join
        first_downloads_per_project
    on
        first_downloads_per_user.user_id = first_downloads_per_project.user_id
    and
        first_downloads_per_user.first_download_timestamp = first_downloads_per_project.download_timestamp
    join
        user_ids
    on
        first_downloads_per_user.user_id = user_ids.id
    join
        project_names
    on
        first_downloads_per_project.project_id = project_names.project_id
)
SELECT
    name,
    project_id,
    COUNT(*) AS user_count
FROM
    final_table_first_downloads
GROUP BY
    name,
    project_id
ORDER BY
    user_count DESC;   """

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
                st.markdown('### "Entrypoint" Projects')
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_9_1",
                help='Refresh "entrypoint"_projects data',
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
