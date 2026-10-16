import argparse
import datetime as dt
import streamlit as st
import pandas as pd
from snowflake.snowpark import Session
import snowflake.snowpark.context as snowpark_context

# Set page config
st.set_page_config(page_title="ADKP Metrics", layout="wide")

# Title
st.title("ADKP Metrics")
st.markdown(
    '<p style="color: #cc0000; font-size: 0.85rem; margin-top: -0.4rem;">'
    "This app is "
    '<a href="https://github.com/Sage-Bionetworks/snowflake/blob/dev/STREAMLIT.md" target="_blank">managed on Github</a>. '
    "Any local edits will not be retained."
    "</p>",
    unsafe_allow_html=True,
)


# Initialize session configured for local dev and Streamlit in Snowflake
def read_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--local-dev", action="store_true")
    return parser.parse_args()


def get_session(local_dev: bool) -> Session:
    if local_dev:
        return Session.builder.config("connection_name", "default").create()
    return snowpark_context.get_active_session()


args = read_args()
session = get_session(args.local_dev)
try:
    session.query_tag = "__generated_streamlit"
except Exception:
    pass

# Date buckets available in SYNAPSE_AGGREGATE.OBJECTDOWNLOAD_AGGREGATE (AGG_PERIOD values)
AGGREGATE_PERIODS = {
    "Day": "DAILY",
    "Month": "MONTHLY",
    "Quarter": "QUARTERLY",
    "Year": "YEARLY",
}

# Earliest record in objectdownload_event for the ADKP project
DEFAULT_WINDOW_START = dt.date(2022, 1, 1)

# Parameter input widgets arranged in a row
(param_col_1,) = st.columns(1)

with param_col_1:
    # Widgets in a form only take effect when the form is submitted, so the charts
    # don't re-query on every change
    with st.form("params_form", border=False):
        # Parameter: datewindow
        st.markdown("**Date window**")
        st.markdown(
            "For charts which group results by time period, this property restricts "
            "results to the periods between the selected start and end dates. "
            "Start dates are rounded down and end dates rounded up in charts which "
            "bucket their data by the date bucket."
        )
        input_datewindow = st.date_input(
            "Date window",
            value=(DEFAULT_WINDOW_START, dt.date.today()),
            max_value=dt.date.today(),
            label_visibility="collapsed",
            key="datewindow_param",
        )

        # Parameter: datebucket
        st.markdown("**Date bucket**")
        st.markdown(
            "For charts which group results by time period, this property configures "
            "which time period those results are bucketed by."
        )
        input_datebucket = st.selectbox(
            "Date bucket",
            options=list(AGGREGATE_PERIODS),
            index=3,
            label_visibility="collapsed",
            key="datebucket_param",
        )

        st.form_submit_button("Update", type="primary")

# A range picker returns one date until the user has chosen both ends
if len(input_datewindow) != 2:
    st.warning("Select both a start and an end date for the date window, then click Update.")
    st.stop()
window_start, window_end = input_datewindow


