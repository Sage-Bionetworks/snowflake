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
st.set_page_config(page_title="ACL audit", layout="wide")

# Title
st.title("ACL audit")
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


def param_query_1() -> str:
    """Build SQL for parameter 'synapse_project_id' (Synapse Project Id)."""
    sql_query = r"""
select
    distinct project_id
from
    synapse_data_warehouse.synapse.node_latest
where
    project_id is not null;  """

    return sql_query


def normalize_project_id(value: object) -> str | None:
    if pd.isna(value):
        return None

    text_value = str(value).strip()
    if text_value.endswith(".0"):
        text_value = text_value[:-2]

    try:
        return str(int(text_value))
    except ValueError:
        return text_value


# Parameter input widgets arranged in a row
(param_col_1,) = st.columns(1)

with param_col_1:
    # Parameter: synapse_project_id
    st.markdown("**Synapse Project Id**")
    df = session.sql(param_query_1()).to_pandas()
    options_synapse_project_id = []
    for raw_value in df.iloc[:, 0]:
        normalized_value = normalize_project_id(raw_value)
        if normalized_value is None:
            continue
        options_synapse_project_id.append(
            {"name": normalized_value, "arg": normalized_value}
        )

    options_synapse_project_id = sorted(
        {opt["name"]: opt for opt in options_synapse_project_id}.values(),
        key=lambda opt: int(opt["name"]) if opt["name"].isdigit() else opt["name"],
    )

    display = [opt["name"] for opt in options_synapse_project_id]
    default_synapse_project_id = [value for value in ["21788217"] if value in display]
    input_synapse_project_id = st.multiselect(
        "Synapse Project Id",
        options=display,
        default=default_synapse_project_id,
        label_visibility="collapsed",
        key="synapse_project_id_param",
    )

st.markdown("---")


@st.cache_data(ttl="23h50m")
def execute_query(query: str) -> str:
    return session.sql(query).collect_nowait().query_id


