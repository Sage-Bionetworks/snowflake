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
            "the active Streamlit in Snowflake session."
        ),
    )
    return parser.parse_args()


def get_session(local_dev: bool) -> Session:
    if local_dev:
        return Session.builder.config("connection_name", "default").create()
    return get_active_session()


args = read_args()

# Set page config
st.set_page_config(page_title="Audit", layout="wide")

# Title
st.title("Audit")
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

# Parameter input widgets arranged in a row
(param_col_1,) = st.columns(1)

with param_col_1:
    # Parameter: daterange (relative)
    st.markdown("**Date range**")
    default_start = dt.datetime.now().date() - dt.timedelta(days=30 * 6)
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
with user_download_count (user_id, num_downloads) as (
    select fd.user_id, count(*) as num_downloads
    from synapse_data_warehouse.synapse_event.objectdownload_event fd
    where (
        extract(year from fd.record_date) = extract(year from current_date)
        and extract(quarter from fd.record_date) in (1,2)
        and extract(quarter from current_date) in (3,4)
    )
    or (
        extract(year from fd.record_date) = extract(year from current_date) - 1
        and extract(quarter from fd.record_date) in (3,4)
        and extract(quarter from current_date) in (1,2)
    )
    group by fd.user_id
),
user_project_download_count (user_id, project_id, num_downloads) as (
    select fd.user_id, fd.project_id, count(fd.association_object_id) as num_downloads
    from synapse_data_warehouse.synapse_event.objectdownload_event fd
    /*join node_snapshot_ranked nd on nd.id=fd.association_object_id
    where nd.rn=1
    and*/ where ((
        extract(year from fd.record_date) = extract(year from current_date)
        and extract(quarter from fd.record_date) in (1,2)
        and extract(quarter from current_date) in (3,4)
    )
    or (
        extract(year from fd.record_date) = extract(year from current_date) - 1
        and extract(quarter from fd.record_date) in (3,4)
        and extract(quarter from current_date) in (1,2)
    ))
    and fd.association_object_type in ('FileEntity', 'TableEntity')
    group by fd.user_id, fd.project_id
),
user_project_download_count_ranked (user_id, project_id, num_downloads, rn) as (
    select user_id, project_id, num_downloads, row_number() over (partition by user_id order by num_downloads desc) as rn
    from user_project_download_count
),
user_download_top_project (user_id, project_ids) as (
    select user_id, listagg(project_id, ',') as project_ids
    from user_project_download_count_ranked
    where rn < 6
    group by user_id
),
user_download_count (user_id, num_downloads) as (
    select updcr.user_id, sum(updcr.num_downloads) as num_downloads
    from user_project_download_count_ranked updcr
    group by updcr.user_id
)
select udc.user_id, udc.num_downloads, upl.user_name, upl.email, upl.first_name, upl.last_name, concat('https://www.synapse.org/#!Profile:', upl.id) as user_profile, udtp.project_ids
from user_download_count udc
join user_download_top_project udtp on udtp.user_id=udc.user_id
join synapse_data_warehouse.synapse.userprofile_latest upl on upl.id=udc.user_id
order by udc.num_downloads desc
limit 20
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
                st.markdown("### top_downloaders_top_project")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_1",
                help="Refresh top_downloaders_top_project data",
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
with md5_duplicate_filter (content_md5, md5_count) as (
    select fl.content_md5, count(*) as md5_count
  from synapse_data_warehouse.synapse.file_latest fl
    where not fl.is_preview and fl.created_on < '2024-01-01' and fl.change_type <> 'DELETE'
    group by fl.content_md5
    having md5_count > 1
)/*10M/45M*/,
md5_duplicate_node (filehandle_id, content_md5, node_id, node_name, project_id, parent_id, is_public, is_controlled, is_restricted) as (
    select fl.id as filehandle_id, fl.content_md5, nl.id as node_id, nl.name as node_name, nl.project_id, nl.parent_id,
        iff(nl.is_public,1,0), iff(nl.is_controlled,1,0), iff(nl.is_restricted,1,0)
  from synapse_data_warehouse.synapse.file_latest fl
    join md5_duplicate_filter md5df on md5df.content_md5=fl.content_md5
  join synapse_data_warehouse.synapse.node_latest nl on nl.file_handle_id=fl.id
    where not fl.is_preview and fl.created_on < '2024-01-01' and fl.change_type <> 'DELETE'
)/*7M*/,
md5_duplicate_inconsistent_summary (content_md5, c_md5, s_is_public, s_is_controlled, s_is_restricted) as (
    select content_md5, count(*) as c_md5,
        sum(is_public) as s_is_public, sum(is_controlled) as s_is_controlled, sum(is_restricted) as s_is_restricted
    from md5_duplicate_node
    group by content_md5
    having (c_md5 <> s_is_public and s_is_public <> 0)
        and ((c_md5 <> s_is_controlled and s_is_controlled <> 0)
        or (c_md5 <> s_is_restricted and s_is_restricted <> 0))
),
md5_duplicate_node_inconsistent as (
    select dn.*
    from md5_duplicate_node dn
    join md5_duplicate_inconsistent_summary dns on dns.content_md5=dn.content_md5
),
md5_duplicate_inconsistent_public_controlled_or_restricted as (
    select * from md5_duplicate_node_inconsistent
    where is_public and (is_controlled or is_restricted)
),
md5_duplicate_inconsistent_public_not_controlled_and_not_restricted as (
    select * from md5_duplicate_node_inconsistent
    where is_public and not (is_controlled or is_restricted)
)
select distinct pcr.project_id as project_locked, pncr.project_id as project_unlocked
from md5_duplicate_inconsistent_public_controlled_or_restricted pcr
join md5_duplicate_inconsistent_public_not_controlled_and_not_restricted pncr on pncr.content_md5=pcr.content_md5
order by pcr.project_id  """

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
                st.markdown("### duplicate_md5_project_summary")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_1",
                help="Refresh duplicate_md5_project_summary data",
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
    sql_query = r"""