def bucket_floor(d: dt.date, bucket: str) -> dt.date:
    if bucket == "Month":
        return d.replace(day=1)
    if bucket == "Quarter":
        return d.replace(month=3 * ((d.month - 1) // 3) + 1, day=1)
    if bucket == "Year":
        return d.replace(month=1, day=1)
    return d


def bucket_end(d: dt.date, bucket: str) -> dt.date:
    # Last day of the bucket period containing d
    start = bucket_floor(d, bucket)
    months = {"Month": 1, "Quarter": 3, "Year": 12}.get(bucket)
    if months is None:
        return start
    next_month = start.month - 1 + months
    next_start = start.replace(year=start.year + next_month // 12, month=next_month % 12 + 1)
    return next_start - dt.timedelta(days=1)


def window_filter_sql(column: str) -> str:
    # Keeps whole date-bucket periods: from the period containing the start date
    # through the period containing the end date
    return (
        f"{column} >= date_trunc('{input_datebucket}', '{window_start}'::date) "
        f"and {column} < dateadd('{input_datebucket}', 1, "
        f"date_trunc('{input_datebucket}', '{window_end}'::date))"
    )


st.markdown("---")


MAX_METRIC_COLUMNS = 4


def format_metric_value(value, compact: bool = False) -> str:
    if pd.isna(value):
        return "—"
    if isinstance(value, (int, float)):
        if compact and abs(value) >= 1e9:
            return f"{value / 1e9:,.2f}B"
        if compact and abs(value) >= 1e6:
            return f"{value / 1e6:,.2f}M"
        if compact and abs(value) >= 1e3:
            return f"{value:,.0f}"
        return f"{value:,.2f}".rstrip("0").rstrip(".") if value % 1 else f"{value:,.0f}"
    return str(value)


def render_dataframe(df: pd.DataFrame, height=400) -> None:
    # A single-row result reads better as metric cards than as a mostly empty table
    if len(df) == 1 and len(df.columns) <= MAX_METRIC_COLUMNS:
        for col, (name, value) in zip(st.columns(len(df.columns)), df.iloc[0].items()):
            # Fixed-height caption keeps values aligned when labels wrap differently;
            # large values are abbreviated to avoid truncation, with the full value as help text
            with col.container(height=50, border=False):
                st.caption(name.replace("_", " "))
            if isinstance(value, (int, float)):
                col.metric(
                    label=name,
                    value=format_metric_value(value, compact=True),
                    help=format_metric_value(value),
                    label_visibility="collapsed",
                )
            else:
                # Text and dates are wider than numbers; st.metric would truncate them
                col.markdown(f"#### {format_metric_value(value)}")
    else:
        st.dataframe(df, width="stretch", hide_index=True, height=height)


@st.cache_data(ttl="23h50m")
def execute_query(query: str) -> str:
    return session.sql(query).collect_nowait().query_id


def query_1_2() -> str:
    sql_query = rf"""

    SELECT
        count(distinct(FILE_LATEST.ID)) as TOTAL_FILES,
        round(sum(FILE_LATEST.CONTENT_SIZE) / power(2, 40), 2) AS TOTAL_SIZE_IN_TB
        -- round(sum(FILE_LATEST.CONTENT_SIZE) / power(2, 30) * 0.023 * 12, 2) AS PRICE_PER_YEAR
    FROM
        SYNAPSE_DATA_WAREHOUSE.SYNAPSE.FILE_LATEST
    join
        synapse_data_warehouse.synapse.node_latest
        on file_latest.id = node_latest.file_handle_id
    where
        node_latest.project_id = 2580853
        and {window_filter_sql('node_latest.created_on')}  """

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
                st.markdown("### Portal Summary - files, volume, storage cost")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_2",
                help="Refresh portal_summary_-_files,_volume,_storage_cost data",
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

            render_dataframe(df)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_1_3() -> str:
    sql_query = rf"""

SELECT
    node_latest.annotations:annotations:dataType:value as datatype,
    count(*) as number_of_files,
    sum(file_latest.content_size) / power(2, 30) as size_in_gib
    -- round(sum(FILE_LATEST.CONTENT_SIZE) / power(2, 30) * 0.023 * 12, 2) AS PRICE_PER_YEAR
FROM
    SYNAPSE_DATA_WAREHOUSE.SYNAPSE.FILE_LATEST
join
    synapse_data_warehouse.synapse.node_latest
    on file_latest.id = node_latest.file_handle_id
where
    node_latest.project_id = 2580853
    and {window_filter_sql('node_latest.created_on')}
group by
    datatype  """

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
                st.markdown("### Portal Summary - data type distribution")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_3",
                help="Refresh portal_summary_-_data_type_distribution data",
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

            render_dataframe(df)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_2_1() -> str:
    sql_query = rf"""
with dedup_downloads as (
    select
        user_id, record_date, file_handle_id
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    where project_id = 2580853
        and {window_filter_sql('record_date')}
), file_size as(
    select
        id,
        content_size  
    from synapse_data_warehouse.synapse.file_latest
)
select
    count(*) AS number_of_downloads,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    round(sum(file_size.content_size) / power(2, 50), 2) AS PB_downloaded
from
    dedup_downloads
left join
    file_size
    on dedup_downloads.file_handle_id = file_size.id
;
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
                st.markdown("### Total downloads")
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

            render_dataframe(df)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_2_2() -> str:
    sql_query = rf"""
with dedup_downloads as (
    select
        user_id, record_date, file_handle_id, 
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    where project_id = 2580853
        and {window_filter_sql('record_date')}
), external_users as (
    select id as user_id
    from
        synapse_data_warehouse.synapse.userprofile_latest
    where
        email not ilike '%@sagebase.org' and email not ilike '%sagebionetworks.org'

), file_size as(
    select
        id,
        content_size  
    from synapse_data_warehouse.synapse.file_latest
)
select
    count(*) AS number_of_downloads,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    round(sum(file_size.content_size) / power(2, 50), 2) AS PB_downloaded
from
    dedup_downloads
inner join
    external_users
    on dedup_downloads.user_id = external_users.user_id
left join
    file_size
    on dedup_downloads.file_handle_id = file_size.id
;  """

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
                st.markdown("### Total downloads (non-Sagers)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_2",
                help="Refresh all_time_downloads_(non-sagers) data",
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

            render_dataframe(df)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_downloads_aggregate() -> str:
    # Project-level downloads and unique users, pre-aggregated at the selected bucket
    sql_query = f"""
select
    agg_period_start as BUCKET_START,
    download_event_count as NUMBER_OF_DOWNLOADS,
    user_download_count as UNIQUE_USERS
from
    synapse_data_warehouse.synapse_aggregate.objectdownload_aggregate
where
    agg_project_id = 2580853
    and agg_level = 'PROJECT'
    and agg_period = '{AGGREGATE_PERIODS[input_datebucket]}'
    and {window_filter_sql('agg_period_start')}
order by
    agg_period_start desc;  """

    return sql_query


def query_downloads_volume() -> str:
    # The aggregate table has no size column, so volume comes from the event table
    expr_datebucket = f"DATE_TRUNC('{input_datebucket}', RECORD_DATE)"

    sql_query = rf"""
select
    {expr_datebucket} as BUCKET_START,
    round(sum(file_latest.content_size) / power(2, 40), 2) as TB_DOWNLOADED
from
    synapse_data_warehouse.synapse_event.objectdownload_event
join
    synapse_data_warehouse.synapse.file_latest
    on objectdownload_event.file_handle_id = file_latest.id
where
    project_id = 2580853
    and {window_filter_sql('record_date')}
group by
    BUCKET_START
order by
    BUCKET_START desc
    nulls last;  """

    return sql_query


execute_query(query_downloads_aggregate())
execute_query(query_downloads_volume())


@st.fragment
def downloads_over_time_cell(
    key: str,
    query_fn,
    value_column: str,
    title: str,
    color: str | None = None,
    title_suffix: str = "",
) -> None:
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown(f"### {title} per {input_datebucket.lower()}{title_suffix}")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_{key}",
                help=f"Refresh {key} data",
            ) and (color is None or input_studies):
                execute_query.clear(query_fn())

        try:
            if color is not None and not input_studies:
                st.info("Select at least one study.")
                return

            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_fn())).result(
                    "pandas"
                )

            if len(df) > 0:
                df = df[
                    ["BUCKET_START", value_column] + ([color] if color else [])
                ].copy()
                df["BUCKET_START"] = pd.to_datetime(df["BUCKET_START"])
                st.line_chart(
                    df,
                    x="BUCKET_START",
                    y=value_column,
                    color=color,
                    x_label=input_datebucket,
                    width="stretch",
                    height=400,
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def cell_downloads_count() -> None:
    downloads_over_time_cell(
        "downloads_count",
        query_downloads_aggregate,
        "NUMBER_OF_DOWNLOADS",
        "Number of downloads",
    )


def cell_downloads_users() -> None:
    downloads_over_time_cell(
        "downloads_users", query_downloads_aggregate, "UNIQUE_USERS", "Unique users"
    )


def cell_downloads_volume() -> None:
    downloads_over_time_cell(
        "downloads_volume",
        query_downloads_volume,
        "TB_DOWNLOADED",
        "Data volume downloaded (TB)",
    )


STUDY_NODES_CTE = """
study_node as (
    select
        id,
        file_handle_id,
        annotations:annotations:study:value[0]::string as study
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id = 2580853
)"""


def query_study_options() -> str:
    # Studies ordered by all-time downloads so the most active ones are listed first
    sql_query = f"""
with {STUDY_NODES_CTE}
select
    study_node.study as STUDY
from
    synapse_data_warehouse.synapse_aggregate.objectdownload_aggregate as agg
join
    study_node on agg.agg_object_id = study_node.id
where
    agg.agg_project_id = 2580853
    and agg.agg_level = 'OBJECT WITHIN PROJECT'
    and agg.agg_period = 'ALL TIME'
    and study_node.study is not null
group by
    study_node.study
order by
    sum(agg.download_event_count) desc, study_node.study;  """

    return sql_query


DATATYPE_NODES_CTE = """
datatype_node as (
    select
        id,
        annotations:annotations:dataType:value[0]::string as datatype
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id = 2580853
)"""


def query_datatype_options() -> str:
    # Datatypes ordered by all-time downloads so the most popular ones are listed first
    sql_query = f"""
with {DATATYPE_NODES_CTE}
select
    datatype_node.datatype as DATATYPE
from
    synapse_data_warehouse.synapse_aggregate.objectdownload_aggregate as agg
join
    datatype_node on agg.agg_object_id = datatype_node.id
where
    agg.agg_project_id = 2580853
    and agg.agg_level = 'OBJECT WITHIN PROJECT'
    and agg.agg_period = 'ALL TIME'
    and datatype_node.datatype is not null
group by
    datatype_node.datatype
order by
    sum(agg.download_event_count) desc, datatype_node.datatype;  """

    return sql_query


def sql_in_list(studies: list[str]) -> str:
    return ", ".join("'" + study.replace("'", "''") + "'" for study in studies)


def query_study_downloads() -> str:
    # Non-Sage downloads, users, and volume per study from the event table (the
    # aggregate has no user detail, so it can't exclude Sage staff).
    # Join on the entity id (not file_handle_id): entities get new file handles when
    # re-versioned, so a file_handle_id join drops most historical downloads.
    expr_datebucket = f"DATE_TRUNC('{input_datebucket}', RECORD_DATE)"

    sql_query = f"""
with {STUDY_NODES_CTE}, external_users as (
    select
        id as user_id
    from
        synapse_data_warehouse.synapse.userprofile_latest
    where
        email not ilike '%@sagebase.org' and email not ilike '%sagebionetworks.org'
)
select
    {expr_datebucket} as BUCKET_START,
    study_node.study as STUDY,
    count(*) as NUMBER_OF_DOWNLOADS,
    count(distinct objectdownload_event.user_id) as UNIQUE_USERS,
    round(sum(file_latest.content_size) / power(2, 40), 3) as TB_DOWNLOADED
from
    synapse_data_warehouse.synapse_event.objectdownload_event
join
    study_node on objectdownload_event.association_object_id = study_node.id
join
    external_users on objectdownload_event.user_id = external_users.user_id
left join
    synapse_data_warehouse.synapse.file_latest
    on objectdownload_event.file_handle_id = file_latest.id
where
    objectdownload_event.project_id = 2580853
    and study_node.study in ({sql_in_list(input_studies)})
    and {window_filter_sql('objectdownload_event.record_date')}
group by
    BUCKET_START, STUDY
order by
    BUCKET_START desc, STUDY;  """

    return sql_query


def cell_study_downloads_count() -> None:
    downloads_over_time_cell(
        "study_downloads_count",
        query_study_downloads,
        "NUMBER_OF_DOWNLOADS",
        "Number of downloads by study,",
        color="STUDY",
        title_suffix=" (non-Sagers)",
    )


def cell_study_downloads_users() -> None:
    downloads_over_time_cell(
        "study_downloads_users",
        query_study_downloads,
        "UNIQUE_USERS",
        "Unique users by study,",
        color="STUDY",
        title_suffix=" (non-Sagers)",
    )


def cell_study_downloads_volume() -> None:
    downloads_over_time_cell(
        "study_downloads_volume",
        query_study_downloads,
        "TB_DOWNLOADED",
        "Data volume downloaded (TB) by study,",
        color="STUDY",
        title_suffix=" (non-Sagers)",
    )


def query_4_1() -> str:
    sql_query = rf"""
with individuals as (
    select
        annotations:annotations:individualID:value as individualID,
        annotations:annotations:species:value[0] as species
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
        )
        and {window_filter_sql('created_on')}
)
select
    case 
        when grouping(species) = 1 then 'Total'
        else species
    end species,
    count(distinct individualID)
from
    individuals
where individualID is not null
group by 
    rollup(species)
order by count(distinct individualID) desc;  """

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
                st.markdown("### unique individuals from annotations")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_1",
                help="Refresh unique_individuals_from_annotations data",
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

            render_dataframe(df)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_4_2() -> str:
    sql_query = rf"""
with specimens as (
    select
        annotations:annotations:specimenID:value as specimenID,
        annotations:annotations:species:value[0] as species
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
        )
        and {window_filter_sql('created_on')}
)
select
    case 
        when grouping(species) = 1 then 'Total'
        else species
    end species,
    count(distinct specimenID)
from
    specimens
where
    specimenID is not null
group by 
    rollup(species)
order by
    count(distinct specimenID) desc;  """

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
                st.markdown("### unique specimens from annotations")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_2",
                help="Refresh unique_specimens_from_annotations data",
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

            render_dataframe(df)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_6_1() -> str:
    sql_query = rf"""

--- Excludes files labelled "resouceType = metadata" to avoid miscounting files annotated with multiple studies

with node_annotations as (
    select
        id,
        file_handle_id,
        annotations:annotations:dataType:value[0]::string as dataType,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
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
    on
        objectdownload_event.association_object_id = node_annotations.id
    where
        {window_filter_sql('objectdownload_event.record_date')}
), external_users as (
    select
        id as user_id
    from
        synapse_data_warehouse.synapse.userprofile_latest
    where
        email not ilike '%@sagebase.org' and email not ilike '%sagebionetworks.org'

), file_size as(
    select
        id,
        content_size  
    from synapse_data_warehouse.synapse.file_latest
)
select
    dataType,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    count(record_date) AS number_of_downloads,
    round(sum(file_size.content_size) / power(2, 30), 2) AS GiB_downloaded
from
    dedup_downloads
inner join
    external_users
    on dedup_downloads.user_id = external_users.user_id
left join
    file_size
    on dedup_downloads.file_handle_id = file_size.id
where
    dataType is not null
    and dataType in ({sql_in_list(input_datatypes)})
group by
    dataType
order by
    number_of_unique_users desc, dataType desc
-- ;


-- SELECT
--     datatype,
--     COUNT(RECORD_DATE) as number_downloads,
--     count(distinct USER_ID) distinct_users_downloading,
--     count(distinct id) as total_files,
--     number_downloads/total_files as mean_downloads_per_file
-- FROM
--     SAGE.PORTAL_DOWNLOADS.AD
-- WHERE
--     resourceType != 'metadata' AND datatype != '[]' AND NOT datatype LIKE '%,%'
-- GROUP BY
--     datatype
-- ORDER BY
--     distinct_users_downloading DESC;  """

    return sql_query



@st.fragment
def cell_6_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Total downloads by datatype (non-Sagers)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_1",
                help="Refresh total_downloads_by_datatype_(non-sagers) data",
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
                    df.groupby(by="DATATYPE", sort=False)
                    .agg(col1=("NUMBER_OF_DOWNLOADS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_DOWNLOADS (sum)"})
                    .reset_index()
                )

                df["/* Order Key (Generated by Snowflake) */"] = df.drop(
                    columns="DATATYPE"
                ).sum(axis=1)

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
                    horizontal=True,
                    stack=False,
                    x_label="NUMBER_DOWNLOADS",
                    y_label="DATATYPE",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_6_2() -> str:
    sql_query = rf"""

--- Excludes files labelled "resouceType = metadata" to avoid miscounting files annotated with multiple studies

with node_annotations as (
    select
        id,
        file_handle_id,
        annotations:annotations:dataType:value[0]::string as dataType,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
        )
), dedup_downloads as (
    select
        distinct filedownload.user_id, filedownload.record_date, filedownload.file_handle_id, node_annotations.dataType
    from
    synapse_data_warehouse.synapse_event.objectdownload_event filedownload
    inner join
        node_annotations
    on
        filedownload.association_object_id = node_annotations.id
    where
        {window_filter_sql('filedownload.record_date')}
), external_users as (
    select id as user_id
    from
        synapse_data_warehouse.synapse.userprofile_latest
    where
        email not ilike '%@sagebase.org' and email not ilike '%sagebionetworks.org'

), file_size as(
    select
        id,
        content_size  
    from synapse_data_warehouse.synapse.file_latest
)
select
    dataType,
    count(record_date) AS number_of_downloads,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    round(sum(file_size.content_size) / power(2, 30), 2) AS GiB_downloaded
