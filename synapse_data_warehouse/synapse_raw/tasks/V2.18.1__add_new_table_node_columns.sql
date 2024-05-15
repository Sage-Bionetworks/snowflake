use role accountadmin;
use schema {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
alter task refresh_synapse_warehouse_s3_stage_task suspend;
alter task NODESNAPSHOT_TASK suspend;
alter task UPSERT_TO_NODE_LATEST_TASK suspend;
alter task REMOVE_DELETE_NODES_TASK suspend;

alter task NODESNAPSHOT_TASK MODIFY AS
    copy into
        nodesnapshots
    from (
        select
            $1:change_type as change_type,
            $1:change_timestamp as change_timestamp,
            $1:change_user_id as change_user_id,
            $1:snapshot_timestamp as snapshot_timestamp,
            $1:id as id,
            $1:benefactor_id as benefactor_id,
            $1:project_id as project_id,
            $1:parent_id as parent_id,
            $1:node_type as node_type,
            $1:created_on as created_on,
            $1:created_by as created_by,
            $1:modified_on as modified_on,
            $1:modified_by as modified_by,
            $1:version_number as version_number,
            $1:file_handle_id as file_handle_id,
            $1:name as name,
            $1:is_public as is_public,
            $1:is_controlled as is_controlled,
            $1:is_restricted as is_restricted,
            NULLIF(
                REGEXP_REPLACE(
                    metadata$filename,
                    '.*nodesnapshots\/snapshot_date\=(.*)\/.*', '\\1'
                ),
                '__HIVE_DEFAULT_PARTITION__'
            ) as snapshot_date,
            $1:effective_ars as effective_ars,
            parse_json(replace(replace($1:annotations, '\n', '\\n'), '\r', '\\r')) as annotations,
            parse_json(replace(replace($1:derived_annotations, '\n', '\\n'), '\r', '\\r')) as derived_annotations,
            $1:version_comment as version_comment,
            $1:version_label as version_label,
            $1:alias as alias,
            $1:activity_id as activity_id,
            parse_json($1:column_model_ids) as column_model_ids,
            parse_json($1:scope_ids) as scope_ids,
            parse_json($1:items) as items,
            parse_json($1:reference) as reference,
            $1:is_search_enabled as is_search_enabled,
            $1:defining_sql as defining_sql,
            $1:is_public as is_public,
            $1:is_controlled as is_controlled,
            $1:is_restricted as is_restricted,
            parse_json(replace(replace($1:internal_annotations, '\n', '\\n'), '\r', '\\r')) as internal_annotations
        from @{{stage_storage_integration}}_stage/nodesnapshots/ --noqa: TMP
    )
    pattern = '.*nodesnapshots/snapshot_date=.*/.*';

alter task upsert_to_node_latest_task MODIFY AS
    MERGE INTO {{database_name}}.SYNAPSE.NODE_LATEST AS TARGET_TABLE --noqa: TMP
    USING (
        WITH RANKED_NODES AS (
            SELECT
                *,
                "row_number"()
                    OVER (
                        PARTITION BY ID
                        ORDER BY CHANGE_TIMESTAMP DESC, SNAPSHOT_TIMESTAMP DESC
                    )
                    AS N
            FROM NODESNAPSHOTS_STREAM
        )

        SELECT * EXCLUDE N
        FROM RANKED_NODES
        WHERE N = 1
    ) AS SOURCE_TABLE ON TARGET_TABLE.ID = SOURCE_TABLE.ID
    WHEN MATCHED THEN
        UPDATE SET
            TARGET_TABLE.CHANGE_TYPE = SOURCE_TABLE.CHANGE_TYPE,
            TARGET_TABLE.CHANGE_TIMESTAMP = SOURCE_TABLE.CHANGE_TIMESTAMP,
            TARGET_TABLE.CHANGE_USER_ID = SOURCE_TABLE.CHANGE_USER_ID,
            TARGET_TABLE.SNAPSHOT_TIMESTAMP = SOURCE_TABLE.SNAPSHOT_TIMESTAMP,
            TARGET_TABLE.ID = SOURCE_TABLE.ID,
            TARGET_TABLE.BENEFACTOR_ID = SOURCE_TABLE.BENEFACTOR_ID,
            TARGET_TABLE.PROJECT_ID = SOURCE_TABLE.PROJECT_ID,
            TARGET_TABLE.PARENT_ID = SOURCE_TABLE.PARENT_ID,
            TARGET_TABLE.NODE_TYPE = SOURCE_TABLE.NODE_TYPE,
            TARGET_TABLE.CREATED_ON = SOURCE_TABLE.CREATED_ON,
            TARGET_TABLE.CREATED_BY = SOURCE_TABLE.CREATED_BY,
            TARGET_TABLE.MODIFIED_ON = SOURCE_TABLE.MODIFIED_ON,
            TARGET_TABLE.MODIFIED_BY = SOURCE_TABLE.MODIFIED_BY,
            TARGET_TABLE.VERSION_NUMBER = SOURCE_TABLE.VERSION_NUMBER,
            TARGET_TABLE.FILE_HANDLE_ID = SOURCE_TABLE.FILE_HANDLE_ID,
            TARGET_TABLE.NAME = SOURCE_TABLE.NAME,
            TARGET_TABLE.IS_PUBLIC = SOURCE_TABLE.IS_PUBLIC,
            TARGET_TABLE.IS_CONTROLLED = SOURCE_TABLE.IS_CONTROLLED,
            TARGET_TABLE.IS_RESTRICTED = SOURCE_TABLE.IS_RESTRICTED,
            TARGET_TABLE.SNAPSHOT_DATE = SOURCE_TABLE.SNAPSHOT_DATE,
            TARGET_TABLE.EFFECTIVE_ARS = SOURCE_TABLE.EFFECTIVE_ARS,
            TARGET_TABLE.ANNOTATIONS = SOURCE_TABLE.ANNOTATIONS,
            TARGET_TABLE.DERIVED_ANNOTATIONS = SOURCE_TABLE.DERIVED_ANNOTATIONS,
            TARGET_TABLE.VERSION_COMMENT = SOURCE_TABLE.VERSION_COMMENT,
            TARGET_TABLE.VERSION_LABEL = SOURCE_TABLE.VERSION_LABEL,
            TARGET_TABLE.ALIAS = SOURCE_TABLE.ALIAS,
            TARGET_TABLE.ACTIVITY_ID = SOURCE_TABLE.ACTIVITY_ID,
            TARGET_TABLE.COLUMN_MODEL_IDS = SOURCE_TABLE.COLUMN_MODEL_IDS,
            TARGET_TABLE.SCOPE_IDS = SOURCE_TABLE.SCOPE_IDS,
            TARGET_TABLE.ITEMS = SOURCE_TABLE.ITEMS,
            TARGET_TABLE.REFERENCE = SOURCE_TABLE.REFERENCE,
            TARGET_TABLE.IS_SEARCH_ENABLED = SOURCE_TABLE.IS_SEARCH_ENABLED,
            TARGET_TABLE.DEFINING_SQL = SOURCE_TABLE.DEFINING_SQL,
            TARGET_TABLE.INTERNAL_ANNOTATIONS = SOURCE_TABLE.INTERNAL_ANNOTATIONS
    WHEN NOT MATCHED THEN
        INSERT (CHANGE_TYPE, CHANGE_TIMESTAMP, CHANGE_USER_ID, SNAPSHOT_TIMESTAMP, ID, BENEFACTOR_ID, PROJECT_ID, PARENT_ID, NODE_TYPE, CREATED_ON, CREATED_BY, MODIFIED_ON, MODIFIED_BY, VERSION_NUMBER, FILE_HANDLE_ID, NAME, IS_PUBLIC, IS_CONTROLLED, IS_RESTRICTED, SNAPSHOT_DATE, EFFECTIVE_ARS, ANNOTATIONS, DERIVED_ANNOTATIONS, , VERSION_COMMENT, VERSION_LABEL, ALIAS, ACTIVITY_ID, COLUMN_MODEL_IDS, SCOPE_IDS, ITEMS, REFERENCE, IS_SEARCH_ENABLED, DEFINING_SQL, INTERNAL_ANNOTATIONS)
        VALUES (SOURCE_TABLE.CHANGE_TYPE, SOURCE_TABLE.CHANGE_TIMESTAMP, SOURCE_TABLE.CHANGE_USER_ID, SOURCE_TABLE.SNAPSHOT_TIMESTAMP, SOURCE_TABLE.ID, SOURCE_TABLE.BENEFACTOR_ID, SOURCE_TABLE.PROJECT_ID, SOURCE_TABLE.PARENT_ID, SOURCE_TABLE.NODE_TYPE, SOURCE_TABLE.CREATED_ON, SOURCE_TABLE.CREATED_BY, SOURCE_TABLE.MODIFIED_ON, SOURCE_TABLE.MODIFIED_BY, SOURCE_TABLE.VERSION_NUMBER, SOURCE_TABLE.FILE_HANDLE_ID, SOURCE_TABLE.NAME, SOURCE_TABLE.IS_PUBLIC, SOURCE_TABLE.IS_CONTROLLED, SOURCE_TABLE.IS_RESTRICTED, SOURCE_TABLE.SNAPSHOT_DATE, SOURCE_TABLE.EFFECTIVE_ARS, SOURCE_TABLE.ANNOTATIONS, SOURCE_TABLE.DERIVED_ANNOTATIONS,  SOURCE_TABLE.VERSION_COMMENT, SOURCE_TABLE.VERSION_LABEL, SOURCE_TABLE.ALIAS, SOURCE_TABLE.ACTIVITY_ID, SOURCE_TABLE.COLUMN_MODEL_IDS, SOURCE_TABLE.SCOPE_IDS, SOURCE_TABLE.ITEMS, SOURCE_TABLE.REFERENCE, SOURCE_TABLE.IS_SEARCH_ENABLED, SOURCE_TABLE.DEFINING_SQL, SOURCE_TABLE.INTERNAL_ANNOTATIONS);
SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('refresh_synapse_warehouse_s3_stage_task');
