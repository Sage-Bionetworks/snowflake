import argparse
import datetime as dt
import pandas as pd
import streamlit as st
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session

# Set page config
st.set_page_config(page_title="Synapse Performance Metrics", layout="wide")

# Title
st.title("Synapse Performance Metrics")


def parse_args() -> bool:
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--local-dev", action="store_true")
    args, _ = parser.parse_known_args()
    return args.local_dev


def get_session(local_dev: bool) -> Session:
    if local_dev:
        return Session.builder.config("connection_name", "default").create()
    return get_active_session()


# Initialize session configured for local dev and SiS runtime
session = get_session(parse_args())
try:
    session.query_tag = "__generated_streamlit"
except Exception:
    pass


@st.cache_data(ttl="23h50m")
def execute_query(query: str) -> str:
    return session.sql(query).collect_nowait().query_id


def query_1_1() -> str:
    sql_query = r"""
-- Slow APIs this week

SELECT *
FROM synapse_data_warehouse.synapse_event.access_event
WHERE record_date between current_date - interval '7' day AND current_date AND
elapse_ms > 30000
and normalized_method_signature not in
(
'PUT /file/multipart/#/add/#',
'PUT /file/multipart/#/complete',
'GET /migration/rowsbyrange',
'GET /migration/rangechecksum',
'GET /migration/count',
'GET /migration/typechecksum',
'GET /migration/status',
'POST /admin/asynchronous/job'
)
ORDER BY timestamp;  """

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
                st.markdown("### Requests >30 seconds, this week")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_1",
                help="Refresh requests_>30_seconds,_this_week data",
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
-- slowest query per hour in the past 2 weeks

SELECT
date_trunc('hour', timestamp) as bin,
concat('STACK-', instance) as stack,
max(elapse_ms) as max_elapsed_ms
FROM synapse_data_warehouse.synapse_event.access_event
WHERE record_date between current_date - interval '14' day AND current_date
AND normalized_method_signature not like '%/evaluation/submission/query%'
AND normalized_method_signature not like '%/file/multipart%'
AND normalized_method_signature not like '%/migration%'
AND normalized_method_signature not like '%/admin%'
group by instance, date_trunc('hour', timestamp)
order by bin  """

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
                st.markdown("### Slowest request per hour in the past 2 weeks")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_1",
                help="Refresh slowest_request_per_hour_in_the_past_2_weeks data",
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
                    df.groupby(by=["BIN", "STACK"], sort=False)
                    .agg(col1=("MAX_ELAPSED_MS", "sum"))
                    .rename(columns={"col1": "MAX_ELAPSED_MS (sum)"})
                    .unstack(level=1)
                )

                df.columns = [
                    " | ".join(map(str, c[::-1])).replace(":", "_") for c in df.columns
                ]

                df = df.reset_index()

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["BIN"]):
                    datetime_primary_column = df["BIN"]
                elif df["BIN"].dtype == "object" and isinstance(
                    df["BIN"].get(df["BIN"].first_valid_index()), dt.date
                ):
                    datetime_primary_column = pd.to_datetime(df["BIN"], errors="coerce")
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["BIN"] = df["BIN"].astype("string")

                st.bar_chart(
                    df.set_index("BIN"),
                    sort=True,
                    width="stretch",
                    height=400,
                    stack=True,
                    y_label="Milliseconds",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 2: Single Cell
cell_2_1()


def query_3_1() -> str:
    sql_query = r"""
-- average latency per hour, past four weeks
SELECT
date_trunc('hour', timestamp) as bin,
concat('STACK-', instance) as stack,
avg(elapse_ms)::float as max_elapsed_ms
FROM synapse_data_warehouse.synapse_event.access_event
WHERE record_date between current_date - interval '28' day AND current_date
AND normalized_method_signature not like '%/evaluation/submission/query%'
AND normalized_method_signature not like '%/file/multipart%'
AND normalized_method_signature not like '%/migration%'
AND normalized_method_signature not like '%/admin%'
group by instance, date_trunc('hour', timestamp)
order by bin  """

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
                st.markdown("### Average latency per hour, past four weeks")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_1",
                help="Refresh average_latency_per_hour,_past_four_weeks data",
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

            # Prepare data for bar chart
            if len(df) > 0:
                df = (
                    df.groupby(by=["BIN", "STACK"], sort=False)
                    .agg(col1=("MAX_ELAPSED_MS", "sum"))
                    .rename(columns={"col1": "MAX_ELAPSED_MS (sum)"})
                    .unstack(level=1)
                )

                df.columns = [
                    " | ".join(map(str, c[::-1])).replace(":", "_") for c in df.columns
                ]

                df = df.reset_index()

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["BIN"]):
                    datetime_primary_column = df["BIN"]
                elif df["BIN"].dtype == "object" and isinstance(
                    df["BIN"].get(df["BIN"].first_valid_index()), dt.date
                ):
                    datetime_primary_column = pd.to_datetime(df["BIN"], errors="coerce")
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["BIN"] = df["BIN"].astype("string")

                st.bar_chart(
                    df.set_index("BIN"),
                    sort=True,
                    width="stretch",
                    height=400,
                    stack=True,
                    y_label="Milliseconds",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 3: Single Cell
cell_3_1()


def query_4_1() -> str:
    sql_query = r"""
-- count per hour, last four weeks