from
    dedup_downloads
inner join
    external_users
    on dedup_downloads.user_id = external_users.user_id
left join
    file_size
    on dedup_downloads.file_handle_id = file_size.id
where
    dataType is not null
    and dataType in ({sql_in_list(input_datatypes)})
group by
    dataType
order by
    number_of_unique_users desc, dataType desc;  """

    return sql_query



@st.fragment
def cell_6_2():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Unique users downloading by datatype (non-Sagers)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_2",
                help="Refresh unique_users_downloading_by_datatype_(non-sagers) data",
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
                    .agg(col1=("NUMBER_OF_UNIQUE_USERS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_UNIQUE_USERS (sum)"})
                    .reset_index()
                )

                df["/* Order Key (Generated by Snowflake) */"] = df.drop(
                    columns="DATATYPE"
                ).sum(axis=1)

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
                    horizontal=True,
                    stack=False,
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_7_1() -> str:
    sql_query = rf"""

--- Excludes Sage users

with node_annotations as (
    select
        id,
        file_handle_id,
        annotations:annotations:dataType:value[0]::string as dataType,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
        )
        and node_type = 'file'
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
        objectdownload_event.association_object_id = node_annotations.id
    where
        {window_filter_sql('objectdownload_event.record_date')}
), external_users as (
    select id as user_id
    from
        synapse_data_warehouse.synapse.userprofile_latest
    where
        email not ilike '%@sagebase.org' and email not ilike '%sagebionetworks.org'
), files_per_datatype as (
    -- includes files with no downloads, so the mean is per file in the datatype
    select
        dataType,
        count(distinct id) as number_of_files
    from node_annotations
    group by dataType
)
select
    dedup_downloads.dataType,
    round(count(dedup_downloads.record_date) / max(files_per_datatype.number_of_files), 2) as mean_downloads_per_file
