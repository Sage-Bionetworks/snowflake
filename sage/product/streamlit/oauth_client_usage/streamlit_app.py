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
st.set_page_config(page_title="Oauth Client Usage", layout="wide")

# Title
st.title("Oauth Client Usage")
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
        distinct access_event.user_id, oauth_client_id
    from
        synapse_data_warehouse.synapse_event.access_event
    join    
        synapse_rds_snapshot.prod_576.oauth_client on
        access_event.oauth_client_id = oauth_client.id
    where
      -- oauth_client_id in (100426, 100036, 100409, 100363, 100344, 100063, 100419, 100398, 100123, 100164, 100430, 100433, 100436) and
        {expr_daterange} and
        user_id is not null
)
select
    oauth_client.id as oauth_client_id,
    oauth_client.name as oauth_client_name,
    case
        when sage_users.user_id is not null then 'Sage'
        else 'Non-Sage'
    end as user_type,
    count(*) as user_count
from
    all_users
join    
    synapse_rds_snapshot.prod_576.oauth_client on
    all_users.oauth_client_id = oauth_client.id
left join
    sage_users
    on all_users.user_id = sage_users.user_id
group by
    user_type, oauth_client.id, oauth_client.name;


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
                st.markdown("### Number Of Users")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_1",
                help="Refresh number_of_users data",
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
                    df.groupby(by=["OAUTH_CLIENT_NAME", "USER_TYPE"], sort=False)
                    .agg(col1=("USER_COUNT", "sum"))
                    .rename(columns={"col1": "USER_COUNT (sum)"})
                    .unstack(level=1)
                )

                df.columns = [
                    " | ".join(map(str, c[::-1])).replace(":", "_") for c in df.columns
                ]

                df = df.reset_index()
                value_columns = [c for c in df.columns if c != "OAUTH_CLIENT_NAME"]
                df[value_columns] = df[value_columns].fillna(0)

                df["/* Order Key (Generated by Snowflake) */"] = df.drop(
                    columns="OAUTH_CLIENT_NAME"
                ).sum(axis=1)

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["OAUTH_CLIENT_NAME"]):
                    datetime_primary_column = df["OAUTH_CLIENT_NAME"]
                elif df["OAUTH_CLIENT_NAME"].dtype == "object" and isinstance(
                    df["OAUTH_CLIENT_NAME"].get(
                        df["OAUTH_CLIENT_NAME"].first_valid_index()
                    ),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["OAUTH_CLIENT_NAME"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["OAUTH_CLIENT_NAME"] = df["OAUTH_CLIENT_NAME"].astype("string")

                st.bar_chart(
                    df,
                    x="OAUTH_CLIENT_NAME",
                    y=[
                        c
                        for c in df.columns
                        if c != "OAUTH_CLIENT_NAME"
                        and c != "/* Order Key (Generated by Snowflake) */"
                    ],
                    sort="-/* Order Key (Generated by Snowflake) */",
                    width="stretch",
                    height=400,
                    horizontal=True,
                    stack=False,
                    x_label="Users",
                    y_label="Oauth Group",
                )
            else:
                st.warning("No data available")
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
        distinct access_event.user_id, oauth_client_id
    from
        synapse_data_warehouse.synapse_event.access_event
    join    
        synapse_rds_snapshot.prod_576.oauth_client on
        access_event.oauth_client_id = oauth_client.id
    where
        oauth_client_id in (100344, 100398, 100363, 100418, 100419, 100344, 100409) and
        {expr_daterange} and
        user_id is not null
)
select
    oauth_client.id as oauth_client_id,
    oauth_client.name as oauth_client_name,
    case
        when sage_users.user_id is not null then 'Sage'
        else 'Non-Sage'
    end as user_type,
    count(*) as user_count
from
    all_users
join    
    synapse_rds_snapshot.prod_576.oauth_client on
    all_users.oauth_client_id = oauth_client.id
left join
    sage_users
    on all_users.user_id = sage_users.user_id
group by
    user_type, oauth_client.id, oauth_client.name;


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
                st.markdown("### TREs")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_2",
                help="Refresh tres data",
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
                df = (
                    df.groupby(by=["OAUTH_CLIENT_NAME", "USER_TYPE"], sort=False)
                    .agg(col1=("USER_COUNT", "sum"))
                    .rename(columns={"col1": "USER_COUNT (sum)"})
                    .unstack(level=1)
                )

                df.columns = [
                    " | ".join(map(str, c[::-1])).replace(":", "_") for c in df.columns
                ]

                df = df.reset_index()
                value_columns = [c for c in df.columns if c != "OAUTH_CLIENT_NAME"]
                df[value_columns] = df[value_columns].fillna(0)

                df["/* Order Key (Generated by Snowflake) */"] = df.drop(
                    columns="OAUTH_CLIENT_NAME"
                ).sum(axis=1)

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["OAUTH_CLIENT_NAME"]):
                    datetime_primary_column = df["OAUTH_CLIENT_NAME"]
                elif df["OAUTH_CLIENT_NAME"].dtype == "object" and isinstance(
                    df["OAUTH_CLIENT_NAME"].get(
                        df["OAUTH_CLIENT_NAME"].first_valid_index()
                    ),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["OAUTH_CLIENT_NAME"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["OAUTH_CLIENT_NAME"] = df["OAUTH_CLIENT_NAME"].astype("string")

                st.bar_chart(
                    df,
                    x="OAUTH_CLIENT_NAME",
                    y=[
                        c
                        for c in df.columns
                        if c != "OAUTH_CLIENT_NAME"
                        and c != "/* Order Key (Generated by Snowflake) */"
                    ],
                    sort="-/* Order Key (Generated by Snowflake) */",
                    width="stretch",
                    height=400,
                    horizontal=True,
                    stack=False,
                    x_label="Users",
                    y_label="Oauth Group",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_1_3() -> str:
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
        distinct access_event.user_id, oauth_client_id
    from
        synapse_data_warehouse.synapse_event.access_event
    join    
        synapse_rds_snapshot.prod_576.oauth_client on
        access_event.oauth_client_id = oauth_client.id
    where
        oauth_client_id in (
            100419,
            100409,
            100344
        ) and
        {expr_daterange} and
        user_id is not null
)
select
    oauth_client.id as oauth_client_id,
    oauth_client.name as oauth_client_name,
    case
        when sage_users.user_id is not null then 'Sage'
        else 'Non-Sage'
    end as user_type,
    count(*) as user_count
from
    all_users
join    
    synapse_rds_snapshot.prod_576.oauth_client on
    all_users.oauth_client_id = oauth_client.id
left join
    sage_users
    on all_users.user_id = sage_users.user_id
group by
    user_type, oauth_client.id, oauth_client.name;


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
                st.markdown("### Public TREs")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_3",
                help="Refresh public_tres data",
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

            # Prepare data for bar chart
            if len(df) > 0:
                df = (
                    df.groupby(by=["OAUTH_CLIENT_NAME", "USER_TYPE"], sort=False)
                    .agg(col1=("USER_COUNT", "sum"))
                    .rename(columns={"col1": "USER_COUNT (sum)"})
                    .unstack(level=1)
                )

                df.columns = [
                    " | ".join(map(str, c[::-1])).replace(":", "_") for c in df.columns
                ]

                df = df.reset_index()
                value_columns = [c for c in df.columns if c != "OAUTH_CLIENT_NAME"]
                df[value_columns] = df[value_columns].fillna(0)

                df["/* Order Key (Generated by Snowflake) */"] = df.drop(
                    columns="OAUTH_CLIENT_NAME"
                ).sum(axis=1)

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["OAUTH_CLIENT_NAME"]):
                    datetime_primary_column = df["OAUTH_CLIENT_NAME"]
                elif df["OAUTH_CLIENT_NAME"].dtype == "object" and isinstance(
                    df["OAUTH_CLIENT_NAME"].get(
                        df["OAUTH_CLIENT_NAME"].first_valid_index()
                    ),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["OAUTH_CLIENT_NAME"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["OAUTH_CLIENT_NAME"] = df["OAUTH_CLIENT_NAME"].astype("string")

                st.bar_chart(
                    df,
                    x="OAUTH_CLIENT_NAME",
                    y=[
                        c
                        for c in df.columns
                        if c != "OAUTH_CLIENT_NAME"
                        and c != "/* Order Key (Generated by Snowflake) */"
                    ],
                    sort="-/* Order Key (Generated by Snowflake) */",
                    width="stretch",
                    height=400,
                    horizontal=True,
                    stack=False,
                    x_label="Users",
                    y_label="Oauth Group",
                )
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
        distinct access_event.user_id, oauth_client_id
    from
        synapse_data_warehouse.synapse_event.access_event
    join    
        synapse_rds_snapshot.prod_576.oauth_client on
        access_event.oauth_client_id = oauth_client.id
    where
      -- oauth_client_id in (100426, 100036, 100409, 100363, 100344, 100063, 100419, 100398, 100123, 100164, 100430, 100433, 100436) and
        {expr_daterange} and
        user_id is not null
)
select
    oauth_client.id as oauth_client_id,
    oauth_client.name as oauth_client_name,
    case
        when sage_users.user_id is not null then 'Sage'
        else 'Non-Sage'
    end as user_type,
    count(*) as user_count
from
    all_users
join    
    synapse_rds_snapshot.prod_576.oauth_client on
    all_users.oauth_client_id = oauth_client.id
left join
    sage_users
    on all_users.user_id = sage_users.user_id
group by
    user_type, oauth_client.id, oauth_client.name;


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
                st.markdown("### Number Of Users")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_1",
                help="Refresh number_of_users data",
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
        expr_daterange = f"record_date BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange = f"record_date >= '{start_date}'"
    else:
        expr_daterange = "TRUE"

    sql_query = rf"""
select
    case
        when oauth_client_id = 100426 then 'C-PATH'
        when oauth_client_id = 100063 then 'STRIDES Service Catalog'
        when oauth_client_id = 100419 then 'AD workbench'
        when oauth_client_id = 100344 then 'Cavatica'
        when oauth_client_id = 100409 then 'Terra'
        when oauth_client_id = 100398 then 'Pluto Dev'
        when oauth_client_id = 100036 then 'cBioPortal'
        when oauth_client_id = 100363 then 'BioDataCatalyst'
        when oauth_client_id = 100430 then 'Synapse MCP'
        when oauth_client_id = 100436 then 'BioArena prod'
        else 'Other'
    end as oauth_client_name,
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
    oauth_client_id in (100426, 100036, 100409, 100363, 100344, 100063, 100419, 100398, 100430, 100436) and
    {expr_daterange}
group by
    access_event.oauth_client_id,
    access_event.user_id,
    userprofile_latest.user_name,
    userprofile_latest.email
order by
    oauth_client_name,
    number_of_calls desc  """

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
                st.markdown("### User calls")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_1",
                help="Refresh user_calls data",
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


# Footer
st.markdown("---")
st.markdown(
    "*Dashboard loaded: {}*".format(dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
)
