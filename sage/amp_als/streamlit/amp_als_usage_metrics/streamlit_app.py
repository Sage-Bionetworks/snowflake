import argparse
import datetime as dt
import pandas as pd
import streamlit as st
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session

# Set page config
st.set_page_config(page_title="AMP-ALS Usage Metrics", layout="wide")

# Title
st.title("AMP-ALS Usage Metrics")

st.markdown(
    '<p style="color: #cc0000; font-size: 0.85rem; margin-top: -0.4rem;">'
    "This app is "
    '<a href="https://github.com/Sage-Bionetworks/snowflake/blob/dev/STREAMLIT.md" target="_blank">managed on Github</a>. '
    "Any local edits will not be retained."
    "</p>",
    unsafe_allow_html=True,
)


def read_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--local-dev",
        action="store_true",
        help=(
            "Run in local development mode using the 'default' connection from "
            "~/.snowflake/connections.toml."
        ),
    )
    return parser.parse_args()


def get_session(local_dev: bool) -> Session:
    if local_dev:
        return Session.builder.config("connection_name", "default").create()

    return get_active_session()


# Initialize session configured for generated Streamlit apps
args = read_args()
session = get_session(args.local_dev)
try:
    session.query_tag = "__generated_streamlit"
except Exception:
    pass


@st.cache_data(ttl="23h50m")
def execute_query(query: str) -> str:
    return session.sql(query).collect_nowait().query_id


def query_1_1() -> str:
    sql_query = r"""
-- get latest projects https://www.synapse.org/#!Synapse:syn51489960/tables/query/eyJzcWwiOiJTRUxFQ1QgZGlzdGluY3QocHJvamVjdElkKSBGUk9NIHN5bjUxNDg5OTYwIiwgImluY2x1ZGVFbnRpdHlFdGFnIjp0cnVlLCAibGltaXQiOjI1fQ==

select
    min(record_date) as min_dl_date,
    max(record_date) as max_dl_date
from
    synapse_data_warehouse.synapse_event.objectdownload_event
where
    project_id in (
        64892175,
        68702804
    )
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
select
    count(*) as number_of_files,
    sum(content_size) / power(2, 40) AS TOTAL_SIZE_IN_TIb,
    sum(content_size) / power(2, 30) * 0.023 * 12 AS annual_price_estimate
from
    synapse_data_warehouse.synapse.node_latest
inner join
    synapse_data_warehouse.synapse.file_latest
    on node_latest.file_handle_id = file_latest.id
where
    node_latest.project_id in (
        64892175,
        68702804
    )

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


# Row 1: 2 Cells
col1_1, col1_2 = st.columns(2)
with col1_1:
    cell_1_1()
with col1_2:
    cell_1_2()


def query_2_1() -> str:
    sql_query = r"""
select
    count(*) as number_of_downloads,
    count(distinct user_id) as number_of_unique_users_downloaded
from
    synapse_data_warehouse.synapse_event.objectdownload_event
where
    project_id in (
        64892175,
        68702804
    );  """

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
WITH sage_users AS (
    SELECT
        *
    FROM
        table(synapse_data_warehouse.synapse.list_sage_users())
), dedup_downloads as (
    select
        record_date, user_id, file_handle_id
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    where
        project_id in (
            64892175,
            68702804
        ) and
        user_id not in (select * from sage_users)
)
select
    count(*) as number_of_downloads,
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


# Row 2: 2 Cells
col2_1, col2_2 = st.columns(2)
with col2_1:
    cell_2_1()
with col2_2:
    cell_2_2()


def query_3_1() -> str:
    sql_query = r"""

with dedup_downloads as (
    select
        record_date, user_id, file_handle_id
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    where
        project_id in (
            64892175,
            68702804
        )
)
select
    date_trunc('MONTH', RECORD_DATE) AS month_of_dl,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    count(distinct sage_users.user_id) as number_of_sage_users,
    count(sage_users.user_id) as number_of_sage_downloads

FROM
    dedup_downloads
left join
    table(synapse_data_warehouse.synapse.list_sage_users()) sage_users on
    dedup_downloads.user_id = sage_users.user_id
GROUP BY
    month_of_dl
ORDER BY
    month_of_dl DESC
    NULLS LAST;
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
                st.dataframe(df, width="stretch", hide_index=True)
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 3: Single Cell
cell_3_1()