from
    dedup_downloads
inner join
    files_per_datatype
    on dedup_downloads.dataType = files_per_datatype.dataType
inner join
    external_users
    on dedup_downloads.user_id = external_users.user_id
where
    dedup_downloads.dataType is not null
    and dedup_downloads.dataType in ({sql_in_list(input_datatypes)})
group by
    dedup_downloads.dataType
order by
    mean_downloads_per_file desc, dataType desc;  """

    return sql_query



@st.fragment
def cell_7_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Mean downloads per file by datatype (non-Sagers)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_7_1",
                help="Refresh mean_downloads_per_file_by_datatype_(non-sagers) data",
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

            # Prepare data for bar chart
            if len(df) > 0:
                df = df[["DATATYPE", "MEAN_DOWNLOADS_PER_FILE"]]

                df["/* Order Key (Generated by Snowflake) */"] = df.drop(
                    columns="DATATYPE"
                ).sum(axis=1)

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
                    horizontal=True,
                    stack=False,
                    x_label="MEAN_DOWNLOADS_PER_FILE",
                    y_label="DATATYPE",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_7_2() -> str:
    sql_query = rf"""

--- Excludes files labelled "resouceType = metadata" to avoid miscounting files annotated with multiple studies

with node_annotations as (
    select
        id,
        file_handle_id,
        annotations:annotations:dataType:value[0]::string as dataType,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
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
        objectdownload_event.association_object_id = node_annotations.id
    where
        {window_filter_sql('objectdownload_event.record_date')}
), external_users as (
    select id as user_id
    from
        synapse_data_warehouse.synapse.userprofile_latest
    where
        email not ilike '%@sagebase.org' and email not ilike '%sagebionetworks.org'

), file_size as(
    select
        id,
        content_size  
    from synapse_data_warehouse.synapse.file_latest
)
select
    dataType,
    count(record_date) AS number_of_downloads,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    round(sum(file_size.content_size) / power(2, 40), 2) AS TB_downloaded
