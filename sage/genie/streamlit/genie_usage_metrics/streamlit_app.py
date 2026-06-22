import datetime as dt
import argparse
import streamlit as st
import pandas as pd
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session

# Set page config
st.set_page_config(page_title="GENIE Usage Metrics", layout="wide")

# Title
st.title("GENIE Usage Metrics")
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
    project_id in (7222066, 27056172)  """

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

-- storage cost
-- SELECT
--     count(*) as number_of_files,
--     sum(dataFileSizeBytes) / power(2, 30) AS TOTAL_SIZE_IN_GB,
--     sum(dataFileSizeBytes) / power(2, 30) * 0.023 * 12 AS PRICE_PER_YEAR
-- FROM
--     SAGE.PORTAL_RAW.GENIE;

select
    count(*) as number_of_files,
    sum(content_size) / power(2, 30) AS TOTAL_SIZE_IN_GiB,
    sum(content_size) / power(2, 30) * 0.023 * 12 AS annual_price_estimate
from
    synapse_data_warehouse.synapse.node_latest
inner join
    synapse_data_warehouse.synapse.file_latest
on
    node_latest.file_handle_id = file_latest.id
where
    node_latest.project_id in (7222066, 27056172)

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
                st.markdown("### Storage summary (GENIE/BPC)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_2",
                help="Refresh storage_summary_(genie/bpc) data",
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
-- SELECT
--     count(RECORD_DATE) as number_of_downloads,
--     count(DISTINCT USER_ID) as number_of_unique_users_downloaded,
--     min(record_date) as earliest_download_record,
--     max(record_date) as latest_download_record
-- FROM
--     sage.portal_downloads.GENIE;


select
    count(RECORD_DATE) as number_of_downloads,
    count(DISTINCT USER_ID) as number_of_unique_users_downloaded
from
    synapse_data_warehouse.synapse_event.objectdownload_event
where
    project_id in (7222066, 27056172)  """

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
                st.markdown("### All time downloads (GENIE/BPC)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_1",
                help="Refresh all_time_downloads_(genie/bpc) data",
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
select
    date_trunc('year', record_date) as year_of_download,
    count(RECORD_DATE) as number_of_downloads,
    count(DISTINCT USER_ID) as number_of_unique_users_downloaded
from
    synapse_data_warehouse.synapse_event.objectdownload_event
where
    project_id in (7222066, 27056172)
group by
   year_of_download
ORDER BY
    year_of_download  """

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
                st.markdown("### Annual unique users downloaded")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_2",
                help="Refresh annual_unique_users_downloaded data",
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

            # Prepare data for bar chart
            if len(df) > 0:
                df = df[["YEAR_OF_DOWNLOAD", "NUMBER_OF_UNIQUE_USERS_DOWNLOADED"]]
                df["NUMBER_OF_UNIQUE_USERS_DOWNLOADED"] = pd.to_numeric(
                    df["NUMBER_OF_UNIQUE_USERS_DOWNLOADED"],
                    errors="coerce",
                ).fillna(0)

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["YEAR_OF_DOWNLOAD"]):
                    datetime_primary_column = df["YEAR_OF_DOWNLOAD"]
                elif df["YEAR_OF_DOWNLOAD"].dtype == "object" and isinstance(
                    df["YEAR_OF_DOWNLOAD"].get(
                        df["YEAR_OF_DOWNLOAD"].first_valid_index()
                    ),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["YEAR_OF_DOWNLOAD"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["YEAR_OF_DOWNLOAD"] = df["YEAR_OF_DOWNLOAD"].astype("string")

                st.bar_chart(
                    df.set_index("YEAR_OF_DOWNLOAD"),
                    sort=True,
                    width="stretch",
                    height=400,
                    stack=False,
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_2_3() -> str:
    sql_query = r"""
WITH nonsage_users AS (
    SELECT
        ID
    FROM
        SYNAPSE_DATA_WAREHOUSE.SYNAPSE.USERPROFILE_LATEST
    WHERE
        EMAIL NOT LIKE '%@sagebase.org' and
        EMAIL NOT LIKE '%@sagebionetworks.org'
)
select
    count(RECORD_DATE) as number_of_downloads,
    count(DISTINCT USER_ID) as number_of_unique_users_downloaded
from
    synapse_data_warehouse.synapse_event.objectdownload_event
inner join
    nonsage_users
    on objectdownload_event.user_id = nonsage_users.id
where
    project_id in (7222066, 27056172)
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
                st.markdown("### All time non-sage downloads (GENIE/BPC)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_3",
                help="Refresh all_time_non-sage_downloads_(genie/bpc) data",
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
with dedup_downloads as (
    select
        objectdownload_event.record_date,
        processedaccess.X_FORWARDED_FOR,
        objectdownload_event.user_id,
        objectdownload_event.file_handle_id
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    join
      synapse_data_warehouse.synapse_event.access_event processedaccess
        on objectdownload_event.session_id = processedaccess.session_id
    where
        objectdownload_event.project_id in (7222066, 27056172)
)
SELECT
    country_name,
    date_trunc('year', record_date) as year_of_download,
    count(*) as number_of_downloads,
    count(distinct user_id) as number_of_users
FROM
    dedup_downloads
JOIN TABLE(IP_INFO.PUBLIC.IP_COUNTRY_DETAILS(dedup_downloads.X_FORWARDED_FOR))
group by
    country_name,
    year_of_download
ORDER BY
    YEAR_OF_DOWNLOAD DESC, NUMBER_OF_DOWNLOADS DESC;  """

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
                st.markdown("### Location of downloads")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_1",
                help="Refresh location_of_downloads data",
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
with node_annotations as (
    select
        id,
        annotations:annotations:cohort:value[0] as cohort,
        annotations:annotations:consortium:value[0] as consortium,
        annotations:annotations:version:value[0] as version
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (7222066, 27056172) and
        consortium = 'GENIE-BPC'
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.version,
        node_annotations.cohort
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
        on objectdownload_event.association_object_id = node_annotations.id
)
SELECT
    cohort || ' ' || version as cohort_release,
    YEAR(record_date) as year_of_download,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) as number_of_unique_users
FROM
    dedup_downloads
GROUP BY
    year_of_download, cohort_release
ORDER BY
    year_of_download DESC, cohort_release DESC NULLS LAST;
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
                st.markdown("### Annual downloads in BPC GENIE")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_1",
                help="Refresh annual_downloads_in_bpc_genie data",
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
                st.dataframe(df, width="stretch", hide_index=True, height=400)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_4_2() -> str:
    sql_query = r"""
with node_annotations as (
    select
        id,
        annotations:annotations:cohort:value[0] as cohort,
        annotations:annotations:consortium:value[0] as consortium,
        annotations:annotations:version:value[0] as version
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (7222066, 27056172) and
        consortium = 'GENIE' and
        version is not null
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.version
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
        on objectdownload_event.association_object_id = node_annotations.id
)
SELECT
    version,
    YEAR(record_date) as year_of_download,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) as number_of_unique_users
FROM
    dedup_downloads
GROUP BY
    year_of_download, version
ORDER BY
    year_of_download DESC, version DESC NULLS LAST;
  """

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
                st.markdown("### Annual Downloads in main GENIE")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_2",
                help="Refresh annual_downloads_in_main_genie data",
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


# Row 4: 2 Cells
col4_1, col4_2 = st.columns(2)
with col4_1:
    cell_4_1()
with col4_2:
    cell_4_2()


def query_5_1() -> str:
    sql_query = r"""
with dedup_downloads as (
    select
        record_date, user_id, file_handle_id
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    where
        project_id in (7222066, 27056172)
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
                st.markdown("### downloads per month (BPC/GENIE)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_1",
                help="Refresh downloads_per_month_(bpc/genie) data",
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
with dedup_downloads as (
    select
        record_date, user_id, file_handle_id
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    where
        project_id in (7222066, 27056172)
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
                st.markdown("### downloads per month (BPC/GENIE)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_2",
                help="Refresh downloads_per_month_(bpc/genie) data",
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
        annotations:annotations:cohort:value[0] as cohort,
        annotations:annotations:consortium:value[0] as consortium,
        annotations:annotations:version:value[0] as version
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (7222066, 27056172) and
        consortium = 'GENIE' and
        version is not null
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.version
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
        on objectdownload_event.association_object_id = node_annotations.id
)
SELECT
    date_trunc('MONTH', RECORD_DATE) AS MONTH_of_dl,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS
FROM
    dedup_downloads
GROUP BY
    MONTH_of_dl
ORDER BY
    MONTH_of_dl DESC
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
                st.markdown("### downloads per month (main GENIE)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_1",
                help="Refresh downloads_per_month_(main_genie) data",
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


# Row 6: Single Cell
cell_6_1()


def query_7_1() -> str:
    sql_query = r"""
with node_annotations as (
    select
        id,
        annotations:annotations:cohort:value[0] as cohort,
        annotations:annotations:consortium:value[0] as consortium,
        annotations:annotations:version:value[0] as version
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (7222066, 27056172) and
        consortium = 'GENIE' and
        version is not null
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.version
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
        on objectdownload_event.association_object_id = node_annotations.id
)
SELECT
    version,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) as number_of_unique_users
FROM
    dedup_downloads
GROUP BY
    version
ORDER BY
    version DESC
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
                st.markdown("### Number of downloads per main GENIE release")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_7_1",
                help="Refresh number_of_downloads_per_main_genie_release data",
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
        annotations:annotations:cohort:value[0] as cohort,
        annotations:annotations:consortium:value[0] as consortium,
        annotations:annotations:version:value[0] as version
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (7222066, 27056172) and
        consortium = 'GENIE' and
        version is not null
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.version
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
        on objectdownload_event.association_object_id = node_annotations.id
)
SELECT
    version,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) as number_of_unique_users
FROM
    dedup_downloads
GROUP BY
    version
ORDER BY
    version DESC
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
                st.markdown("### Number of downloads per main GENIE release")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_7_2",
                help="Refresh number_of_downloads_per_main_genie_release data",
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
                    df.groupby(by="VERSION", sort=False)
                    .agg(col1=("NUMBER_OF_DOWNLOADS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_DOWNLOADS (sum)"})
                    .reset_index()
                )

                df["/* Order Key (Generated by Snowflake) */"] = df["VERSION"]

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["VERSION"]):
                    datetime_primary_column = df["VERSION"]
                elif df["VERSION"].dtype == "object" and isinstance(
                    df["VERSION"].get(df["VERSION"].first_valid_index()), dt.date
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["VERSION"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["VERSION"] = df["VERSION"].astype("string")

                st.bar_chart(
                    df,
                    x="VERSION",
                    y=[
                        c
                        for c in df.columns
                        if c != "VERSION"
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


# Row 7: 2 Cells
col7_1, col7_2 = st.columns(2)
with col7_1:
    cell_7_1()
with col7_2:
    cell_7_2()


def query_8_1() -> str:
    sql_query = r"""
with node_annotations as (
    select
        id,
        annotations:annotations:cohort:value[0] as cohort,
        annotations:annotations:consortium:value[0] as consortium,
        annotations:annotations:version:value[0] as version
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (7222066, 27056172) and
        consortium = 'GENIE-BPC'
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.version,
        node_annotations.cohort
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
        on objectdownload_event.association_object_id = node_annotations.id
)
SELECT
  cohort || ' ' || version as cohort_version,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
    count(distinct user_id) AS UNIQUE_USERS

FROM
    dedup_downloads
GROUP BY
  cohort_version
ORDER BY
  cohort_version DESC
    NULLS LAST;  """

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
                st.markdown("### Number of downloads per BPC GENIE release")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_8_1",
                help="Refresh number_of_downloads_per_bpc_genie_release data",
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
                st.dataframe(df, width="stretch", hide_index=True, height=400)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_8_2() -> str:
    sql_query = r"""
with node_annotations as (
    select
        id,
        annotations:annotations:cohort:value[0] as cohort,
        annotations:annotations:consortium:value[0] as consortium,
        annotations:annotations:version:value[0] as version
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (7222066, 27056172) and
        consortium = 'GENIE-BPC'
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.version,
        node_annotations.cohort
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
        on objectdownload_event.association_object_id = node_annotations.id
)
SELECT
  cohort || ' ' || version as cohort_version,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
  count(distinct user_id) AS UNIQUE_USERS

FROM
    dedup_downloads
GROUP BY
  cohort_version
ORDER BY
  cohort_version DESC
    NULLS LAST;  """

    return sql_query


execute_query(query_8_2())


@st.fragment
def cell_8_2():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Number of downloads per BPC GENIE release")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_8_2",
                help="Refresh number_of_downloads_per_bpc_genie_release data",
            ):
                execute_query.clear(query_8_2())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_8_2())).result(
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
                df = df[["COHORT_VERSION", "NUMBER_OF_DOWNLOADS"]]

                df["/* Order Key (Generated by Snowflake) */"] = df["COHORT_VERSION"]

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["COHORT_VERSION"]):
                    datetime_primary_column = df["COHORT_VERSION"]
                elif df["COHORT_VERSION"].dtype == "object" and isinstance(
                    df["COHORT_VERSION"].get(df["COHORT_VERSION"].first_valid_index()),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["COHORT_VERSION"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["COHORT_VERSION"] = df["COHORT_VERSION"].astype("string")

                st.bar_chart(
                    df,
                    x="COHORT_VERSION",
                    y=[
                        c
                        for c in df.columns
                        if c != "COHORT_VERSION"
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


# Row 8: 2 Cells
col8_1, col8_2 = st.columns(2)
with col8_1:
    cell_8_1()
with col8_2:
    cell_8_2()


def query_9_1() -> str:
    sql_query = r"""
with node_annotations as (
    select
        id,
        annotations:annotations:cohort:value[0] as cohort,
        annotations:annotations:consortium:value[0] as consortium,
        annotations:annotations:version:value[0] as version
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (7222066, 27056172) and
        consortium = 'GENIE-BPC'
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.version,
        node_annotations.cohort
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
        on objectdownload_event.association_object_id = node_annotations.id
)
SELECT
    date_trunc('MONTH', record_date) as MONTH_of_dl,
  count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS

FROM
    dedup_downloads
GROUP BY
  MONTH_of_dl
ORDER BY
    MONTH_of_dl DESC
    NULLS LAST;  """

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
                st.markdown("### downloads per month in BPC GENIE")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_9_1",
                help="Refresh downloads_per_month_in_bpc_genie data",
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
with node_annotations as (
    select
        id,
        annotations:annotations:cohort:value[0] as cohort,
        annotations:annotations:consortium:value[0] as consortium,
        annotations:annotations:version:value[0] as version
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (7222066, 27056172) and
        consortium = 'GENIE-BPC'
), dedup_downloads as (
    select
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.version,
        node_annotations.cohort
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
        on objectdownload_event.association_object_id = node_annotations.id
)
SELECT
    date_trunc('MONTH', record_date) as MONTH_of_dl,
  count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS

FROM
    dedup_downloads
GROUP BY
  MONTH_of_dl
ORDER BY
    MONTH_of_dl DESC
    NULLS LAST;  """

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
                st.markdown("### downloads per month in BPC GENIE")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_9_2",
                help="Refresh downloads_per_month_in_bpc_genie data",
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

            # Prepare data for bar chart
            if len(df) > 0:
                df = df[["MONTH_OF_DL", "NUMBER_OF_DOWNLOADS"]]

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
                    x_label="# downloads",
                    y_label="month",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 9: 2 Cells
col9_1, col9_2 = st.columns(2)
with col9_1:
    cell_9_1()
with col9_2:
    cell_9_2()


def query_10_1() -> str:
    sql_query = r"""
with node_annotations as (
    select
        id,
        annotations:annotations:cohort:value[0] as cohort,
        annotations:annotations:consortium:value[0] as consortium,
        annotations:annotations:version:value[0] as version
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (7222066, 27056172) and
        consortium = 'GENIE-BPC'
), dedup_downloads as (
    select
        objectdownload_event.user_id,
            objectdownload_event.record_date,
        objectdownload_event.file_handle_id,
        node_annotations.version,
        node_annotations.cohort
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    inner join
        node_annotations
        on objectdownload_event.association_object_id = node_annotations.id
)
SELECT
    date_trunc('MONTH', RECORD_DATE) AS MONTH_of_dls,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS
FROM
    dedup_downloads
GROUP BY
    MONTH_of_dls
ORDER BY
    MONTH_of_dls DESC
    NULLS LAST;



-- -- Distribution of downloads over months
-- SELECT
--     date_trunc('MONTH', RECORD_DATE) AS MONTH,
--     count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS
-- FROM
--     SAGE.PORTAL_DOWNLOADS.GENIE
-- WHERE
--     consortium = 'GENIE-BPC'
-- GROUP BY
--     MONTH
-- ORDER BY
--     MONTH DESC
--     NULLS LAST;
  """

    return sql_query


execute_query(query_10_1())


@st.fragment
def cell_10_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### downloads per month (BPC)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_10_1",
                help="Refresh downloads_per_month_(bpc) data",
            ):
                execute_query.clear(query_10_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_10_1())).result(
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
                    df.groupby(by="MONTH_OF_DLS", sort=False)
                    .agg(col1=("NUMBER_OF_DOWNLOADS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_DOWNLOADS (sum)"})
                    .reset_index()
                )

                df["/* Order Key (Generated by Snowflake) */"] = df["MONTH_OF_DLS"]

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["MONTH_OF_DLS"]):
                    datetime_primary_column = df["MONTH_OF_DLS"]
                elif df["MONTH_OF_DLS"].dtype == "object" and isinstance(
                    df["MONTH_OF_DLS"].get(df["MONTH_OF_DLS"].first_valid_index()),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["MONTH_OF_DLS"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["MONTH_OF_DLS"] = df["MONTH_OF_DLS"].astype("string")

                st.bar_chart(
                    df,
                    x="MONTH_OF_DLS",
                    y=[
                        c
                        for c in df.columns
                        if c != "MONTH_OF_DLS"
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


# Row 10: Single Cell
cell_10_1()


def query_11_1() -> str:
    sql_query = r"""
-- Compute download metrics for cohort/release combinations.
-- SQL Mental model: Treat each cohort folder as a root. For every release folder beneath it,
-- aggregate total download and distinct user download counts subtree across its child objects
-- Emit one row per cohort/release.

-- Query for all nodes under the consortium (release) folders
-- Consortium folders exist under cohort folders, i.e., cohort > consortium
WITH RECURSIVE release_nodes_raw (id, root_parent_id) AS (
    SELECT
        id,
        parent_id AS root_parent_id
    FROM
      synapse_data_warehouse.synapse.node_latest
    WHERE
        -- These are our "cohort" folders
        parent_id IN (
            26288991,
            50612194,
            26471040,
            50612195,
            24981908,
            32298950,
            26958248,
            53018640,
            54107363,
            63996092
        )
    UNION ALL
    SELECT
        snl.id,
        rnr.root_parent_id
    FROM
        synapse_data_warehouse.synapse.node_latest snl
        JOIN release_nodes_raw rnr ON snl.parent_id = rnr.id
),
-- KEEP THIS. Don't pushdown recursive join
release_nodes AS (
    SELECT
        DISTINCT id,
        root_parent_id
    FROM
        release_nodes_raw
),
-- We need to derive these counts from the  objectdownload_event table,
-- rather than objectdownload_aggregate, since the latter provides object
-- download aggregates, whereas we want object *set* download aggregates
download_count AS (
    SELECT
        rn.root_parent_id,
        COUNT(*) AS downloads,
        COUNT(DISTINCT ode.user_id) AS unique_user_downloads
    FROM
        release_nodes rn
        JOIN synapse_data_warehouse.synapse_event.objectdownload_event ode ON ode.association_object_id = rn.id
    GROUP BY
        rn.root_parent_id
),
-- Cohort and consortium folder names
root_info AS (
    SELECT
        root.id AS root_parent_id,
        root.name AS root_parent_name,
        parent.name AS parent_of_root_name
    FROM
        synapse_data_warehouse.synapse.node_latest root
        LEFT JOIN synapse_data_warehouse.synapse.node_latest parent ON parent.id = root.parent_id
)
SELECT
    ri.parent_of_root_name AS cohort,
    ri.root_parent_name AS release,
    dc.root_parent_id AS release_folder_id,
    dc.downloads,
    dc.unique_user_downloads
FROM
    download_count dc
    JOIN root_info ri ON ri.root_parent_id = dc.root_parent_id
ORDER BY
    cohort,
    release;  """

    return sql_query


execute_query(query_11_1())


@st.fragment
def cell_11_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### All-Time Downloads per BPC private consortium release")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_11_1",
                help="Refresh all-time_downloads_per_bpc_private_consortium_release data",
            ):
                execute_query.clear(query_11_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_11_1())).result(
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


# Row 11: Single Cell
cell_11_1()


def query_12_1() -> str:
    sql_query = r"""
select
    title, number_of_citations, authors, publication_year, venue, publication_url, 
from
    sage.citations.genie_google_scholar
order by
    number_of_citations DESC
limit 10;
"""

    return sql_query


execute_query(query_12_1())


@st.fragment
def cell_12_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### top 10 cited papers [Not Curated]")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_12_1",
                help="Refresh top_10_cited_papers_[not_curated] data",
            ):
                execute_query.clear(query_12_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_12_1())).result(
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


# Row 12: Single Cell
cell_12_1()


def query_13_1() -> str:
    sql_query = r"""
with node_annotations as (
    select
        id,
        annotations:annotations:cohort:value[0] as cohort,
        annotations:annotations:consortium:value[0] as consortium,
        annotations:annotations:version:value[0] as version
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (7222066, 27056172)

)
select
    consortium || '-' || cohort || '-' || version as cohort_version,
    count(*) as number_of_files
from
    node_annotations
where
    cohort_version is not null
group by
    cohort_version
ORDER BY
    cohort_version
  """

    return sql_query


execute_query(query_13_1())


@st.fragment
def cell_13_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Storage summary (GENIE/BPC)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_13_1",
                help="Refresh storage_summary_(genie/bpc) data",
            ):
                execute_query.clear(query_13_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_13_1())).result(
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
                df = df[["COHORT_VERSION", "NUMBER_OF_FILES"]]

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["COHORT_VERSION"]):
                    datetime_primary_column = df["COHORT_VERSION"]
                elif df["COHORT_VERSION"].dtype == "object" and isinstance(
                    df["COHORT_VERSION"].get(df["COHORT_VERSION"].first_valid_index()),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["COHORT_VERSION"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["COHORT_VERSION"] = df["COHORT_VERSION"].astype("string")

                st.bar_chart(
                    df.set_index("COHORT_VERSION"),
                    sort=True,
                    width="stretch",
                    height=400,
                    horizontal=True,
                    stack=False,
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


# Row 13: Single Cell
cell_13_1()


# Footer
st.markdown("---")
st.markdown(
    "*Dashboard loaded: {}*".format(dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
)
