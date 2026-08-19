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

# CTE to join each node with its parent node's name.
SQL_CTE_NODES_WITH_PARENT = """\
    nodes_with_parent AS (
        SELECT
            child.*,
            parent.name AS parent_name
        FROM sage.cckp.mc2_nodes AS child
        LEFT JOIN sage.cckp.mc2_nodes AS parent
            ON child.parent_id = parent.id
    )"""

# CTE to get CCKP-annotated dataset entities from mc2_nodes, based on 3 criteria:
#   Rule 1 — Native dataset/datasetcollection nodes (any portal annotation).
#   Rule 2 — Files or folders explicitly annotated with portal=CCKP, entityType=dataset.
#   Rule 3 — Unannotated, non-manifest files inside a folder named "datasets"
#             (the parent folder is the canonical dataset entity).
# Includes matched_rule for troubleshooting.
SQL_CTE_MC2_DATASET_NODES = """\
    mc2_dataset_nodes AS (
        SELECT DISTINCT
            n.id,
            n.name AS dataset_name,
            n.file_handle_id,
            n.project_id,
            n.project_name,
            classified.matched_rule
        FROM (
            SELECT
                CASE
                    -- Rule 1: Native dataset entities (any portal)
                    WHEN LOWER(node_type) IN ('dataset', 'datasetcollection')
                    THEN id
                    -- Rule 2: Explicitly annotated CCKP files/folders
                    WHEN LOWER(node_type) IN ('file', 'folder')
                         AND LOWER(annotations:annotations:portal.value[0]::string) = 'cckp'
                         AND LOWER(annotations:annotations:entityType.value[0]::string) = 'dataset'
                    THEN id
                    -- Rule 3: Unannotated files in a "datasets" folder → parent is the dataset
                    WHEN LOWER(node_type) = 'file'
                         AND name NOT ILIKE 'synapse_storage_manifest_%'
                         AND annotations:annotations:portal IS NULL
                         AND annotations:annotations:entityType IS NULL
                         AND LOWER(parent_name) = 'datasets'
                    THEN parent_id
                END AS dataset_id,
                CASE
                    WHEN LOWER(node_type) IN ('dataset', 'datasetcollection')
                    THEN 'Rule 1'
                    WHEN LOWER(node_type) IN ('file', 'folder')
                         AND LOWER(annotations:annotations:portal.value[0]::string) = 'cckp'
                         AND LOWER(annotations:annotations:entityType.value[0]::string) = 'dataset'
                    THEN 'Rule 2'
                    WHEN LOWER(node_type) = 'file'
                         AND name NOT ILIKE 'synapse_storage_manifest_%'
                         AND annotations:annotations:portal IS NULL
                         AND annotations:annotations:entityType IS NULL
                         AND LOWER(parent_name) = 'datasets'
                    THEN 'Rule 3'
                END AS matched_rule
            FROM nodes_with_parent
        ) classified
        INNER JOIN sage.cckp.mc2_nodes n ON n.id = classified.dataset_id
        WHERE classified.dataset_id IS NOT NULL
    )"""

# CTE to get all CCKP dataset files — direct files and files nested one
# level inside a dataset/folder container.
SQL_CTE_MC2_DATASET_FILES = """\
    mc2_dataset_files AS (
        -- File entities that are themselves the dataset node
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
            child.file_handle_id IS NOT NULL
            AND child.name NOT ILIKE 'synapse_storage_manifest_%'
    )"""