from
    dedup_downloads
inner join
    external_users
    on dedup_downloads.user_id = external_users.user_id
left join
    file_size
    on dedup_downloads.file_handle_id = file_size.id
where
    dataType is not null
    and dataType in ({sql_in_list(input_datatypes)})
group by
    dataType
order by
    number_of_unique_users desc, dataType desc;  """

    return sql_query



@st.fragment
def cell_7_2():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Volume downloaded (TB) by data type (non-Sagers)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_7_2",
                help="Refresh volume_downloaded_(tb)_by_data_type_(non-sagers) data",
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
                df = df[["DATATYPE", "TB_DOWNLOADED"]]

                df["/* Order Key (Generated by Snowflake) */"] = df.drop(
                    columns="DATATYPE"
                ).sum(axis=1)

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
                    horizontal=True,
                    stack=False,
                    x_label="TB_DOWNLOADED",
                    y_label="DATATYPE",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_8_2() -> str:
    sql_query = rf"""
select 
    record_date,
    sum("'TRUE'") AS internal_users,
    sum("'FALSE'") AS external_users
    from (select * from sage.ad.user_frequency where {window_filter_sql('record_date')})
    pivot(count(user_id) for sage_internal in ('TRUE', 'FALSE'))
        as p
    group by record_date
    order by
        record_date desc;  """

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
                st.markdown("### internal vs external AD portal users")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_8_2",
                help="Refresh internal_vs_external_ad_portal_users data",
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

            # Prepare data for line chart with aggregation
            if len(df) > 0:
                df = (
                    df.groupby(by="RECORD_DATE", sort=False)
                    .agg(col1=("INTERNAL_USERS", "sum"), col2=("EXTERNAL_USERS", "sum"))
                    .rename(
                        columns={
                            "col1": "INTERNAL_USERS (sum)",
                            "col2": "EXTERNAL_USERS (sum)",
                        }
                    )
                    .reset_index()
                )

                st.line_chart(
                    df.set_index("RECORD_DATE"),
                    width="stretch",
                    height=400,
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_10_1() -> str:
    sql_query = rf"""
select 
    --datebucket(RECORD_DATE) as MONTH_OF_DL,
    year(month_created) as year,
    monthname(month_created) as month,
    month_created as measurement_point, 
    simple_assay,
    round((cumulative_volume) / power(2, 40), 2) as cumulative_volume_TB