with md5_duplicate_filter (content_md5, md5_count) as (
    select fl.content_md5, count(*) as md5_count
  from synapse_data_warehouse.synapse.file_latest fl
    where not fl.is_preview and created_on < '2024-01-01' and change_type <> 'DELETE'
    group by fl.content_md5
    having md5_count > 1
)/*10M/45M*/,
md5_duplicate_node (filehandle_id, content_md5, node_id, node_name, project_id, parent_id, is_public, is_controlled, is_restricted) as (
    select fl.id as filehandle_id, fl.content_md5, nl.id as node_id, nl.name as node_name, nl.project_id, nl.parent_id,
        iff(nl.is_public,1,0), iff(nl.is_controlled,1,0), iff(nl.is_restricted,1,0)
  from synapse_data_warehouse.synapse.file_latest fl
    join md5_duplicate_filter md5df on md5df.content_md5=fl.content_md5
  join synapse_data_warehouse.synapse.node_latest nl on nl.file_handle_id=fl.id
)/*7M*/,
md5_duplicate_node_summary (content_md5, c_md5, s_is_public, s_is_controlled, s_is_restricted) as (
    select content_md5, count(*) as c_md5,
        sum(is_public) as s_is_public, sum(is_controlled) as s_is_controlled, sum(is_restricted) as s_is_restricted
    from md5_duplicate_node
    group by content_md5
    having (c_md5 <> s_is_public and s_is_public <> 0)
        and ((c_md5 <> s_is_controlled and s_is_controlled <> 0)
        or (c_md5 <> s_is_restricted and s_is_restricted <> 0))
),
/* This is the result we used to use: 50K rows */
md5_duplicate_node_public_inconsistent as (
    select dn.*
    from md5_duplicate_node dn
    join md5_duplicate_node_summary dns on dns.content_md5=dn.content_md5
    where dn.is_public=1
)
select * from md5_duplicate_node_public_inconsistent order by content_md5, project_id  """

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
                st.markdown("### duplicate_md5")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_1",
                help="Refresh duplicate_md5 data",
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
        expr_daterange = f"snapshot_timestamp BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange = f"snapshot_timestamp >= '{start_date}'"
    else:
        expr_daterange = "TRUE"

    sql_query = rf"""

