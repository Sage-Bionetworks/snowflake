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
            "default connection from ~/.snowflake/connections.toml. "
            "Usage: streamlit run streamlit_app.py -- --local-dev"
        ),
    )
    return parser.parse_args()


def get_session(local_dev: bool) -> Session:
    if local_dev:
        return Session.builder.config("connection_name", "default").create()
    return get_active_session()


# Set page config
st.set_page_config(page_title="Snowflake Workshop Dashboard Demo", layout="wide")

# Title
st.title("Snowflake Workshop Dashboard Demo")
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
param_col_1, param_col_2 = st.columns(2)

with param_col_1:
    # Parameter: datebucket
    st.markdown("**Date bucket**")
    input_datebucket = st.selectbox(
        "Date bucket",
        options=["Second", "Minute", "Hour", "Day", "Week", "Month", "Quarter", "Year"],
        index=5,
        label_visibility="collapsed",
        key="datebucket_param",
    )

with param_col_2:
    # Parameter: daterange (absolute)
    st.markdown("**Date range**")
    input_daterange = st.date_input(
        "Date range",
        value=(dt.datetime.fromisoformat("1900-01-01T00:00:00.000Z").date(),),
        label_visibility="collapsed",
        key="daterange_param",
    )

st.markdown("---")


@st.cache_data(ttl="23h50m")
def execute_query(query: str) -> str:
    return session.sql(query).collect_nowait().query_id


