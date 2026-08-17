import streamlit as st


@st.cache_data(ttl="23h50m")
def execute_query(query: str) -> str:
    return st.session_state.session.sql(query).collect_nowait().query_id


def rename_duplicate_columns(df):
    """Append a numeric suffix to duplicate column names.

    This function acts as a safety net, in case a query produces duplicate
    column names that would otherwise cause st.dataframe to error.
    """
    if not any(df.columns.duplicated()):
        return df
    new_names = []
    name_indexes = {}
    for name in df.columns:
        idx = name_indexes.get(name, 0) + 1
        name_indexes[name] = idx
        new_names.append(f"{name}_{idx}" if idx > 1 else name)
    df.columns = new_names
    return df


# CTE to get external users (non-Sagers).
SQL_CTE_NON_SAGERS = """\
    non_sagers AS (
        SELECT 
            id AS user_id,
            user_name
        FROM
            synapse_data_warehouse.synapse.userprofile_latest
        WHERE
            email NOT ILIKE '%@sagebase.org'
            AND email NOT ILIKE '%@sagebionetworks.org'
    )"""

# CTE to get Sagers vs externals (based on email).
SQL_CTE_SYNAPSE_USERS = """\
    synapse_users AS (
        SELECT
            id,
            CASE
                WHEN email ILIKE '%@sagebase.org'
                  OR email ILIKE '%@sagebionetworks.org' THEN 'Sager'
                ELSE 'External'
            END AS user_type
        FROM
            synapse_data_warehouse.synapse.userprofile_latest
    )"""

# CTE to get CCKP-annotated dataset entities from mc2_nodes.
SQL_CTE_MC2_DATASET_NODES = """\
    mc2_dataset_nodes AS (
        SELECT
            id,
            file_handle_id,
            name AS dataset_name,
            project_id,
            project_name
        FROM
            sage.cckp.mc2_nodes
        WHERE
            annotations:annotations:portal.value[0]::string = 'CCKP'
            AND annotations:annotations:entityType.value[0]::string = 'dataset'
    )"""

# CTE to get all CCKP dataset files — direct files and files nested one
# level inside a dataset/folder container.
SQL_CTE_MC2_DATASET_FILES = """\
    mc2_dataset_files AS (
        -- File entities directly annotated as a CCKP dataset
        SELECT
            id AS file_entity_id,
            file_handle_id,
            dataset_name,
            project_id,
            project_name
        FROM
            mc2_dataset_nodes
        WHERE
            file_handle_id IS NOT NULL

        UNION ALL

        -- Files nested one level inside dataset/folder entities
        SELECT
            child.id AS file_entity_id,
            child.file_handle_id,
            parent.dataset_name,
            parent.project_id,
            parent.project_name
        FROM
            sage.cckp.mc2_nodes child
        INNER JOIN
            mc2_dataset_nodes parent ON child.parent_id = parent.id
        WHERE
            parent.file_handle_id IS NULL        -- parent is a folder/dataset
            AND child.file_handle_id IS NOT NULL -- child must be a file
    )"""