-- This CTE filters for nodes whose ARs changed in some way,
-- or the node went public, during the given date range
with events_within_daterange as (

select *
from synapse_data_warehouse.synapse_event.node_event
where {expr_daterange}

),
state_summary as (

    select
        -- We use ID as the only identifier for the node because each row
        -- for a single ID is already a de-duplicated event in node_event
        id,
        count(id) as total_events,
        -- If an event is true, mark 1. If false, mark 0.
        -- Take the sum.
        sum(iff(is_public, 1, 0)) as public_events,
        sum(iff(is_controlled, 1, 0)) as controlled_events,
        sum(iff(is_restricted, 1, 0)) as restricted_events
    from events_within_daterange
    group by id
    -- Let's filter out node events where is_public/controlled/restricted changed at some point
    -- within the given date range... In other words, filter out cases where an event always stayed
    -- false (e.g. public_events = 0), and cases where the event never changed (e.g. public_events = total_events)
    having (public_events <> 0 and public_events <> total_events)
        or (controlled_events <> 0 and controlled_events <> total_events)
        or (restricted_events <> 0 and restricted_events <> total_events)
),
state as (

    -- Here we order the lag() operation over a partition "ordered by snapshot_timestamp".
    -- because change_timestamp can be the same for multiple
    -- rows, which might create an inconsistency in what the true "previous row" is.
    -- In node_event, each event is marked with a distinct snapshot_timestamp, since the
    -- PK (id, version_number, change_type, modified_on) is selected for each UNIQUE snapshot_timestamp.
    -- This lets us leverage snapshot_timestamp for ordering the rows, as its the true
    -- timestamp for a single event. Try the following query to get what I mean:
    --
    -- select modified_on, change_timestamp, snapshot_timestamp, change_type, is_public, is_controlled, is_restricted
    -- from synapse_data_warehouse.synapse_event.node_event
    -- where id = 52361467
    -- and snapshot_date between '2023-07-01' and '2023-12-31';
    select distinct
        ne.id,
        ne.change_type,
        ne.modified_on,
        ne.is_public,
        lag(is_public) over (partition by ne.id order by ne.snapshot_timestamp) as was_public,
        ne.is_controlled,
        lag(is_controlled) over (partition by ne.id order by ne.snapshot_timestamp) as was_controlled,
        ne.is_restricted,
        lag(is_restricted) over (partition by ne.id order by ne.snapshot_timestamp) as was_restricted,
        ne.project_id,
        lag(ne.project_id) over (partition by ne.id order by ne.snapshot_timestamp) as previous_project_id,
        ne.parent_id,
        lag(ne.parent_id) over (partition by ne.id order by ne.snapshot_timestamp) as previous_parent_id
    from events_within_daterange as ne
    -- This join filters out for only the nodes that had their AR(s) changed in some form
    -- within the given date range
    join state_summary ss on ss.id=ne.id
        and ne.change_type <> 'DELETE'

),
node_public_relaxed_ar as (
    select *
    from state
    -- TODO: What if an AR started relaxed, then restricted/controlled, then relaxed again, all within the time frame?
    -- It will count in the final tally, but should it?
    where
        -- TODO: Why are we filtering for only public nodes that had their ARs relaxed?
        is_public=TRUE
    and ( (is_controlled=FALSE and was_controlled=TRUE)
        or (is_restricted=FALSE and was_restricted=TRUE) )
    and (project_id = previous_project_id)
    and (parent_id = previous_parent_id)
)
select
    project_id,
    count(*) as num_instances_relaxed
from node_public_relaxed_ar
group by project_id
order by project_id;

-- ORIGINAL
-- with state_summary as (
--     select id, version_number, count(id) as c, sum(iff(is_public,1,0)) as sp, sum(iff(is_controlled,1,0)) as sc, sum(iff(is_restricted,1,0)) as sr
--     from synapse_raw.nodesnapshots ns
--     where snapshot_date between '2023-07-01' and '2023-12-31'
--     group by id, version_number
--     having (sp <> 0 and sp <> c) or (sc <> 0 and sc <> c) or (sr <> 0 and sr <> c)
-- ),
-- state as (
--     select distinct ns.id, ns.change_timestamp, ns.is_public,
--         lag(is_public, 1, null) over (partition by ns.id order by ns.change_timestamp) as was_public,
--         ns.is_controlled,
--         lag(is_controlled, 1, null) over (partition by ns.id order by ns.change_timestamp) as was_controlled,
--         ns.is_restricted,
--         lag(is_restricted, 1, null) over (partition by ns.id order by ns.change_timestamp) as was_restricted,
--         ns.project_id,
--         lag(ns.project_id, 1, null) over (partition by ns.id order by ns.change_timestamp) as previous_project_id,
--         ns.parent_id,
--         lag(ns.parent_id, 1, null) over (partition by ns.id order by ns.change_timestamp) as previous_parent_id
--     from synapse_raw.nodesnapshots ns
--     join state_summary ss on ss.id=ns.id and ns.version_number=ss.version_number
--     where ns.snapshot_date between '2023-07-01' and '2023-12-31'
--         and ns.change_type <> 'DELETE'
-- ),
-- node_public_relaxed_ar as (
--     select *
--     from state
--     where is_public=TRUE and ((is_controlled=FALSE and was_controlled=TRUE) or (is_restricted=FALSE and was_restricted=TRUE))
--         and (project_id = previous_project_id) and (parent_id = previous_parent_id)
-- )
-- select project_id, count(*) as num_instances
-- from node_public_relaxed_ar
-- group by project_id
-- order by project_id  """

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
                st.markdown("### Relaxed ARs Summary")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_1",
                help="Refresh relaxed_ars_summary data",
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
        expr_daterange = f"snapshot_timestamp BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange = f"snapshot_timestamp >= '{start_date}'"
    else:
        expr_daterange = "TRUE"

    sql_query = rf"""