from 
    sage.ad.datatype_cumulative_volume
where 
    simple_assay is not null 
    and simple_assay not in ('', 'Blood Chemistry Measurement', 'polymeraseChainReaction')
    and year >= 2015
    and {window_filter_sql('month_created')}
order by 
    measurement_point desc,
    cumulative_volume_TB desc
;
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
                st.markdown("### cumulative upload volume (TB) by data type")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_10_1",
                help="Refresh cumulative_upload_volume_(tb)_by_data_type data",
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
                    df.groupby(by=["MEASUREMENT_POINT", "SIMPLE_ASSAY"], sort=False)
                    .agg(col1=("CUMULATIVE_VOLUME_TB", "sum"))
                    .rename(columns={"col1": "CUMULATIVE_VOLUME_TB (sum)"})
                    .unstack(level=1)
                )

                df.columns = [
                    " | ".join(map(str, c[::-1])).replace(":", "_") for c in df.columns
                ]

                df = df.reset_index()

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["MEASUREMENT_POINT"]):
                    datetime_primary_column = df["MEASUREMENT_POINT"]
                elif df["MEASUREMENT_POINT"].dtype == "object" and isinstance(
                    df["MEASUREMENT_POINT"].get(
                        df["MEASUREMENT_POINT"].first_valid_index()
                    ),
                    dt.date,
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["MEASUREMENT_POINT"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["MEASUREMENT_POINT"] = df["MEASUREMENT_POINT"].astype("string")

                st.bar_chart(
                    df.set_index("MEASUREMENT_POINT"),
                    sort=True,
                    width="stretch",
                    height=400,
                    stack=True,
                    x_label="year-month",
                    y_label="CUMULATIVE_VOLUME (TB)",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_12_1() -> str:
    sql_query = rf"""
-- uploaded files by consortium

with file_size as (
    select
        id as file_handle_id,
        content_size
    from synapse_data_warehouse.synapse.file_latest
)
select
    trim(spl.value, '"[] ') as consortium,
    count(distinct nl.file_handle_id) as number_files,
    round(sum(content_size)/power(2, 40), 3) as data_volume_TB
from synapse_data_warehouse.synapse.node_latest nl
left join file_size as fs
    on nl.file_handle_id = fs.file_handle_id, lateral split_to_table(annotations:annotations:consortium:value::VARCHAR, ',') spl
where project_id = '2580853' and node_type = 'file' and is_public = 'true' and consortium != 'ROSMAP'
    and {window_filter_sql('nl.created_on')}
group by consortium
order by number_files desc;  """

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
                st.markdown("### Contributed Data per Consortium")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_12_1",
                help="Refresh contributed_data_per_consortium data",
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

            render_dataframe(df)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_12_2() -> str:
    sql_query = rf"""
with file_size as (
    select
        id as file_handle_id,
        content_size
    from synapse_data_warehouse.synapse.file_latest
)
select 
    trim(nl.annotations:annotations:organ:value[0], '"') as organ,
    round(sum(fs.content_size)/power(2, 40), 3) as data_volume_TB,
    count(distinct nl.file_handle_id) as number_files
from synapse_data_warehouse.synapse.node_latest nl
left join file_size as fs
    on nl.file_handle_id = fs.file_handle_id,
where project_id = '2580853' 
    and node_type = 'file' 
    and {window_filter_sql('nl.created_on')}
    and is_public = 'true'
    and annotations:annotations:species:value[0] = 'Human'
    and organ is not null
group by organ
order by data_volume_TB desc
;  """

    return sql_query


execute_query(query_12_2())


@st.fragment
def cell_12_2():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Human Data Volume by Organ")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_12_2",
                help="Refresh human_data_volume_by_organ data",
            ):
                execute_query.clear(query_12_2())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_12_2())).result(
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

            render_dataframe(df)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_13_1() -> str:
    sql_query = rf"""
-- average users per month
-- Distribution of downloads, users, and TB downloaded over months
with dedup_downloads as (
    select 
        distinct filedownload.user_id, filedownload.file_handle_id, filedownload.record_date, file_latest.content_size
    from
    synapse_data_warehouse.synapse_event.objectdownload_event filedownload
    join
        synapse_data_warehouse.synapse.file_latest
        on filedownload.file_handle_id = file_latest.id
    where
        project_id = 2580853
        and {window_filter_sql('filedownload.record_date')}
),

monthly_downloads as (
    SELECT
        date_trunc('MONTH', RECORD_DATE) AS MONTH_OF_DL,
        count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS,
        count(distinct USER_ID) UNIQUE_USERS,
        round(sum(content_size) / power(2, 40), 2) AS TB_DOWNLOADED
    FROM
        dedup_downloads
    GROUP BY
        MONTH_OF_DL
    ORDER BY
        MONTH_OF_DL DESC
        NULLS LAST
)
select 

    avg(number_of_downloads) as avg_downloads,
    avg(unique_users) as avg_unique_users,
    avg(tb_downloaded) as avg_tb_downloaded
from monthly_downloads;

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
                st.markdown("### Average monthly downloads, users, and volume (TB)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_13_1",
                help="Refresh average_monthly_downloads,_users,_and_volume_(tb) data",
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

            render_dataframe(df, height="auto")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_14_1() -> str:
    sql_query = rf"""
--- Excludes Sage users, since 2022
--- excludes metadata files

with node_annotations as (
    select
        id,
        file_handle_id,
        annotations:annotations:dataType:value[0] as data_type,
        annotations:annotations:dataSubtype:value[0] as data_subtype,
        annotations:annotations:fileFormat:value[0] as file_format,
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
        )
), dedup_downloads as (
    select
        distinct filedownload.user_id, 
        filedownload.record_date, 
        filedownload.file_handle_id, 
        node_annotations.data_type,
        node_annotations.data_subtype,
        node_annotations.file_format
    from
      synapse_data_warehouse.synapse_event.objectdownload_event filedownload
    inner join
        node_annotations
    on
        filedownload.association_object_id = node_annotations.id
    where
        {window_filter_sql('filedownload.record_date')}
), external_users as (
    select id as user_id
    from
        synapse_data_warehouse.synapse.userprofile_latest
    where
        email not ilike '%@sagebase.org' and email not ilike '%sagebionetworks.org'

)
select
    data_subtype,
    file_format,
    count(distinct dedup_downloads.user_id) as number_of_unique_users,
    count(record_date) AS number_of_downloads