SELECT
date_trunc('hour', timestamp) as bin,
concat('STACK-', instance) as stack,
count(*) as count
FROM synapse_data_warehouse.synapse_event.access_event
WHERE record_date between current_date - interval '28' day AND current_date
AND normalized_method_signature not like '%/evaluation/submission/query%'
AND normalized_method_signature not like '%/file/multipart%'
AND normalized_method_signature not like '%/migration%'
AND normalized_method_signature not like '%/admin%'
group by instance, date_trunc('hour', timestamp)
order by bin  """

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
                st.markdown("### Count per hour, last four weeks")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_1",
                help="Refresh count_per_hour,_last_four_weeks data",
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
                    df.groupby(by=["BIN", "STACK"], sort=False)
                    .agg(col1=("COUNT", "sum"))
                    .rename(columns={"col1": "COUNT (sum)"})
                    .unstack(level=1)
                )

                df.columns = [
                    " | ".join(map(str, c[::-1])).replace(":", "_") for c in df.columns
                ]

                df = df.reset_index()

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["BIN"]):
                    datetime_primary_column = df["BIN"]
                elif df["BIN"].dtype == "object" and isinstance(
                    df["BIN"].get(df["BIN"].first_valid_index()), dt.date
                ):
                    datetime_primary_column = pd.to_datetime(df["BIN"], errors="coerce")
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["BIN"] = df["BIN"].astype("string")

                st.bar_chart(
                    df.set_index("BIN"),
                    sort=True,
                    width="stretch",
                    height=400,
                    stack=True,
                    y_label="COUNT",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 4: Single Cell
cell_4_1()


def query_5_1() -> str:
    sql_query = r"""
-- count of request > 1 sec, over the last four weeks
SELECT
date_trunc('hour', timestamp) as bin,
count(*) as count
FROM synapse_data_warehouse.synapse_event.access_event
WHERE timestamp between current_date - interval '28' day AND current_date
AND elapse_ms > 1000
AND normalized_method_signature not like '%/evaluation/submission/query%'
AND normalized_method_signature not like '%/file/multipart%'
AND normalized_method_signature not like '%/migration%'
AND normalized_method_signature not like '%/admin%'
AND record_date between current_date - interval '28' day AND current_date
group by date_trunc('hour', timestamp)
order by bin asc
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
                st.markdown("### Request > 1 sec, past month")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_1",
                help="Refresh request_>_1_sec,_past_month data",
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
                    df.groupby(by="BIN", sort=False)
                    .agg(col1=("COUNT", "sum"))
                    .rename(columns={"col1": "COUNT (sum)"})
                    .reset_index()
                )

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["BIN"]):
                    datetime_primary_column = df["BIN"]
                elif df["BIN"].dtype == "object" and isinstance(
                    df["BIN"].get(df["BIN"].first_valid_index()), dt.date
                ):
                    datetime_primary_column = pd.to_datetime(df["BIN"], errors="coerce")
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["BIN"] = df["BIN"].astype("string")

                st.bar_chart(
                    df.set_index("BIN"),
                    sort=True,
                    width="stretch",
                    height=400,
                    stack=False,
                    y_label="1s, 5s",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_5_2() -> str:
    sql_query = r"""
-- count of request > 1 sec, over the last four weeks
SELECT
date_trunc('hour', timestamp) as bin,
count(*) as count
FROM synapse_data_warehouse.synapse_event.access_event
WHERE timestamp between current_date - interval '28' day AND current_date
AND elapse_ms > 5000
AND normalized_method_signature not like '%/evaluation/submission/query%'
AND normalized_method_signature not like '%/file/multipart%'
AND normalized_method_signature not like '%/migration%'
AND normalized_method_signature not like '%/admin%'
AND record_date between current_date - interval '28' day AND current_date
group by date_trunc('hour', timestamp)
order by bin
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
                st.markdown("### Requests > 5sec, past month")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_2",
                help="Refresh requests_>_5sec,_past_month data",
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
                    df.groupby(by="BIN", sort=False)
                    .agg(col1=("COUNT", "sum"))
                    .rename(columns={"col1": "COUNT (sum)"})
                    .reset_index()
                )

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["BIN"]):
                    datetime_primary_column = df["BIN"]
                elif df["BIN"].dtype == "object" and isinstance(
                    df["BIN"].get(df["BIN"].first_valid_index()), dt.date
                ):
                    datetime_primary_column = pd.to_datetime(df["BIN"], errors="coerce")
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["BIN"] = df["BIN"].astype("string")

                st.bar_chart(
                    df.set_index("BIN"),
                    sort=True,
                    width="stretch",
                    height=400,
                    stack=False,
                    y_label="1s, 5s",
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
SELECT normalized_method_signature, count(*) as count
FROM synapse_data_warehouse.synapse_event.access_event
WHERE record_date between current_date - interval '7' day AND current_date AND
response_status=500
group by normalized_method_signature
order by count desc  """

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
                st.markdown("### HTTP 500 Responses in the last week")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_1",
                help="Refresh http_500_responses_in_the_last_week data",
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
    sql_query = r"""
-- TopSlowHttpRequestLastWeek
SELECT normalized_method_signature, COUNT(*) AS COUNT
FROM synapse_data_warehouse.synapse_event.access_event
WHERE record_date between current_date - interval '7' day AND current_date AND
elapse_ms > 1000
GROUP BY normalized_method_signature
ORDER BY COUNT DESC;  """

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
                st.markdown("### Top Slow Requests, Last Week")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_7_1",
                help="Refresh top_slow_requests,_last_week data",
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
-- TopSlowHttpRequestLast4Week
SELECT normalized_method_signature, COUNT(*) AS COUNT
FROM synapse_data_warehouse.synapse_event.access_event
WHERE record_date between current_date - interval '28' day AND current_date AND
elapse_ms > 1000
GROUP BY normalized_method_signature
ORDER BY COUNT DESC;  """

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
                st.markdown("### Top Slow Requests, Last Month")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_7_2",
                help="Refresh top_slow_requests,_last_month data",
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


# Footer
st.markdown("---")
st.markdown(
    "*Dashboard loaded: {}*".format(dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
)