with events_within_daterange as (

select *
from synapse_data_warehouse.synapse_event.node_event
where {expr_daterange}

),
-- This CTE filters for nodes whose ARs changed in some way,
-- or the node went public, during the given date range
state_summary as (

    select
        -- We use ID as the only identifier for the node because each row
        -- for a single ID is already a de-duplicated event in node_event
        id,
        count(id) as total_events,
        -- If an event is true, mark 1. If false, mark 0.
        -- Take the sum.
        sum(iff(is_public, 1, 0)) as public_events,
        sum(iff(is_controlled, 1, 0)) as controlled_events,
        sum(iff(is_restricted, 1, 0)) as restricted_events
    from events_within_daterange
    group by id
    -- Let's filter out node events where is_public/controlled/restricted changed at some point
    -- within the given date range... In other words, filter out cases where an event always stayed
    -- false (e.g. public_events = 0), and cases where the event never changed (e.g. public_events = total_events)
    having (public_events <> 0 and public_events <> total_events)
        or (controlled_events <> 0 and controlled_events <> total_events)
        or (restricted_events <> 0 and restricted_events <> total_events)
),
state as (

    -- Here we order the lag() operation over a partition "ordered by snapshot_timestamp".
    -- because change_timestamp can be the same for multiple
    -- rows, which might create an inconsistency in what the true "previous row" is.
    -- In node_event, each event is marked with a distinct snapshot_timestamp, since the
    -- PK (id, version_number, change_type, modified_on) is selected for each UNIQUE snapshot_timestamp.
    -- This lets us leverage snapshot_timestamp for ordering the rows, as its the true
    -- timestamp for a single event. Try the following query to get what I mean:
    --
    -- select modified_on, change_timestamp, snapshot_timestamp, change_type, is_public, is_controlled, is_restricted
    -- from synapse_data_warehouse.synapse_event.node_event
    -- where id = 52361467
    -- and snapshot_date between '2023-07-01' and '2023-12-31';
    select distinct
        ne.id,
        ne.change_type,
        ne.modified_on,
        ne.is_public,
        lag(is_public) over (partition by ne.id order by ne.snapshot_timestamp) as was_public,
        ne.is_controlled,
        lag(is_controlled) over (partition by ne.id order by ne.snapshot_timestamp) as was_controlled,
        ne.is_restricted,
        lag(is_restricted) over (partition by ne.id order by ne.snapshot_timestamp) as was_restricted,
        ne.project_id,
        lag(ne.project_id) over (partition by ne.id order by ne.snapshot_timestamp) as previous_project_id,
        ne.parent_id,
        lag(ne.parent_id) over (partition by ne.id order by ne.snapshot_timestamp) as previous_parent_id
    from events_within_daterange as ne
    -- This join filters out for only the nodes that had their AR(s) changed in some form
    -- within the given date range
    join state_summary ss on ss.id=ne.id
        and ne.change_type <> 'DELETE'

),
node_public_relaxed_ar as (
    select *
    from state
    -- TODO: What if an AR started relaxed, then restricted/controlled, then relaxed again, all within the time frame?
    -- It will count in the final tally, but should it?
    where
        -- TODO: Why are we filtering for only public nodes that had their ARs relaxed?
        is_public=TRUE
    and ( (is_controlled=FALSE and was_controlled=TRUE)
        or (is_restricted=FALSE and was_restricted=TRUE) )
    and (project_id = previous_project_id)
    and (parent_id = previous_parent_id)
)
select *
from node_public_relaxed_ar
order by modified_on desc;

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