from
    dedup_downloads
inner join
    external_users
    on dedup_downloads.user_id = external_users.user_id
where
    data_type = 'geneExpression'
group by
data_subtype, file_format
order by
    number_of_unique_users desc;  """

    return sql_query


execute_query(query_14_1())


@st.fragment
def cell_14_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown(
                    "### gene expression downloads by file format and data subtype (non-Sagers)"
                )
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_14_1",
                help="Refresh gene_expression_downloads_by_file_format_and_data_subtype_(non-sagers) data",
            ):
                execute_query.clear(query_14_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_14_1())).result(
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

            render_dataframe(df)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_14_2() -> str:
    sql_query = rf"""
-- data usage within the date window from all buckets provisioned by the synapse-service-ad-data-curation-01 service account in the STRIDES service catalog

with bucket_info as (
    select 
        id as file_handle_id,
        bucket,
        content_size
    from synapse_data_warehouse.synapse.file_latest
    where bucket in ('ad-knowledge-portal-large', 
                    'ad-knowledge-portal-main', 
                    'diverse-cohorts', 
                    'exceptional-longevity', 
                    'scientific-wellness')
),
dedup_last_month_downloads as (
    select
        user_id, record_date, file_handle_id, 
    from
        synapse_data_warehouse.synapse_event.objectdownload_event
    where {window_filter_sql('record_date')}
)
select
    case 
        when grouping(bucket) = 1 then 'Total All Buckets'
        else bucket
    end bucket,
    count(distinct dl.user_id, dl.record_date, dl.file_handle_id) AS number_of_downloads,
    count(distinct dl.user_id) as number_of_unique_users,
    sum(b.content_size)/power(2,30) as download_volume_gb,
    record_date
from bucket_info b
inner join dedup_last_month_downloads dl
    on b.file_handle_id = dl.file_handle_id
group by 
    dl.record_date, 
    rollup(bucket)
order by 
    dl.record_date
;

  """

    return sql_query


execute_query(query_14_2())


@st.fragment
def cell_14_2():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### STRIDES bucket downloads")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_14_2",
                help="Refresh strides_bucket_downloads_-_previous_30_days data",
            ):
                execute_query.clear(query_14_2())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_14_2())).result(
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
                    df.groupby(by=["RECORD_DATE", "BUCKET"], sort=False)
                    .agg(col1=("NUMBER_OF_DOWNLOADS", "sum"))
                    .rename(columns={"col1": "NUMBER_OF_DOWNLOADS (sum)"})
                    .unstack(level=1)
                )

                df.columns = [
                    " | ".join(map(str, c[::-1])).replace(":", "_") for c in df.columns
                ]

                df = df.reset_index()

                st.line_chart(
                    df.set_index("RECORD_DATE"),
                    width="stretch",
                    height=400,
                    y_label="DOWNLOAD_VOLUME_GB",
                )
            else:
                st.warning("No data available")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_15_2() -> str:
    sql_query = rf"""
with individuals as (
    select
        annotations:annotations:individualID:value as individualID,
        annotations:annotations:species:value[0] as species
    from
        synapse_data_warehouse.synapse.node_latest
    where
        project_id in (
            2580853
        )
        and {window_filter_sql('created_on')}
)
select
    case 
        when grouping(species) = 1 then 'Total'
        else species
    end species,
    count(distinct individualID)
from
    individuals
where individualID is not null
group by 
    rollup(species)
order by count(distinct individualID) desc;  """

    return sql_query


execute_query(query_15_2())


@st.fragment
def cell_15_2():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### unique individuals from annotations")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_15_2",
                help="Refresh unique_individuals_from_annotations data",
            ):
                execute_query.clear(query_15_2())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_15_2())).result(
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
                df = df[["SPECIES", "COUNT(DISTINCT INDIVIDUALID)"]]

                df["/* Order Key (Generated by Snowflake) */"] = df.drop(
                    columns="SPECIES"
                ).sum(axis=1)

                datetime_primary_column = None
                if pd.api.types.is_datetime64_dtype(df["SPECIES"]):
                    datetime_primary_column = df["SPECIES"]
                elif df["SPECIES"].dtype == "object" and isinstance(
                    df["SPECIES"].get(df["SPECIES"].first_valid_index()), dt.date
                ):
                    datetime_primary_column = pd.to_datetime(
                        df["SPECIES"], errors="coerce"
                    )
                if (
                    datetime_primary_column is not None
                    and (
                        datetime_primary_column.max() - datetime_primary_column.min()
                    ).days
                    > len(df) * 2
                ):
                    # Use string type for sparse date range
                    df["SPECIES"] = df["SPECIES"].astype("string")

                st.bar_chart(
                    df,
                    x="SPECIES",
                    y=[
                        c
                        for c in df.columns
                        if c != "SPECIES"
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


def query_16_1() -> str:
    sql_query = rf"""
