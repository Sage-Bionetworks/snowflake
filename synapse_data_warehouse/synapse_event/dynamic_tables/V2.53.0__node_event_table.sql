USE SCHEMA {{ database_name }}.SYNAPSE_EVENT;

CREATE OR REPLACE DYNAMIC TABLE node_event
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_medium
    AS
        WITH unique_events AS (
            SELECT
                ID,
                VERSION_NUMBER,
                CHANGE_TYPE,
                MODIFIED_ON,
                MODIFIED_BY,
                NAME,
                NODE_TYPE,
                PARENT_ID,
                BENEFACTOR_ID,
                PROJECT_ID,
                CREATED_ON,
                CREATED_BY,
                FILE_HANDLE_ID,
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
                PROJECT_STORAGE_USAGE,
                CHANGE_TIMESTAMP,
                CHANGE_USER_ID,
                SNAPSHOT_DATE,
                SNAPSHOT_TIMESTAMP
            FROM
                {{ database_name }}.synapse_raw.nodesnapshots --noqa: TMP
            WHERE
                -- only `id`, `change_*`, and `snapshot_*` columns are defined regardless of `change_type`
                id is not null
                and change_type is not null
            QUALIFY ROW_NUMBER() OVER (
                    -- `id` and `version_number` provide at least one record for each Synapse entity version.
                    -- `change_type` ensures that simultaneous events are retained, regardless of their `change_type`.
                    -- `modified_on` enables us to capture updates to Synapse Table entities and other
                    -- update scenarios where the `version_number` does not change (like when we update annotations
                    -- without incrementing the version). 
                    PARTITION BY id, version_number, change_type, modified_on
                    -- Ordering by `snapshot_timestamp` ascending means we keep the first snapshot of this event
                    ORDER BY snapshot_timestamp
                ) = 1
        )
        SELECT
            *
        FROM
            unique_events;