-- ORIGINAL
-- with state_summary as (
--     select id, version_number, count(id) as c, sum(iff(is_public,1,0)) as sp, sum(iff(is_controlled,1,0)) as sc, sum(iff(is_restricted,1,0)) as sr
--     from synapse_raw.nodesnapshots ns
--     where snapshot_date between '2023-07-01' and '2023-12-31'
--     group by id, version_number
--     having (sp <> 0 and sp <> c) or (sc <> 0 and sc <> c) or (sr <> 0 and sr <> c)
-- ),
-- state as (
--     select distinct ns.id, ns.change_timestamp, ns.is_public,
--         lag(is_public, 1, null) over (partition by ns.id order by ns.change_timestamp) as was_public,
--         ns.is_controlled,
--         lag(is_controlled, 1, null) over (partition by ns.id order by ns.change_timestamp) as was_controlled,
--         ns.is_restricted,
--         lag(is_restricted, 1, null) over (partition by ns.id order by ns.change_timestamp) as was_restricted,
--         ns.project_id,
--         lag(ns.project_id, 1, null) over (partition by ns.id order by ns.change_timestamp) as previous_project_id,
--         ns.parent_id,
--         lag(ns.parent_id, 1, null) over (partition by ns.id order by ns.change_timestamp) as previous_parent_id
--     from synapse_raw.nodesnapshots ns
--     join state_summary ss on ss.id=ns.id and ns.version_number=ss.version_number
--     where ns.snapshot_date between '2023-07-01' and '2023-12-31'
--         and ns.change_type <> 'DELETE'
-- ),
-- node_public_relaxed_ar as (
--     select *
--     from state
--     where is_public=TRUE and ((is_controlled=FALSE and was_controlled=TRUE) or (is_restricted=FALSE and was_restricted=TRUE))
--         and (project_id = previous_project_id) and (parent_id = previous_parent_id)
--         and change_timestamp >= '2023-07-01'
-- )
-- select *
-- from node_public_relaxed_ar
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
                st.markdown("### Relaxed ARs View")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_5_1",
                help="Refresh relaxed_ars_view data",
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
        expr_daterange = f"timestamp BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange = f"timestamp >= '{start_date}'"
    else:
        expr_daterange = "TRUE"

    sql_query = rf"""
-- Jira ticket: https://sagebionetworks.jira.com/browse/SNOW-327
----------------------------------------------------------------------------------------------

-- WARNING:
-- IP_INFO runs the risk of getting outdated from time to time

-- Query 1:
-- How many NEW accounts were created from a CoC in the past 6 months from :report_start_date?
----------------------------------------------------------------------------------------------

-- First optimize the query by filtering for API requests
-- within the :daterange ONLY

-- nit: Do you want to join this with a list of all CoC names, so that countries
--   which didn't create any accounts are 0, rather than missing?
with rows_within_timeframe as (

    select
        request_url,
        x_forwarded_for,
        timestamp
    from 
        synapse_data_warehouse.synapse_event.access_event
    where {expr_daterange}

),
-- Next, we filter down even further for requests to the
-- /account2 endpoint...
-- This implies a user has verified an e-mail, completing the account
-- creation process. For documentation on this endpoint see here:
-- https://rest-docs.synapse.org/rest/POST/account2.html
new_accounts_verified as (

    select *
    from rows_within_timeframe
    where request_url = '/repo/v1/account2'

),
-- We use the ip_details Snowflake function to extract country information
-- from the input IP address (i.e. the x_forward_for column in `access_event`)
countries_of_origin as (

    select
        na.request_url,
        na.x_forwarded_for,
        ip.country_name
    from new_accounts_verified as na,
    lateral ip_info.public.ip_details(na.x_forwarded_for) AS ip

),
country_counts AS (
    
    select
        coc.country_name,
        COUNT(coo.country_name) AS new_accounts_created
    from (
        SELECT column1 AS country_name
        FROM VALUES
            ('China'),
            ('Hong Kong'),
            ('Macau'),
            ('Russia'),
            ('Iran'),
            ('North Korea'),
            ('Cuba'),
            ('Venezuela')
    ) AS coc
    left join countries_of_origin as coo
    on coc.country_name = coo.country_name
    group by
        coc.country_name
)
SELECT
    country_name,
    new_accounts_created
FROM
    country_counts
ORDER BY
    new_accounts_created desc;  """

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
                st.markdown("### New Accounts from CoC")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_1",
                help="Refresh new_accounts_from_coc data",
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
-- Query 2: What is the all-time total number of accounts created from CoCs?