def query_1_1() -> str:
    filter_expressions = []

    selected_args = [
        opt["arg"]
        for opt in options_synapse_project_id
        if opt["name"] in input_synapse_project_id
    ]
    if selected_args:
        filter_expressions.append(
            f"id IN ({', '.join(repr(str(a)) for a in selected_args)})"
        )

    if filter_expressions:
        expr_synapse_project_id = " OR ".join(
            f"({expr})" for expr in filter_expressions
        )
    else:
        expr_synapse_project_id = "FALSE"

    sql_query = rf"""
select
    name
from
    synapse_data_warehouse.synapse.node_latest
where
    {expr_synapse_project_id};  """

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
                st.markdown("### Project Name")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_1",
                help="Refresh project_name data",
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
    filter_expressions = []

    selected_args = [
        opt["arg"]
        for opt in options_synapse_project_id
        if opt["name"] in input_synapse_project_id
    ]
    if selected_args:
        filter_expressions.append(
            f"project_id IN ({', '.join(repr(str(a)) for a in selected_args)})"
        )

    if filter_expressions:
        expr_synapse_project_id = " OR ".join(
            f"({expr})" for expr in filter_expressions
        )
    else:
        expr_synapse_project_id = "FALSE"

    sql_query = rf"""
select
    count(distinct benefactor_id) as number_of_benefactors
from
    synapse_data_warehouse.synapse.node_latest
where
    {expr_synapse_project_id};  """

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
                st.markdown("### Number of entities with local sharing settings")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_1_2",
                help="Refresh number_of_entities_with_local_sharing_settings data",
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
    filter_expressions = []

    selected_args = [
        opt["arg"]
        for opt in options_synapse_project_id
        if opt["name"] in input_synapse_project_id
    ]
    if selected_args:
        filter_expressions.append(
            f"node_latest.project_id IN ({', '.join(repr(str(a)) for a in selected_args)})"
        )

    if filter_expressions:
        expr_synapse_project_id = " OR ".join(
            f"({expr})" for expr in filter_expressions
        )
    else:
        expr_synapse_project_id = "FALSE"

    sql_query = rf"""
with acl_scrub as (
    SELECT DISTINCT
        acl_latest.*,
        node_latest.project_id,
        CASE 
            WHEN principal_id = 273948 THEN 'All registered Synapse users'
            WHEN principal_id = 273949 THEN 'Anyone on the web'
            ELSE COALESCE(team_latest.name, userprofile_latest.user_name)
        END AS principal_name,
        userprofile_latest.email,
        CASE 
            WHEN principal_id in (273948, 273949) or team_latest.name is not null THEN 'TEAM'
            ELSE 'USER'
        END AS principal_type,
    from
        synapse_data_warehouse.synapse.acl_latest
    inner join
        synapse_data_warehouse.synapse.node_latest
        on acl_latest.owner_id = node_latest.benefactor_id
    LEFT JOIN
        synapse_data_warehouse.synapse.team_latest
        ON acl_latest.principal_id = team_latest.id
    LEFT JOIN
        synapse_data_warehouse.synapse.userprofile_latest
        ON acl_latest.principal_id = userprofile_latest.id
    where
        {expr_synapse_project_id}
)
select
    principal_name, principal_id, principal_type, email, ARRAY_AGG(distinct access_type) as access_types
from
    acl_scrub
group by
    principal_name, principal_id, principal_type, email  """

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
                st.markdown("### Principals with access")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_2_1",
                help="Refresh principals_with_access data",
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
    filter_expressions = []

    selected_args = [
        opt["arg"]
        for opt in options_synapse_project_id
        if opt["name"] in input_synapse_project_id
    ]
    if selected_args:
        filter_expressions.append(
            f"node_latest.project_id IN ({', '.join(repr(str(a)) for a in selected_args)})"
        )

    if filter_expressions:
        expr_synapse_project_id = " OR ".join(
            f"({expr})" for expr in filter_expressions
        )
    else:
        expr_synapse_project_id = "FALSE"

    sql_query = rf"""


-- WITH acl_latest_init AS (
--     SELECT
--         *,
--         ROW_NUMBER() OVER (
--             PARTITION BY OWNER_ID
--             ORDER BY CHANGE_TIMESTAMP DESC, SNAPSHOT_TIMESTAMP DESC
--         ) AS ROW_NUM
--     FROM
--         synapse_data_warehouse.synapse_raw.aclsnapshots
--     WHERE
--         SNAPSHOT_DATE >= CURRENT_TIMESTAMP - INTERVAL '30 DAYS'
-- ), acl_latest as (
--     select
--         owner_id,
--         change_timestamp,
--         snapshot_timestamp,
--         parse_json(resource_access) as acl
--     from
--         acl_latest_init
--     where
--         ROW_NUM = 1
-- ), acl_expanded as (
--     select
--         owner_id,
--         change_timestamp,
--         snapshot_timestamp,
--         COALESCE(
--             array_sort(value:"accesstype"::variant),
--             array_sort(value:"accessType"::variant),
--             array_sort(value:"accesstype#1"::variant),
--             array_sort(value:"accesstype#2"::variant),
--             array_sort(value:"accesstype#3"::variant)
--           ) AS accesstype,
--         COALESCE(
--             value:"principalId"::number,
--             value:"principalid"::number,
--             value:"principalid#1"::number
--           ) AS principalid
--     from 
--         acl_latest,
--         LATERAL FLATTEN(acl, outer=>TRUE)
with acl_scrub as (
    SELECT DISTINCT
        acl_latest.*,
        node_latest.project_id,
        CASE 
            WHEN principal_id = 273948 THEN 'All registered Synapse users'
            WHEN principal_id = 273949 THEN 'Anyone on the web'
            ELSE COALESCE(team_latest.name, userprofile_latest.user_name)
        END AS principal_name,
        CASE 
            WHEN principal_id in (273948, 273949) or team_latest.name is not null THEN 'TEAM'
            ELSE 'USER'
        END AS principal_type,
    from
        synapse_data_warehouse.synapse.acl_latest
    inner join
        synapse_data_warehouse.synapse.node_latest
        on acl_latest.owner_id = node_latest.benefactor_id
    LEFT JOIN
        synapse_data_warehouse.synapse.team_latest
        ON acl_latest.principal_id = team_latest.id
    LEFT JOIN
        synapse_data_warehouse.synapse.userprofile_latest
        ON acl_latest.principal_id = userprofile_latest.id
    where
        {expr_synapse_project_id}
), final_acl as (
    select
        owner_id as id,
        access_type,
        principal_id,
        principal_name,
        principal_type
    from
        acl_scrub
)
select
    node_latest.name,
    node_latest.node_type,
    final_acl.*
from
    final_acl
left join
    synapse_data_warehouse.synapse.node_latest
on
    final_acl.id = node_latest.id  """

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
                st.markdown("### ACL of benefactors")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_3_1",
                help="Refresh acl_of_benefactors data",
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
    filter_expressions = []

    selected_args = [
        opt["arg"]
        for opt in options_synapse_project_id
        if opt["name"] in input_synapse_project_id
    ]
    if selected_args:
        filter_expressions.append(
            f"id IN ({', '.join(repr(str(a)) for a in selected_args)})"
        )

    if filter_expressions:
        expr_synapse_project_id = " OR ".join(
            f"({expr})" for expr in filter_expressions
        )
    else:
        expr_synapse_project_id = "FALSE"

    filter_expressions = []

    selected_args = [
        opt["arg"]
        for opt in options_synapse_project_id
        if opt["name"] in input_synapse_project_id
    ]
    if selected_args:
        filter_expressions.append(
            f"project_id IN ({', '.join(repr(str(a)) for a in selected_args)})"
        )

    if filter_expressions:
        expr_synapse_project_id_1 = " OR ".join(
            f"({expr})" for expr in filter_expressions
        )
    else:
        expr_synapse_project_id_1 = "FALSE"

    sql_query = rf"""
with recursive nodepaths as (

    -- anchor member: start with the top-level nodes where parent_id equals the project_id
    select 
        id,
        project_id as projectid,
        cast(name as varchar) as path,
        parent_id,
        benefactor_id,
        case 
            when benefactor_id = id then true
            else false
        end as local_share_settings,
        (select distinct name from synapse_data_warehouse.synapse.node_latest 
         where {expr_synapse_project_id}) as project_name,
    from 
        synapse_data_warehouse.synapse.node_latest
    where
        {expr_synapse_project_id_1}
        and parent_id = project_id
        and node_type in ('folder', 'file')

    union all

    -- recursive member: add child nodes
    select 
        child.id,
        child.project_id as projectid,
        concat(parent.path, '/', child.name) as path,
        child.parent_id,
        child.benefactor_id,
        -- determine local_share_settings based on the benefactor_id
        case 
            when child.benefactor_id = child.id then true
            else false
        end as local_share_settings,
        parent.project_name,  -- Carrying forward the project name from the parent
    from 
        synapse_data_warehouse.synapse.node_latest child
    join 
        nodepaths parent on child.parent_id = parent.id
    where
        node_type in ('folder', 'file')
)

-- select the desired columns
select 
    id, 
    projectid, 
    path,
    benefactor_id,
    parent_id,
    local_share_settings,
    project_name,   -- Including the project name in the final selection
from 
    nodepaths;  """

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
                st.markdown("### Local Share Settings Audit (Folders & Files)")
            if st.button(
                ":material/refresh:",
                type="tertiary",
                key=f"refresh_button_cell_4_1",
                help="Refresh local_share_settings_audit_(folders_&_files) data",
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


# Footer
st.markdown("---")
st.markdown(
    "*Dashboard loaded: {}*".format(dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
)
