USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE DYNAMIC TABLE NODE_LATEST
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
                {{database_name}}.synapse_raw.nodesnapshots --noqa: TMP
            WHERE
                SNAPSHOT_TIMESTAMP >= CURRENT_TIMESTAMP - INTERVAL '30 DAYS'
            QUALIFY ROW_NUMBER() OVER (
                    PARTITION BY id
                    ORDER BY change_timestamp DESC, snapshot_timestamp DESC
                ) = 1
        )
        SELECT
            *
        FROM
            latest_unique_rows
        WHERE
            NOT (CHANGE_TYPE = 'DELETE' OR BENEFACTOR_ID = '1681355' OR PARENT_ID = '1681355') -- 1681355 is the synID of the trash can on Synapse
        ORDER BY
            latest_unique_rows.id ASC;