-- WARNING:
-- IP_INFO runs the risk of getting outdated from time to time

-- First, we filter down for requests to the
-- /account2 endpoint...
-- This implies a user has verified an e-mail, completing the account
-- creation process. For documentation on this endpoint see here:
-- https://rest-docs.synapse.org/rest/POST/account2.html
with new_accounts_verified as (

    select
        request_url,
        x_forwarded_for,
        timestamp
    from
        synapse_data_warehouse.synapse_event.access_event
    where
        request_url = '/repo/v1/account2'
    and
        success = TRUE

),
-- We use the ip_details Snowflake function to extract country information
-- from the input IP address (i.e. the x_forward_for column in `access_event`)
countries_of_origin as (

    select
        na.request_url,
        na.x_forwarded_for,
        ip.country_name
    from new_accounts_verified as na,
    lateral ip_details(na.x_forwarded_for) AS ip

),
country_counts AS (
    
    select
        coc.country_name,
        COUNT(coo.country_name) AS new_accounts_created
    from (
        SELECT column1 AS country_name
        FROM VALUES
            ('China'),
            ('Hong Kong'),
            ('Macau'),
            ('Russia'),
            ('Iran'),
            ('North Korea'),
            ('Cuba'),
            ('Venezuela')
    ) AS coc
    left join countries_of_origin as coo
    on coc.country_name = coo.country_name
    group by
        coc.country_name
)
SELECT
    country_name,
    new_accounts_created
FROM
    country_counts
ORDER BY
    new_accounts_created desc;  """

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
                st.markdown("### All Time: New Accounts from CoC")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_6_2",
                help="Refresh all_time:_new_accounts_from_coc data",
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


# Row 6: 2 Cells
col6_1, col6_2 = st.columns(2)
with col6_1:
    cell_6_1()
with col6_2:
    cell_6_2()


def query_7_1() -> str:
    # Transform :daterange parameter - convert to range comparison
    if isinstance(input_daterange, tuple) and len(input_daterange) == 2:
        start_date, end_date = input_daterange
        expr_daterange = f"timestamp BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange = f"timestamp >= '{start_date}'"
    else:
        expr_daterange = "TRUE"

    sql_query = rf"""
-- Jira ticket: https://sagebionetworks.jira.com/browse/SNOW-327
----------------------------------------------------------------------------------------------

-- WARNING:
-- IP_INFO runs the risk of getting outdated from time to time

-- Query 3:
-- What new projects have been generated from a Country of Concern within the specified :daterange?
----------------------------------------------------------------------------------------------


WITH base_events AS (
    SELECT
        ne.name AS project_name,
        ne.id AS project_id,
        ae.x_forwarded_for,
        ae.timestamp,
        ae.user_id
    FROM
        synapse_data_warehouse.synapse_event.access_event ae
        JOIN synapse_data_warehouse.synapse_event.node_event ne
          -- Here we are stripping the 'syn' prefix from the `return_object_id`
          -- string value, and converting it to a number we can compare against
          -- the `id` column which is a number datatype.
          ON TRY_TO_NUMBER(SUBSTR(ae.return_object_id, 4)) = ne.id
    -- We filter `request_url` with the endpoints below because they are the services
    -- used to generate entities on Synapse. See the links below for more context:
    -- https://rest-docs.synapse.org/rest/POST/entity/bundle2/create.html
    -- and
    -- https://rest-docs.synapse.org/rest/POST/entity.html
    WHERE (ae.request_url = '/repo/v1/entity' or ae.request_url = '/repo/entity/bundle2/create')
    AND ae.success = TRUE
    AND ae.method = 'POST'
    AND ne.node_type = 'project'
    AND ae.x_forwarded_for IS NOT NULL
    AND {expr_daterange}
),
distinct_ips AS (
  SELECT DISTINCT
    x_forwarded_for
  FROM
    base_events
),
ip_info AS (
  SELECT
    dip.x_forwarded_for,
    ip.country_name
  FROM
    distinct_ips dip,
    LATERAL ip_details(dip.x_forwarded_for) AS ip
  WHERE
    ip.country_name IN (
      'China','Hong Kong','Macau',
      'Russia','Iran','North Korea',
      'Cuba','Venezuela'
    )
)
SELECT
  b.project_name,
  b.project_id,
  b.timestamp,
  b.x_forwarded_for,
  ip.country_name,
  b.user_id
