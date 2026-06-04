import argparse
import datetime as dt
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
st.set_page_config(page_title="Synapse Sage Cost estimation", layout="wide")

# Title
st.title("Synapse Sage Cost estimation")
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
    # Parameter: daterange (absolute)
    st.markdown("**Date range**")
    input_daterange = st.date_input(
        "Date range",
        value=(
            dt.datetime.fromisoformat("2026-03-01T00:00:00.000Z").date(),
            dt.datetime.fromisoformat("2026-04-30T00:00:00.000Z").date(),
        ),
        label_visibility="collapsed",
        key="daterange_param",
    )

st.markdown("---")


@st.cache_data(ttl="23h50m")
def execute_query(query: str) -> str:
    return session.sql(query).collect_nowait().query_id


def query_1_1() -> str:
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
with dedup_synapse_dls as (
    SELECT
        objectdownload_event.user_id,
        objectdownload_event.file_handle_id,
        objectdownload_event.record_date,
        date_trunc('month', objectdownload_event.record_date) AS month_of_dl,
        objectdownload_event.project_id,
        file_latest.content_size
    FROM
        synapse_data_warehouse.synapse_event.objectdownload_event
    INNER JOIN
        synapse_data_warehouse.synapse.file_latest
        ON objectdownload_event.file_handle_id = file_latest.id
    inner join
        sage.it.storage_location_info
        on file_latest.bucket = storage_location_info.bucket
    WHERE
        {expr_daterange} and
        storage_location_info.does_sage_pay
)
SELECT
    month_of_dl,
    count(distinct user_id) as number_of_unique_users_downloaded_data,
    sum(content_size) / power(2, 40) as total_data_egressed_in_tb,
    sum(content_size) / power(2, 30) as total_data_egressed_in_gb,
    COUNT(*) AS number_of_downloads,
    count(distinct file_handle_id) as number_of_unique_files_downloaded,
    avg(content_size) / power(2, 30) as average_download_size_in_gb,
    CASE
        WHEN total_data_egressed_in_gb < 10240 THEN total_data_egressed_in_gb*0.09
        WHEN total_data_egressed_in_gb < 40960 THEN (total_data_egressed_in_gb -10240) *0.085 + 10240*0.09
        WHEN total_data_egressed_in_gb < 102400 THEN (total_data_egressed_in_gb -40960 - 10240) *0.07 + 40960*0.085 + 10240*0.09
        ELSE (total_data_egressed_in_gb - 102400 - 40960 - 10240) * 0.05 + 102400*0.07 + 40960*0.085 + 10240*0.09
    END as upper_egress_cost_estimate
FROM
    dedup_synapse_dls
GROUP BY
    month_of_dl
ORDER BY
    month_of_dl DESC;  """

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
                st.markdown("### Egress cost per month")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_1",
                help="Refresh egress_cost_per_month data",
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
with dedup_synapse_dls as (
    SELECT
        objectdownload_event.user_id,
        objectdownload_event.file_handle_id,
        objectdownload_event.record_date,
        date_trunc('month', objectdownload_event.record_date) AS month_of_dl,
        objectdownload_event.project_id,
        file_latest.content_size,
        file_latest.bucket
    FROM
        synapse_data_warehouse.synapse_event.objectdownload_event
    INNER JOIN
        synapse_data_warehouse.synapse.file_latest
        ON objectdownload_event.file_handle_id = file_latest.id
    inner join
        sage.it.storage_location_info
        on file_latest.bucket = storage_location_info.bucket
    WHERE
        {expr_daterange} and
        storage_location_info.does_sage_pay
)
SELECT
    bucket,
    month_of_dl,
    sum(content_size) / power(2, 30) as total_data_egressed_in_gb,
    CASE
        WHEN total_data_egressed_in_gb < 10240 THEN total_data_egressed_in_gb*0.09
        WHEN total_data_egressed_in_gb < 40960 THEN (total_data_egressed_in_gb -10240) *0.085 + 10240*0.09
        WHEN total_data_egressed_in_gb < 102400 THEN (total_data_egressed_in_gb -40960 - 10240) *0.07 + 40960*0.085 + 10240*0.09
        ELSE (total_data_egressed_in_gb - 102400 - 40960 - 10240) * 0.05 + 102400*0.07 + 40960*0.085 + 10240*0.09
    END as upper_egress_cost_estimate,
    sum(content_size) / power(2, 40) as total_data_egress_in_tb,
    count(distinct user_id) as number_of_unique_users_downloaded_data,
    COUNT(*) AS number_of_downloads,
    count(distinct file_handle_id) as number_of_unique_files_downloaded,
    avg(content_size) / power(2, 30) as average_download_size_in_gb
FROM
    dedup_synapse_dls
GROUP BY
    bucket, month_of_dl
ORDER BY
    month_of_dl DESC, TOTAL_DATA_EGRESSED_IN_GB DESC;  """

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
                st.markdown("### Egress cost per bucket per month")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_1",
                help="Refresh egress_cost_per_bucket_per_month data",
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
with dedup_synapse_dls as (
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
    inner join
        sage.it.storage_location_info
        on file_latest.bucket = storage_location_info.bucket
    WHERE
        {expr_daterange} and
        storage_location_info.does_sage_pay
)
SELECT
    node_latest.name,
    dedup_synapse_dls.project_id,
    node_latest.is_public,
    dedup_synapse_dls.month_of_dl,
    sum(dedup_synapse_dls.content_size) / power(2, 40) as total_data_egress_in_tb,
    COUNT(dedup_synapse_dls.record_date) AS number_of_downloads,
    count(distinct dedup_synapse_dls.file_handle_id) as number_of_unique_files_downloaded,
    count(distinct dedup_synapse_dls.user_id) as number_of_unique_users_downloaded_data,
    avg(dedup_synapse_dls.content_size) / power(2, 30) as average_download_size_in_gb