def query_4_1() -> str:
    sql_query = r"""

with dedup_downloads as (
    select
        record_date, user_id, file_handle_id
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    where
        project_id in (
            64892175,
            68702804
        )
)
select
    date_trunc('MONTH', RECORD_DATE) AS month_of_dl,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    count(distinct sage_users.user_id) as number_of_sage_users,
    count(sage_users.user_id) as number_of_sage_downloads

FROM
    dedup_downloads
left join
    table(synapse_data_warehouse.synapse.list_sage_users()) sage_users on
    dedup_downloads.user_id = sage_users.user_id
GROUP BY
    month_of_dl
ORDER BY
    month_of_dl DESC
    NULLS LAST;
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
                st.markdown("### downloads per month")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_1",
                help="Refresh downloads_per_month data",
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
                    df.groupby(by="MONTH_OF_DL", sort=False)
                    .agg(col1=("NUMBER_OF_DOWNLOADS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_DOWNLOADS (sum)"})
                    .reset_index()
                )

                df["/* Order Key (Generated by Snowflake) */"] = df["MONTH_OF_DL"]

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["MONTH_OF_DL"]):
                    datetime_primary_column = df["MONTH_OF_DL"]
                elif df["MONTH_OF_DL"].dtype == "object" and isinstance(
                    df["MONTH_OF_DL"].get(df["MONTH_OF_DL"].first_valid_index()),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["MONTH_OF_DL"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["MONTH_OF_DL"] = df["MONTH_OF_DL"].astype("string")

                st.bar_chart(
                    df,
                    x="MONTH_OF_DL",
                    y=[
                        c
                        for c in df.columns
                        if c != "MONTH_OF_DL"
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


# Row 4: Single Cell
cell_4_1()


def query_5_1() -> str:
    sql_query = r"""
with node_annotations as (
    select
        id,
        file_handle_id,
        annotations:annotations:GSE:value[0] as gse,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            64892175,
            68702804
        )
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.gse
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
        on objectdownload_event.file_handle_id = node_annotations.file_handle_id and
        objectdownload_event.association_object_id = node_annotations.id
)
SELECT
    gse,
    date_trunc('year', record_date) as year_of_download,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) as number_of_unique_users
FROM
    dedup_downloads
GROUP BY
    year_of_download, gse
ORDER BY
    year_of_download DESC, gse DESC NULLS LAST;  """

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
                st.markdown("### Annual downloads per GSE")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_1",
                help="Refresh annual_downloads_per_gse data",
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
    sql_query = r"""
with node_annotations as (
    select
        id,
        file_handle_id,
        annotations:annotations:GSE:value[0] as gse
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            64892175,
            68702804
        )
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.gse
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
        on objectdownload_event.file_handle_id = node_annotations.file_handle_id and
        objectdownload_event.association_object_id = node_annotations.id
)
SELECT
    gse,
    count(*) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) as number_of_unique_users
FROM
    dedup_downloads
GROUP BY
    gse
ORDER BY
    NUMBER_OF_DOWNLOADS DESC
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
                st.markdown("### Number of downloads per GSE")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_1",
                help="Refresh number_of_downloads_per_gse data",
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
with node_annotations as (
    select
        id,
        file_handle_id,
        annotations:annotations:GSE:value[0] as gse
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            64892175,
            68702804
        )
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.gse
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
        on objectdownload_event.file_handle_id = node_annotations.file_handle_id and
        objectdownload_event.association_object_id = node_annotations.id
)
SELECT
    gse,
    count(*) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) as number_of_unique_users
FROM
    dedup_downloads
GROUP BY
    gse
ORDER BY
    NUMBER_OF_DOWNLOADS DESC
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
                st.markdown("### Number of downloads per GSE")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_2",
                help="Refresh number_of_downloads_per_gse data",
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
                    df.groupby(by="GSE", sort=False)
                    .agg(col1=("NUMBER_OF_DOWNLOADS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_DOWNLOADS (sum)"})
                    .reset_index()
                )

                df["/* Order Key (Generated by Snowflake) */"] = df["GSE"]

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["GSE"]):
                    datetime_primary_column = df["GSE"]
                elif df["GSE"].dtype == "object" and isinstance(
                    df["GSE"].get(df["GSE"].first_valid_index()), dt.date
                ):
                    datetime_primary_column = pd.to_datetime(df["GSE"], errors="coerce")
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["GSE"] = df["GSE"].astype("string")

                st.bar_chart(
                    df,
                    x="GSE",
                    y=[
                        c
                        for c in df.columns
                        if c != "GSE"
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
with node_annotations as (
    select
        id,
        file_handle_id,
        annotations:annotations:dataType:value[0] as dataType
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            64892175,
            68702804
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
        on objectdownload_event.file_handle_id = node_annotations.file_handle_id and
        objectdownload_event.association_object_id = node_annotations.id
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
                st.markdown("### Number of downloads per dataType")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_7_1",
                help="Refresh number_of_downloads_per_datatype data",
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
with node_annotations as (
    select
        id,
        file_handle_id,
        annotations:annotations:dataType:value[0] as dataType
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            64892175,
            68702804
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
        on objectdownload_event.file_handle_id = node_annotations.file_handle_id and
        objectdownload_event.association_object_id = node_annotations.id
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
                st.markdown("### Number of downloads per dataType")
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

            # Prepare data for bar chart
            if len(df) > 0:
                df = (
                    df.groupby(by="DATATYPE", sort=False)
                    .agg(col1=("NUMBER_OF_DOWNLOADS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_DOWNLOADS (sum)"})
                    .reset_index()
                )

                df["/* Order Key (Generated by Snowflake) */"] = df["DATATYPE"]

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
                    stack=False,
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


# Footer
st.markdown("---")
st.markdown(
    "*Dashboard loaded: {}*".format(dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
)
