USE SCHEMA {{ database_name }}.SYNAPSE_EVENT;

CREATE OR REPLACE DYNAMIC TABLE node_event
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    AS
        WITH latest_unique_rows AS (
            SELECT
                CHANGE_TYPE,
                CHANGE_TIMESTAMP,
                CHANGE_USER_ID,
                SNAPSHOT_TIMESTAMP,
                ID,
                BENEFACTOR_ID,
                PROJECT_ID,
                PARENT_ID,
                NODE_TYPE,
                CREATED_ON,
                CREATED_BY,
                MODIFIED_ON,
                MODIFIED_BY,
                VERSION_NUMBER,
                FILE_HANDLE_ID,
                NAME,
                IS_PUBLIC,
                IS_CONTROLLED,
                IS_RESTRICTED,
                SNAPSHOT_DATE,
                EFFECTIVE_ARS,
                ANNOTATIONS,
                DERIVED_ANNOTATIONS,
                VERSION_COMMENT,
                VERSION_LABEL,
                ALIAS,
                ACTIVITY_ID,
                COLUMN_MODEL_IDS,
                SCOPE_IDS,
                ITEMS,
                REFERENCE,
                IS_SEARCH_ENABLED,
                DEFINING_SQL,
                INTERNAL_ANNOTATIONS,
                VERSION_HISTORY,
                PROJECT_STORAGE_USAGE
            FROM
                {{ database_name }}.synapse_raw.nodesnapshots --noqa: TMP
            WHERE
                snapshot_timestamp >= CURRENT_TIMESTAMP - INTERVAL '30 DAYS'
            QUALIFY ROW_NUMBER OVER (
                    PARTITION BY id, version_number
                    ORDER BY change_timestamp DESC, snapshot_timestamp DESC
                ) = 1
        )
        SELECT
            ID,
            VERSION_NUMBER,
            CHANGE_TYPE,
            CHANGE_TIMESTAMP,
            CHANGE_USER_ID,
            NODE_TYPE,
            PARENT_ID,
            BENEFACTOR_ID,
            PROJECT_ID,
            CREATED_ON,
            CREATED_BY,
            MODIFIED_ON,
            MODIFIED_BY,
            FILE_HANDLE_ID,
            PROJECT_STORAGE_USAGE
            NAME,
            IS_PUBLIC,
            IS_CONTROLLED,
            IS_RESTRICTED,
            EFFECTIVE_ARS,
            ANNOTATIONS,
            INTERNAL_ANNOTATIONS,
            DERIVED_ANNOTATIONS,
            VERSION_COMMENT,
            VERSION_LABEL,
            VERSION_HISTORY,
            ACTIVITY_ID,
            COLUMN_MODEL_IDS,
            SCOPE_IDS,
            ITEMS,
            REFERENCE,
            IS_SEARCH_ENABLED,
            DEFINING_SQL,
            ALIAS,
            SNAPSHOT_DATE,
            SNAPSHOT_TIMESTAMP
        FROM
            latest_unique_rows;