FROM
  base_events b
  JOIN ip_info ip
    ON b.x_forwarded_for = ip.x_forwarded_for
ORDER BY
    TIMESTAMP DESC;

-- phil feedback --
-- should we sort this by something? `timestamp`, perhaps?  """

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
                st.markdown("### New Projects from CoC")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_7_1",
                help="Refresh new_projects_from_coc data",
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
    # Transform :daterange parameter - convert to range comparison
    if isinstance(input_daterange, tuple) and len(input_daterange) == 2:
        start_date, end_date = input_daterange
        expr_daterange = f"timestamp BETWEEN '{start_date}' AND '{end_date}'"
    elif isinstance(input_daterange, tuple) and len(input_daterange) == 1:
        start_date = input_daterange[0]
        expr_daterange = f"timestamp >= '{start_date}'"
    else:
        expr_daterange = "TRUE"

    sql_query = rf"""
-- Jira ticket: https://sagebionetworks.jira.com/browse/SNOW-327
----------------------------------------------------------------------------------------------

-- WARNING:
-- IP_INFO runs the risk of getting outdated from time to time

-- Query 4:
-- What new files have been uploaded onto Synapse from a country of concern within the
-- specified :daterange?
----------------------------------------------------------------------------------------------

WITH events_in_window AS (
    -- 1️⃣ Only filter by timestamp here
    SELECT
        request_url,
        x_forwarded_for,
        timestamp,
        user_id,
        return_object_id,
        success,
        method
    FROM synapse_data_warehouse.synapse_event.access_event
    -- phil feedback --
    -- Shoud we ask Governance if they prefer specifying an exact date range
    -- instead, e.g., `WHERE timestamp BETWEEN :start_ts AND :end_ts`
    WHERE {expr_daterange}
),
recent_files_created AS (
    -- 2️⃣ Apply all other access_event + node_event filters
    SELECT
        ne.name               AS file_name,
        ne.id                 AS file_id,
        e.x_forwarded_for,
        e.timestamp,
        e.user_id
    FROM events_in_window AS e
    JOIN synapse_data_warehouse.synapse_event.node_event AS ne
      ON TRY_TO_NUMBER(REGEXP_REPLACE(e.return_object_id, '\\D', '')) = ne.id
    -- phil feedback --
    -- same "briefly explain" feedback as before
    -- https://rest-docs.synapse.org/rest/POST/entity/bundle2/create.html
    -- and
    -- https://rest-docs.synapse.org/rest/POST/entity.html
    WHERE (e.request_url = '/repo/v1/entity' or e.request_url = '/repo/entity/bundle2/create')
    AND e.success = TRUE
    AND e.method = 'POST'
    AND ne.node_type = 'file'
),
distinct_ips AS (
    -- 3️⃣ Extract only the unique IPs to minimize function calls
    SELECT DISTINCT
        x_forwarded_for AS ip
    FROM recent_files_created
),
ip_info AS (
    -- 4️⃣ Lookup country info for each unique IP exactly once
    SELECT
        ip,
        ipd.country_name
    FROM distinct_ips
    CROSS JOIN LATERAL
        ip_details(distinct_ips.ip) AS ipd
),
countries_of_origin AS (
    -- 5️⃣ Re-join to bring country_name back onto each event
    SELECT
        rpc.file_name,
        rpc.file_id,
        rpc.timestamp,
        rpc.x_forwarded_for,
        ipi.country_name,
        rpc.user_id
    FROM recent_files_created AS rpc
    JOIN ip_info AS ipi
      ON rpc.x_forwarded_for = ipi.ip
    where ipi.country_name in (
    'China', 'Hong Kong', 'Macau',
    'Russia', 'Iran', 'North Korea',
    'Cuba', 'Venezuela')
)
SELECT *
FROM countries_of_origin
order by timestamp desc;
-- -- phil feedback --
-- -- can we move the country filter further up
-- -- so that we don't have to join on as many rows?
-- WHERE country_name IN (
--     'China', 'Hong Kong', 'Macau',
--     'Russia', 'Iran', 'North Korea',
--     'Cuba', 'Venezuela'
-- );
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
                st.markdown("### New Files Uploaded from a CoC")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_7_2",
                help="Refresh new_files_uploaded_from_a_coc data",
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
