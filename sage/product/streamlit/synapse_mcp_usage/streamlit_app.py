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
st.set_page_config(page_title="Synapse MCP usage", layout="wide")

# Title
st.title("Synapse MCP usage")
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
    default_start = dt.datetime.now().date() - dt.timedelta(days=30 * 3)
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
    # Transform :daterange parameter - convert to range comparison
    if isinstance(input_daterange, tuple) and len(input_daterange) == 2:
        start_date, end_date = input_daterange
        expr_daterange = f"record_date BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange = f"record_date >= '{start_date}'"
    else:
        expr_daterange = "TRUE"

    sql_query = rf"""
with sage_users as (
    select
        *
    from
        table(synapse_data_warehouse.synapse.list_sage_users())
),
all_users as (
    select
        distinct access_event.user_id
    from
        synapse_data_warehouse.synapse_event.access_event
    where
        oauth_client_id = 100441 and
        {expr_daterange} and
        user_id is not null
)
select
    case
        when sage_users.user_id is not null then 'Sage'
        else 'Non-Sage'
    end as user_type,
    count(*) as user_count
from
    all_users
left join
    sage_users
    on all_users.user_id = sage_users.user_id
group by
    user_type;


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
                st.markdown("### Synapse MCP user usage")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_1",
                help="Refresh synapse_mcp_user_usage data",
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
    # Transform :daterange parameter - convert to range comparison
    if isinstance(input_daterange, tuple) and len(input_daterange) == 2:
        start_date, end_date = input_daterange
        expr_daterange = f"record_date BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange = f"record_date >= '{start_date}'"
    else:
        expr_daterange = "TRUE"

    sql_query = rf"""
with sage_users as (
    select
        *
    from
        table(synapse_data_warehouse.synapse.list_sage_users())
),
all_users as (
    select
        distinct access_event.user_id
    from
        synapse_data_warehouse.synapse_event.access_event
    where
        {expr_daterange} and
        user_id is not null and 
        NORMALIZED_METHOD_SIGNATURE = 'POST /agent/session'
)
select
    case
        when sage_users.user_id is not null then 'Sage'
        else 'Non-Sage'
    end as user_type,
    count(*) as user_count
from
    all_users
left join
    sage_users
    on all_users.user_id = sage_users.user_id
group by
    user_type;


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
                st.markdown("### Synapse Chat session Started")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_2",
                help="Refresh synapse_chat_session_started data",
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
    sql_query = r"""

SELECT
    DATE_TRUNC('month', access_event.record_date) AS usage_month,
    COUNT(DISTINCT access_event.user_id) AS total_users,
    COUNT(DISTINCT
        CASE
            WHEN sage_users.user_id IS NOT NULL
            THEN access_event.user_id
        END
    ) AS sage_users,
    COUNT(DISTINCT
        CASE
            WHEN sage_users.user_id IS NULL
            THEN access_event.user_id
        END
    ) AS non_sage_users
FROM
    synapse_data_warehouse.synapse_event.access_event
LEFT JOIN
    TABLE(synapse_data_warehouse.synapse.list_sage_users()) as sage_users
    ON access_event.user_id = sage_users.user_id
WHERE
    access_event.oauth_client_id = '100441' and
    access_event.user_id is not null
GROUP BY
    usage_month
ORDER BY
    usage_month;  """

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
                st.markdown("### Number of users per month")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_1",
                help="Refresh number_of_users_per_month data",
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

            # Prepare data for line chart with aggregation
            if len(df) > 0:
                chart_df = df[
                    ["USAGE_MONTH", "TOTAL_USERS", "SAGE_USERS", "NON_SAGE_USERS"]
                ].copy()
                chart_df["USAGE_MONTH"] = pd.to_datetime(
                    chart_df["USAGE_MONTH"], errors="coerce"
                )
                for col in ["TOTAL_USERS", "SAGE_USERS", "NON_SAGE_USERS"]:
                    chart_df[col] = pd.to_numeric(chart_df[col], errors="coerce")

                chart_df = chart_df.dropna(subset=["USAGE_MONTH"])
                value_cols = ["TOTAL_USERS", "SAGE_USERS", "NON_SAGE_USERS"]
                if chart_df.empty or chart_df[value_cols].dropna(how="all").empty:
                    st.warning("No numeric chart data available")
                elif len(chart_df) < 2:
                    st.dataframe(chart_df, width="stretch", hide_index=True, height=200)
                else:
                    st.line_chart(
                        chart_df.set_index("USAGE_MONTH")[value_cols],
                        width="stretch",
                        height=400,
                    )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 2: Single Cell
cell_2_1()


def query_3_1() -> str:
    # Transform :daterange parameter - convert to range comparison
    if isinstance(input_daterange, tuple) and len(input_daterange) == 2:
        start_date, end_date = input_daterange
        expr_daterange = f"record_date BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange = f"record_date >= '{start_date}'"
    else:
        expr_daterange = "TRUE"

    sql_query = rf"""


select
    distinct
        node_latest.id,
        node_latest.name,
        COALESCE(
            node_latest.annotations:annotations:dataCoordinationCenter:value,
            node_latest.annotations:annotations:fundingAgency:value,
            node_latest.annotations:annotations:consortium:value,
            node_latest.annotations:annotations:CostCenter:value
        ) AS dcc,
        node_latest.annotations:annotations
from
    synapse_data_warehouse.synapse_event.access_event
join
    synapse_data_warehouse.synapse.node_latest
    on access_event.entity_id = node_latest.id and
    node_latest.id = node_latest.project_id
where
    oauth_client_id = 100441 and
    {expr_daterange};  """

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
                st.markdown("### projects pinged by MCP")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_1",
                help="Refresh projects_pinged_by_mcp data",
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
        expr_daterange = f"record_date BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange = f"record_date >= '{start_date}'"
    else:
        expr_daterange = "TRUE"

    sql_query = rf"""
select
    access_event.user_id,
    userprofile_latest.user_name,
    userprofile_latest.email,
    count(*) as number_of_calls,
    max(record_date) as latest_call
from
    synapse_data_warehouse.synapse_event.access_event
join
    synapse_data_warehouse.synapse.userprofile_latest
    on access_event.user_id = userprofile_latest.id
where
    oauth_client_id = 100441 and
    {expr_daterange}
group by
    access_event.user_id,
    userprofile_latest.user_name,
    userprofile_latest.email
order by
    number_of_calls desc  """

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
                st.markdown("### User calls")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_1",
                help="Refresh user_calls data",
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
        expr_daterange = f"record_date BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange = f"record_date >= '{start_date}'"
    else:
        expr_daterange = "TRUE"

    sql_query = rf"""
select
    normalized_method_signature,
    RESPONSE_STATUS,
    avg(elapse_ms),
    count(*) as number_of_calls
from
    synapse_data_warehouse.synapse_event.access_event
where
    oauth_client_id = 100441 and
    {expr_daterange}
group by
    normalized_method_signature,
    RESPONSE_STATUS
order by
    number_of_calls desc  """

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
                st.markdown("### Response status distribution per method")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_1",
                help="Refresh response_status_distribution_per_method data",
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