def query_1_1() -> str:
    # Transform :datebucket parameter - convert to DATE_TRUNC call
    expr_datebucket = f"DATE_TRUNC('{input_datebucket}', created_on)"

    # Transform :datebucket parameter - convert to DATE_TRUNC call
    expr_datebucket_1 = f"DATE_TRUNC('{input_datebucket}', created_on)"

    # Transform :daterange parameter - convert to range comparison
    if isinstance(input_daterange, tuple) and len(input_daterange) == 2:
        start_date, end_date = input_daterange
        expr_daterange = f"date_bucket BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange = f"date_bucket >= '{start_date}'"
    else:
        expr_daterange = "TRUE"

    sql_query = rf"""
WITH date_storage AS (
  SELECT
    {expr_datebucket} AS date_bucket,
    SUM(content_size) /(1024 * 1024 * 1024) AS storage_gib,
    SUM(storage_gib) OVER (
    ORDER BY
      date_bucket
  ) AS total_storage_gib_precise
  FROM
    synapse_data_warehouse.synapse.file_latest
  WHERE
    status ILIKE '%AVAILABLE%'
  GROUP BY
    {expr_datebucket_1}
  QUALIFY
    {expr_daterange}
)
SELECT
  date_bucket,
  TRUNCATE(storage_gib, 1) as "New Storage",
  TRUNCATE(total_storage_gib_precise, 1) as "Total Storage"
FROM
  date_storage
ORDER BY
  date_bucket ASC;  """

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
                st.markdown("### Synapse File Storage (GiB)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_1",
                help="Refresh synapse_file_storage_(gib) data",
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

            # Prepare data for line chart with aggregation
            if len(df) > 0:
                df["DATE_BUCKET"] = (
                    pd.to_datetime(df["DATE_BUCKET"]).dt.to_period("M").dt.start_time
                )

                df = df[["DATE_BUCKET", "Total Storage", "New Storage"]]

                st.line_chart(
                    df.set_index("DATE_BUCKET"),
                    width="stretch",
                    height=400,
                    x_label="Date",
                    y_label="Storage (GiB)",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_1_2() -> str:
    # Transform :datebucket parameter - convert to DATE_TRUNC call
    expr_datebucket = f"DATE_TRUNC('{input_datebucket}', created_on)"

    # Transform :daterange parameter - convert to range comparison
    if isinstance(input_daterange, tuple) and len(input_daterange) == 2:
        start_date, end_date = input_daterange
        expr_daterange = f"date_bucket BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange = f"date_bucket >= '{start_date}'"
    else:
        expr_daterange = "TRUE"

    sql_query = rf"""
WITH date_files AS (
  SELECT
    {expr_datebucket} AS date_bucket,
    COUNT(DISTINCT id) AS new_file_count,
    SUM(new_file_count) OVER (
    ORDER BY
      date_bucket
  ) AS total_file_count
  FROM synapse_data_warehouse.synapse.file_latest
  WHERE status ILIKE '%AVAILABLE%'
  GROUP BY date_bucket
  QUALIFY {expr_daterange}
)
SELECT
  date_bucket,
  new_file_count as "File Count",
  total_file_count as "Total File Count"
FROM
  date_files
ORDER BY
  date_bucket ASC;"""

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
                st.markdown("### Synapse Files")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_2",
                help="Refresh synapse_files data",
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

            # Prepare data for bar chart
            if len(df) > 0:
                df["DATE_BUCKET"] = (
                    pd.to_datetime(df["DATE_BUCKET"]).dt.to_period("M").dt.start_time
                )

                df = (
                    df.groupby(by="DATE_BUCKET", sort=False)
                    .agg(col1=("Total File Count", "sum"))
                    .rename(columns={"col1": "Total File Count (sum)"})
                    .reset_index()
                )

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["DATE_BUCKET"]):
                    datetime_primary_column = df["DATE_BUCKET"]
                elif df["DATE_BUCKET"].dtype == "object" and isinstance(
                    df["DATE_BUCKET"].get(df["DATE_BUCKET"].first_valid_index()),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["DATE_BUCKET"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["DATE_BUCKET"] = df["DATE_BUCKET"].astype("string")

                st.bar_chart(
                    df.set_index("DATE_BUCKET"),
                    sort=True,
                    width="stretch",
                    height=400,
                    stack=False,
                    x_label="Date",
                    y_label="Files",
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
    # Transform :datebucket parameter - convert to DATE_TRUNC call
    expr_datebucket = f"DATE_TRUNC('{input_datebucket}', timestamp)"

    # Transform :daterange parameter - convert to range comparison
    if isinstance(input_daterange, tuple) and len(input_daterange) == 2:
        start_date, end_date = input_daterange
        expr_daterange = f"date_bucket BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange = f"date_bucket >= '{start_date}'"
    else:
        expr_daterange = "TRUE"

    sql_query = rf"""
with downloads as (
    select
        {expr_datebucket} as date_bucket,
        count(date_bucket) as download_count
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    where
        {expr_daterange}
    group by
    date_bucket
)
select
    date_bucket,
    download_count as "Download Count"
from
    downloads
order by
    date_bucket asc;"""

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
                st.markdown("### Synapse Object Downloads")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_1",
                help="Refresh synapse_object_downloads data",
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
                df["DATE_BUCKET"] = (
                    pd.to_datetime(df["DATE_BUCKET"]).dt.to_period("M").dt.start_time
                )

                df = (
                    df.groupby(by="DATE_BUCKET", sort=False)
                    .agg(col1=("Download Count", "sum"))
                    .rename(columns={"col1": "Download Count (sum)"})
                    .reset_index()
                )

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["DATE_BUCKET"]):
                    datetime_primary_column = df["DATE_BUCKET"]
                elif df["DATE_BUCKET"].dtype == "object" and isinstance(
                    df["DATE_BUCKET"].get(df["DATE_BUCKET"].first_valid_index()),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["DATE_BUCKET"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["DATE_BUCKET"] = df["DATE_BUCKET"].astype("string")

                st.bar_chart(
                    df.set_index("DATE_BUCKET"),
                    sort=True,
                    width="stretch",
                    height=400,
                    stack=True,
                    x_label="Date",
                    y_label="Downloads",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 2: Single Cell
cell_2_1()


# Footer
st.markdown("---")
st.markdown(
    "*Dashboard loaded: {}*".format(dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
)
