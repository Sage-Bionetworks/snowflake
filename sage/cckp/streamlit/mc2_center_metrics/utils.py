import streamlit as st

GRANULARITY_OPTIONS = ["Daily", "Weekly", "Monthly"]
RESAMPLE_FREQ = {"Daily": "D", "Weekly": "W-MON", "Monthly": "MS"}


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

# CTE to get CCKP dataset entities.
SQL_CTE_MC2_DATASET_NODES = """\
    mc2_dataset_nodes AS (
        SELECT DISTINCT
            id,
            node_type,
            name AS dataset_name,
            file_handle_id,
            project_id,
            project_name
        FROM sage.cckp.mc2_nodes
        WHERE node_type IN ('dataset', 'datasetcollection')
    )"""

# CTE to expand dataset/datasetcollection items into file rows, where:
#   dataset -> files
#   datasetcollection -> datasets -> files
SQL_CTE_MC2_DATASET_FILES = """\
    mc2_dataset_files AS (
        -- case 1: dataset entities -> file items
        SELECT DISTINCT
            d.dataset_name,
            d.project_id,
            d.project_name,
            n.id              AS file_entity_id,
            n.file_handle_id
        FROM mc2_dataset_nodes d
        INNER JOIN synapse_data_warehouse.synapse.node_latest nl ON nl.id = d.id,
        LATERAL FLATTEN(input => nl.items) AS item
        INNER JOIN sage.cckp.mc2_nodes n
            ON n.id = TRY_CAST(REPLACE(item.value:entityId::STRING, 'syn', '') AS BIGINT)
        WHERE n.file_handle_id IS NOT NULL
            AND d.node_type = 'dataset'

        UNION

        -- case 2: datasetcollection entities -> dataset items -> file items
        SELECT DISTINCT
            dc.dataset_name,
            dc.project_id,
            dc.project_name,
            n.id              AS file_entity_id,
            n.file_handle_id
        FROM mc2_dataset_nodes dc
        INNER JOIN synapse_data_warehouse.synapse.node_latest nl_dc ON nl_dc.id = dc.id,
        LATERAL FLATTEN(input => nl_dc.items) AS ds_item
        INNER JOIN synapse_data_warehouse.synapse.node_latest nl_ds
            ON nl_ds.id = TRY_CAST(REPLACE(ds_item.value:entityId::STRING, 'syn', '') AS BIGINT),
        LATERAL FLATTEN(input => nl_ds.items) AS file_item
        INNER JOIN sage.cckp.mc2_nodes n
            ON n.id = TRY_CAST(REPLACE(file_item.value:entityId::STRING, 'syn', '') AS BIGINT)
        WHERE n.file_handle_id IS NOT NULL
            AND dc.node_type = 'datasetcollection'
    )"""