select
    node_latest.name as entity_name,
    acl_latest.owner_id as entity_id,
    acl_latest.access_type,
    acl_latest.principal_id as user_or_team_id
from
    synapse_data_warehouse.synapse.node_latest
join
    synapse_data_warehouse.synapse.acl_latest on
    node_latest.id = acl_latest.owner_id
where
    node_latest.project_id = 2580853
    and {window_filter_sql('acl_latest.created_on')};  """

    return sql_query


execute_query(query_16_1())


@st.fragment
def cell_16_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Local sharing settings")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_16_1",
                help="Refresh local_sharing_settings data",
            ):
                execute_query.clear(query_16_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_16_1())).result(
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

            render_dataframe(df, height="auto")
        except Exception as e:
            st.error(f"Error: {str(e)}")


def query_17_1() -> str:
    # 9603055 is the "AD Knowledge Portal" access requirement (the ADKP clickwrap);
    # it has by far the highest submission volume of any access requirement
    sql_query = f"""
select
    coalesce(sum(received_count), 0) as "TOTAL SUBMISSIONS RECEIVED (INCL. RESUBMISSIONS)",
    coalesce(sum(approved_count), 0) as total_submissions_approved
from
    synapse_data_warehouse.synapse_aggregate.data_access_submission_aggregate
where
    agg_access_requirement_id = 9603055
    and agg_period = '{AGGREGATE_PERIODS[input_datebucket]}'
    and {window_filter_sql('agg_period_start')};  """

    return sql_query


execute_query(query_17_1())


@st.fragment
def cell_17_1():
    with st.container(border=True):
        with st.container(
            horizontal=True,
            horizontal_alignment="distribute",
            vertical_alignment="center",
        ):
            with st.container(height=80, border=False, vertical_alignment="center"):
                st.markdown("### Access request submissions")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key="refresh_button_cell_17_1",
                help="Refresh access_request_submissions data",
            ):
                execute_query.clear(query_17_1())

        try:
            with st.spinner("Executing query", show_time=True):
                df = session.create_async_job(execute_query(query_17_1())).result(
                    "pandas"
                )

            render_dataframe(df)
        except Exception as e:
            st.error(f"Error: {str(e)}")


def cell_date_window() -> None:
    # Shows the window the queries actually cover, rounded out to whole date-bucket periods
    with st.container(border=True):
        with st.container(height=80, border=False, vertical_alignment="center"):
            st.markdown("### Date window")
        render_dataframe(
            pd.DataFrame(
                {
                    "START": [bucket_floor(window_start, input_datebucket)],
                    "END": [bucket_end(window_end, input_datebucket)],
                }
            )
        )


def render_cells(cells, num_columns: int) -> None:
    for i in range(0, len(cells), num_columns):
        for col, cell in zip(st.columns(num_columns), cells[i : i + num_columns]):
            with col:
                cell()


# Layout: cells grouped by category, one expander each
with st.expander("Overview", expanded=True):
    render_cells(
        [cell_date_window, cell_1_2, cell_1_3, cell_4_1, cell_4_2, cell_12_2, cell_15_2],
        num_columns=2,
    )

with st.expander("Downloads"):
    render_cells(
        [
            cell_date_window, cell_2_1, cell_2_2, cell_13_1, cell_downloads_count, cell_downloads_users,
            cell_downloads_volume, cell_14_1, cell_14_2,
        ],
        num_columns=2,
    )

    st.markdown("#### By study")
    try:
        study_options = (
            session.create_async_job(execute_query(query_study_options()))
            .result("pandas")["STUDY"]
            .tolist()
        )
    except Exception as e:
        study_options = []
        st.error(f"Error: {str(e)}")
    # Hundreds of studies make for unreadable charts, so default to the five with the
    # most downloads (study_options is already sorted by downloads)
    input_studies = st.multiselect(
        "Studies",
        options=study_options,
        default=study_options[:5],
        key="study_param",
    )
    render_cells(
        [
            cell_study_downloads_count,
            cell_study_downloads_users,
            cell_study_downloads_volume,
        ],
        num_columns=2,
    )

    st.markdown("#### By datatype")
    try:
        datatype_options = (
            session.create_async_job(execute_query(query_datatype_options()))
            .result("pandas")["DATATYPE"]
            .tolist()
        )
    except Exception as e:
        datatype_options = []
        st.error(f"Error: {str(e)}")
    # Default to the ten most-downloaded datatypes
    input_datatypes = st.multiselect(
        "Datatypes",
        options=datatype_options,
        default=datatype_options[:10],
        key="datatype_param",
    )
    render_cells([cell_6_1, cell_6_2, cell_7_2, cell_7_1], num_columns=2)

with st.expander("Uploads"):
    render_cells([cell_date_window, cell_10_1, cell_12_1], num_columns=2)

with st.expander("Access Requests"):
    st.markdown(
        'All charts are with respect to the "AD Knowledge Portal" (9603055) '
        "access requirement."
    )
    render_cells([cell_date_window, cell_17_1], num_columns=2)

# Cells that don't fit Overview/Downloads/Uploads; pending review
with st.expander("Misc."):
    render_cells([cell_date_window, cell_8_2, cell_16_1], num_columns=2)


# Footer
st.markdown("---")
st.markdown(
    "*Dashboard loaded: {}*".format(dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
)