FROM
    dedup_synapse_dls
join
    SYNAPSE_DATA_WAREHOUSE.synapse.node_latest
    on dedup_synapse_dls.project_id = node_latest.id
GROUP BY
    dedup_synapse_dls.project_id, node_latest.name, node_latest.is_public, dedup_synapse_dls.month_of_dl
ORDER BY
    month_of_dl DESC, total_data_egress_in_tb DESC;  """

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
                st.markdown("### Top data egress per project")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_1",
                help="Refresh top_data_egress_per_project data",
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
with dedup_synapse_dls as (
    SELECT
        objectdownload_event.user_id,
        objectdownload_event.file_handle_id,
        objectdownload_event.record_date,
        date_trunc('month', objectdownload_event.record_date) AS month_of_dl,
        objectdownload_event.project_id,
        file_latest.content_size
    FROM
        synapse_data_warehouse.synapse_event.objectdownload_event
    INNER JOIN
        synapse_data_warehouse.synapse.file_latest ON
        objectdownload_event.file_handle_id = file_latest.id
    inner join
        sage.it.storage_location_info
        on file_latest.bucket = storage_location_info.bucket
    WHERE
        {expr_daterange} and
        storage_location_info.does_sage_pay
)
SELECT
    node_latest.name,
    dedup_synapse_dls.project_id,
    node_latest.is_public,
    sum(dedup_synapse_dls.content_size) / power(2, 40) as total_data_egressed_in_tb,
    count(distinct dedup_synapse_dls.user_id) as number_of_unique_users_downloaded_data,
    COUNT(dedup_synapse_dls.record_date) AS number_of_downloads,
    count(distinct dedup_synapse_dls.file_handle_id) as number_of_unique_files_downloaded,
    avg(dedup_synapse_dls.content_size) / power(2, 30) as average_download_size_in_gb
FROM
    dedup_synapse_dls
join
    SYNAPSE_DATA_WAREHOUSE.synapse.node_latest
    on dedup_synapse_dls.project_id = node_latest.id
GROUP BY
    dedup_synapse_dls.project_id, node_latest.name, node_latest.is_public

ORDER BY
    total_data_egressed_in_tb DESC;  """

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
                st.markdown("### Top data egress per project (total)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_1",
                help="Refresh top_data_egress_per_project_(total) data",
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


with cte as (
    select
        file_latest.content_size,
        node_latest.project_id,
        node_latest.created_on,
        CASE
            WHEN YEAR(node_latest.created_on) < YEAR(CURRENT_TIMESTAMP) THEN file_latest.content_size / power(2, 30) * 0.023 * MONTH(CURRENT_TIMESTAMP)
            ELSE file_latest.content_size / power(2, 30)  * 0.023 * (MONTH(CURRENT_TIMESTAMP) - MONTH(node_latest.created_on))
        END as upper_bound_storage_cost_per_year
    from
        synapse_data_warehouse.synapse.node_latest
    inner join
        synapse_data_warehouse.synapse.file_latest
        on node_latest.file_handle_id = file_latest.id
    inner join
        sage.it.storage_location_info
        on file_latest.bucket = storage_location_info.bucket
    WHERE
        storage_location_info.does_sage_pay
)
select
    node_latest.name,
    cte.project_id,
    node_latest.is_public,
    node_latest.created_on,
    count(*) as number_of_files,
    sum(cte.content_size) / power(2, 40) as size_in_tib,
    (sum(cte.content_size) / power(2, 30)) * 0.023 * 12 as annual_upper_bound_cost,
    sum(cte.upper_bound_storage_cost_per_year) as upper_bound_cost_this_year
from
    cte
join
    synapse_data_warehouse.synapse.node_latest
    on cte.project_id = node_latest.id
group by
    cte.project_id, node_latest.name, node_latest.is_public, node_latest.created_on
order by
    size_in_tib DESC;  """

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
                st.markdown("### Data size per project")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_1",
                help="Refresh data_size_per_project data",
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
with dedup_synapse_dls as (
    SELECT
        objectdownload_event.user_id,
        objectdownload_event.file_handle_id,
        objectdownload_event.record_date,
        date_trunc('month', objectdownload_event.record_date) AS month_of_dl,
        file_latest.content_size
    FROM
        synapse_data_warehouse.synapse_event.objectdownload_event
    INNER JOIN
        synapse_data_warehouse.synapse.file_latest
        ON objectdownload_event.file_handle_id = file_latest.id
    inner join
        sage.it.storage_location_info
        on file_latest.bucket = storage_location_info.bucket
    WHERE
        {expr_daterange} and
        storage_location_info.does_sage_pay
)
SELECT
    record_date,
    sum(content_size) / power(2, 40) AS size_of_dl_in_tb
FROM
    dedup_synapse_dls
GROUP BY
    record_date
ORDER BY
    record_date DESC;  """

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
                st.markdown("### Downloaded data size per day")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_1",
                help="Refresh downloaded_data_size_per_day data",
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

            # Prepare data for line chart with aggregation
            if len(df) > 0:
                df = df[["RECORD_DATE", "SIZE_OF_DL_IN_TB"]]

                st.area_chart(
                    df.set_index("RECORD_DATE"),
                    width="stretch",
                    height=400,
                    x_label="date",
                    y_label="size in tebibytes",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 6: Single Cell
cell_6_1()


def query_7_1() -> str:
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
with dedup_synapse_dls as (
    SELECT
        objectdownload_event.user_id,
        objectdownload_event.file_handle_id,
        objectdownload_event.record_date
    FROM
        synapse_data_warehouse.synapse_event.objectdownload_event
    INNER JOIN
        synapse_data_warehouse.synapse.file_latest
        ON objectdownload_event.file_handle_id = file_latest.id
    inner join
        sage.it.storage_location_info
        on file_latest.bucket = storage_location_info.bucket
    WHERE
        {expr_daterange} and
        storage_location_info.does_sage_pay
)
SELECT
    record_date,
    COUNT(distinct user_id) AS number_of_unique_users
FROM
    dedup_synapse_dls
GROUP BY
    record_date
ORDER BY
    record_date DESC;  """

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
                st.markdown("### Number of unique users per day")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_7_1",
                help="Refresh number_of_unique_users_per_day data",
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
                    df.groupby(by="RECORD_DATE", sort=False)
                    .agg(col1=("NUMBER_OF_UNIQUE_USERS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_UNIQUE_USERS (sum)"})
                    .reset_index()
                )

                st.area_chart(
                    df.set_index("RECORD_DATE"),
                    width="stretch",
                    height=400,
                    x_label="date",
                    y_label="# users",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 7: Single Cell
cell_7_1()


def query_8_1() -> str:
    # Transform :daterange parameter - convert to range comparison
    if isinstance(input_daterange, tuple) and len(input_daterange) == 2:
        start_date, end_date = input_daterange
        expr_daterange = (
            f"fileupload_event.record_date BETWEEN '{start_date}' AND '{end_date}'"
        )
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange = f"fileupload_event.record_date >= '{start_date}'"
    else:
        expr_daterange = "TRUE"

    sql_query = rf"""
with dedup_synapse_dls as (
    SELECT
        fileupload_event.user_id,
        fileupload_event.file_handle_id,
        fileupload_event.record_date,
        date_trunc('month', fileupload_event.record_date) AS month_of_dl
    FROM
        synapse_data_warehouse.synapse_event.fileupload_event
    INNER JOIN
        synapse_data_warehouse.synapse.file_latest
        ON fileupload_event.file_handle_id = file_latest.id
    inner join
        sage.it.storage_location_info
        on file_latest.bucket = storage_location_info.bucket
    WHERE
        {expr_daterange} and
        storage_location_info.does_sage_pay
)
SELECT
    record_date,
    COUNT(*) AS number_of_uploads
FROM
    dedup_synapse_dls
GROUP BY
    record_date
ORDER BY
    record_date DESC;  """

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
                st.markdown("### Uploads per day")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_8_1",
                help="Refresh uploads_per_day data",
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

            # Prepare data for line chart with aggregation
            if len(df) > 0:
                df = df[["RECORD_DATE", "NUMBER_OF_UPLOADS"]]

                st.area_chart(
                    df.set_index("RECORD_DATE"),
                    width="stretch",
                    height=400,
                    x_label="date",
                    y_label="# uploads",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 8: Single Cell
cell_8_1()


# Footer
st.markdown("---")
st.markdown(
    "*Dashboard loaded: {}*".format(dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
)
