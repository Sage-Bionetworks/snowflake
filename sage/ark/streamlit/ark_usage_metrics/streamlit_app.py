import argparse
import datetime as dt
import pandas as pd
import streamlit as st
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session

# Set page config
st.set_page_config(page_title="ARK Usage Metrics", layout="wide")


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

# Title
st.title("ARK Usage Metrics")
st.markdown(
    '<p style="color: #cc0000; font-size: 0.85rem; margin-top: -0.4rem;">'
    "This app is "
    '<a href="https://github.com/Sage-Bionetworks/snowflake/blob/dev/STREAMLIT.md" target="_blank">managed on Github</a>. '
    "Any local edits will not be retained."
    "</p>",
    unsafe_allow_html=True,
)

# Initialize session configured for generated Streamlit apps
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
select
    min(record_date) as min_dl_date,
    max(record_date) as max_dl_date
from
    synapse_data_warehouse.synapse_event.objectdownload_event
where
    project_id in (
        26710600
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
    sum(content_size) / power(2, 40) AS TOTAL_SIZE_IN_TIB,
    sum(content_size) / power(2, 30) * 0.023 * 12 AS annual_price_estimate
from
    synapse_data_warehouse.synapse.node_latest
inner join
    synapse_data_warehouse.synapse.file_latest
    on node_latest.file_handle_id = file_latest.id
where
    node_latest.project_id in (
        26710600
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
        26710600
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
            26710600
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
            26710600
        )
)
select
    date_trunc('MONTH', RECORD_DATE) AS month_of_dl,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) as number_of_unique_users
FROM
    dedup_downloads
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
                st.dataframe(df, width="stretch", hide_index=True, height=400)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_3_2() -> str:
    sql_query = r"""

with dedup_downloads as (
    select
        record_date, user_id, file_handle_id
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    where
        project_id in (
            26710600
        )
)
select
    date_trunc('MONTH', RECORD_DATE) AS month_of_dl,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) as number_of_unique_users
FROM
    dedup_downloads
GROUP BY
    month_of_dl
ORDER BY
    month_of_dl DESC
    NULLS LAST;
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
                st.markdown("### downloads per month")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_2",
                help="Refresh downloads_per_month data",
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


# Row 3: 2 Cells
col3_1, col3_2 = st.columns(2)
with col3_1:
    cell_3_1()
with col3_2:
    cell_3_2()


def query_4_1() -> str:
    sql_query = r"""
with node_annotations as (
    select
        id,
        file_handle_id,
        annotations:annotations:study:value[0] as study,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            26710600
        )
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.study
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations on
        objectdownload_event.file_handle_id = node_annotations.file_handle_id and
        objectdownload_event.association_object_id = node_annotations.id
)
SELECT
    study,
    date_trunc('year', record_date) as year_of_download,
    count(*) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) as number_of_unique_users
FROM
    dedup_downloads
GROUP BY
    year_of_download, study
ORDER BY
    year_of_download DESC, study DESC NULLS LAST;  """

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
                st.markdown("### Annual downloads per study")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_1",
                help="Refresh annual_downloads_per_study data",
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
with node_annotations as (
    select
        id,
        file_handle_id,
        annotations:annotations:study:value[0] as study
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            26710600
        )
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.study
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations on
        objectdownload_event.file_handle_id = node_annotations.file_handle_id and
        objectdownload_event.association_object_id = node_annotations.id
)
SELECT
    study,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) as number_of_unique_users
FROM
    dedup_downloads
GROUP BY
    study
ORDER BY
    NUMBER_OF_DOWNLOADS DESC
    NULLS LAST;  """

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
                st.markdown("### Number of downloads per study")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_1",
                help="Refresh number_of_downloads_per_study data",
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
with node_annotations as (
    select
        id,
        file_handle_id,
        annotations:annotations:study:value[0] as study
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            26710600
        )
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.study
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations on
        objectdownload_event.file_handle_id = node_annotations.file_handle_id and
        objectdownload_event.association_object_id = node_annotations.id
)
SELECT
    study,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) as number_of_unique_users
FROM
    dedup_downloads
GROUP BY
    study
ORDER BY
    NUMBER_OF_DOWNLOADS DESC
    NULLS LAST;  """

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
                st.markdown("### Number of downloads per study")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_2",
                help="Refresh number_of_downloads_per_study data",
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
                    df.groupby(by="STUDY", sort=False)
                    .agg(col1=("NUMBER_OF_DOWNLOADS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_DOWNLOADS (sum)"})
                    .reset_index()
                )

                df["/* Order Key (Generated by Snowflake) */"] = df["STUDY"]

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["STUDY"]):
                    datetime_primary_column = df["STUDY"]
                elif df["STUDY"].dtype == "object" and isinstance(
                    df["STUDY"].get(df["STUDY"].first_valid_index()), dt.date
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["STUDY"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["STUDY"] = df["STUDY"].astype("string")

                st.bar_chart(
                    df,
                    x="STUDY",
                    y=[
                        c
                        for c in df.columns
                        if c != "STUDY"
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
with node_annotations as (
    select
        id,
        file_handle_id,
        annotations:annotations:dataType:value[0] as dataType
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            26710600
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
        node_annotations on
        objectdownload_event.file_handle_id = node_annotations.file_handle_id and
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
                st.markdown("### Number of downloads per dataType")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_1",
                help="Refresh number_of_downloads_per_datatype data",
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
        annotations:annotations:dataType:value[0] as dataType
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            26710600
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
        node_annotations on
        objectdownload_event.file_handle_id = node_annotations.file_handle_id and
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
                st.markdown("### Number of downloads per dataType")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_2",
                help="Refresh number_of_downloads_per_datatype data",
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


# Row 6: 2 Cells
col6_1, col6_2 = st.columns(2)
with col6_1:
    cell_6_1()
with col6_2:
    cell_6_2()


# Footer
st.markdown("---")
st.markdown(
    "*Dashboard loaded: {}*".format(dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
)
