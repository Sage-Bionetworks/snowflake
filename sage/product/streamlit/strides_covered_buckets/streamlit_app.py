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
st.set_page_config(page_title="STRIDES covered buckets", layout="wide")

# Title
st.title("STRIDES covered buckets")
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
    default_start = dt.datetime.now().date() - dt.timedelta(days=30 * 12)
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
select
    file_latest.bucket,
    sum(file_latest.content_size) / power(2, 50) as size_in_pib
from
    synapse_data_warehouse.synapse.file_latest
left join
    sage.it.storage_location_info
    on file_latest.bucket = storage_location_info.bucket
WHERE
    file_latest.status = 'AVAILABLE' and
    not storage_location_info.does_sage_pay and
    storage_location_info.aws_account in (423819316185, 751556145034)
group by 
    file_latest.bucket
order by
    size_in_pib DESC;
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
                st.markdown("### Estimated Storage within buckets (PiB)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_1",
                help="Refresh estimated_storage_within_buckets_(pib) data",
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
select
    CASE 
        WHEN file_latest.bucket IN ('ad-knowledge-portal-main', 'strides-ampad-project-tower-bucket', 'ad-knowledge-portal-large', 'wei-an-chen-project-tower-bucket', 'diverse-cohorts') THEN 'ADTR'
        WHEN file_latest.bucket IN ('pec-capstone-migration', 'psychencode-migration-bucket-bucket-erzvrdscmdvm') THEN 'psychencode'
        WHEN file_latest.bucket = 'exceptional-longevity' THEN 'ELITE'
    END AS program,
    sum(file_latest.content_size) / power(2, 40) as size_in_tib
from
    synapse_data_warehouse.synapse.file_latest
left join
    sage.it.storage_location_info
    on file_latest.bucket = storage_location_info.bucket
WHERE
    file_latest.status = 'AVAILABLE' and
    not storage_location_info.does_sage_pay and
    storage_location_info.aws_account in (423819316185, 751556145034)
group by 
    program
order by
    size_in_tib DESC;
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
                st.markdown("### Estimated Storage per program (TiB)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_2",
                help="Refresh estimated_storage_per_program_(tib) data",
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
select
    file_latest.bucket,
    sum(file_latest.content_size) / power(2, 50) as size_in_pib
from
    synapse_data_warehouse.synapse.file_latest
left join
    sage.it.storage_location_info
    on file_latest.bucket = storage_location_info.bucket
WHERE
    file_latest.status = 'AVAILABLE' and
    not storage_location_info.does_sage_pay and
    storage_location_info.aws_account in (423819316185, 751556145034)
group by 
    file_latest.bucket
order by
    size_in_pib DESC;
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
                st.markdown("### Estimated Storage within buckets (PiB)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_3",
                help="Refresh estimated_storage_within_buckets_(pib) data",
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

            # Calculate metric for scorecard
            if len(df) > 0:
                value = df["SIZE_IN_PIB"].sum()
                st.metric(label="SIZE_IN_PIB", value=f"{value:,.2f}")
            else:
                st.warning("No data available")
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
with synapse_dls as (
    SELECT
        objectdownload_event.user_id,
        objectdownload_event.file_handle_id,
        objectdownload_event.record_date,
        DATE_TRUNC('month', objectdownload_event.record_date) AS month_of_dl,
        objectdownload_event.project_id,
        file_latest.content_size
    FROM
        synapse_data_warehouse.synapse_event.objectdownload_event
    INNER JOIN
        synapse_data_warehouse.synapse.file_latest
        ON objectdownload_event.file_handle_id = file_latest.id
    left join
        sage.it.storage_location_info
        on file_latest.bucket = storage_location_info.bucket
    WHERE
        {expr_daterange} and
        not storage_location_info.does_sage_pay and
        storage_location_info.aws_account in (423819316185, 751556145034)

)
SELECT
    month_of_dl,
    count(distinct user_id) as number_of_unique_users_downloaded_data,
    sum(content_size) / power(2, 40) as total_data_downloaded_in_tib,
    COUNT(*) AS number_of_downloads,
    count(distinct file_handle_id) as number_of_unique_files_downloaded,
    avg(content_size) / power(2, 30) as average_download_size_in_gib
FROM
    synapse_dls
GROUP BY
    month_of_dl
ORDER BY
    month_of_dl DESC;  """

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
                st.markdown("### Monthly Egress cost")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_1",
                help="Refresh monthly_egress_cost data",
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
with synapse_dls as (
    SELECT
        objectdownload_event.user_id,
        objectdownload_event.file_handle_id,
        objectdownload_event.record_date,
        DATE_TRUNC('month', objectdownload_event.record_date) AS month_of_dl,
        objectdownload_event.project_id,
        file_latest.content_size,
        file_latest.bucket
    FROM
        synapse_data_warehouse.synapse_event.objectdownload_event
    INNER JOIN
        synapse_data_warehouse.synapse.file_latest
        ON objectdownload_event.file_handle_id = file_latest.id
    left join
        sage.it.storage_location_info
        ON file_latest.bucket = storage_location_info.bucket
    WHERE
        {expr_daterange} and
        not storage_location_info.does_sage_pay and
        storage_location_info.aws_account in (423819316185, 751556145034)
)
SELECT
    bucket,
    month_of_dl,
    count(distinct user_id) as number_of_unique_users_downloaded_data,
    sum(content_size) / power(2, 40) as total_data_downloaded_in_tib,
    COUNT(*) AS number_of_downloads,
    count(distinct file_handle_id) as number_of_unique_files_downloaded,
    avg(content_size) / power(2, 30) as average_download_size_in_gib
FROM
    synapse_dls
GROUP BY
    bucket, month_of_dl
ORDER BY
    month_of_dl DESC;  """

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
                st.markdown("### Monthly egress per bucket")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_1",
                help="Refresh monthly_egress_per_bucket data",
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
                st.dataframe(df, width="stretch", hide_index=True)
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 3: Single Cell
cell_3_1()


def query_4_1() -> str:
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
with synapse_dls as (
    SELECT
        objectdownload_event.user_id,
        objectdownload_event.file_handle_id,
        objectdownload_event.record_date,
        DATE_TRUNC('month', objectdownload_event.record_date) AS month_of_dl,
        objectdownload_event.project_id,
        file_latest.content_size,
        file_latest.bucket
    FROM
        synapse_data_warehouse.synapse_event.objectdownload_event
    INNER JOIN
        synapse_data_warehouse.synapse.file_latest
        ON objectdownload_event.file_handle_id = file_latest.id
    left join
        sage.it.storage_location_info
        ON file_latest.bucket = storage_location_info.bucket
    WHERE
        {expr_daterange} and
        not storage_location_info.does_sage_pay and
        storage_location_info.aws_account in (423819316185, 751556145034)
)
SELECT
    bucket,
    count(distinct user_id) as number_of_unique_users_downloaded_data,
    sum(content_size) / power(2, 40) as total_data_downloaded_in_tib,
    COUNT(*) AS number_of_downloads,
    count(distinct file_handle_id) as number_of_unique_files_downloaded,
    avg(content_size) / power(2, 30) as average_download_size_in_gib
FROM
    synapse_dls
GROUP BY
    bucket
ORDER BY
    total_data_downloaded_in_tib DESC;  """

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
                st.markdown("### Egress per bucket total")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_1",
                help="Refresh egress_per_bucket_total data",
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
with synapse_dls as (
    SELECT
        objectdownload_event.user_id,
        objectdownload_event.file_handle_id,
        objectdownload_event.record_date,
        DATE_TRUNC('MONTH', objectdownload_event.record_date ) AS month_of_dl,
        objectdownload_event.project_id,
        file_latest.content_size
    FROM
        synapse_data_warehouse.synapse_event.objectdownload_event
    INNER JOIN
        synapse_data_warehouse.synapse.file_latest
        ON objectdownload_event.file_handle_id = file_latest.id
    left join
        sage.it.storage_location_info
        on file_latest.bucket = storage_location_info.bucket
    WHERE
        {expr_daterange} and
        not storage_location_info.does_sage_pay and
        storage_location_info.aws_account in (423819316185, 751556145034)
)
SELECT
    node_latest.name,
    synapse_dls.project_id,
    synapse_dls.month_of_dl,
    count(distinct synapse_dls.user_id) as number_of_unique_users_downloaded_data,
    sum(synapse_dls.content_size) / power(2, 40) as total_data_downloaded_in_tib,
    count(distinct synapse_dls.file_handle_id) as number_of_unique_files_downloaded,
    COUNT(synapse_dls.record_date) AS number_of_downloads,
    avg(synapse_dls.content_size) / power(2, 30) as average_download_size_in_gib,
    node_latest.is_public

FROM
    synapse_dls
join
  synapse_data_warehouse.synapse.node_latest
    on synapse_dls.project_id = node_latest.id
GROUP BY
    synapse_dls.project_id, node_latest.name, node_latest.is_public, synapse_dls.month_of_dl
ORDER BY
    month_of_dl DESC, total_data_downloaded_in_tib DESC NULLS LAST;  """

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
                st.markdown("### Top data egress per project")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_1",
                help="Refresh top_data_egress_per_project data",
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
                st.dataframe(df, width="stretch", hide_index=True)
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 5: Single Cell
cell_5_1()


# Footer
st.markdown("---")
st.markdown(
    "*Dashboard loaded: {}*".format(dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
)
