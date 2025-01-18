-- Configure environment
USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP,CP02

-- Suspend the root task
ALTER TASK refresh_synapse_warehouse_s3_stage_task SUSPEND;

-- Suspend the child task in question
ALTER TASK nodesnapshot_task SUSPEND;

-- Add the new column to the child task
ALTER TASK nodesnapshot_task MODIFY AS
	COPY INTO
        nodesnapshots
    FROM (
        SELECT
            $1:change_type AS change_type,
            $1:change_timestamp AS change_timestamp,
            $1:change_user_id AS change_user_id,
            $1:snapshot_timestamp AS snapshot_timestamp,
            $1:id AS id,
            $1:benefactor_id AS benefactor_id,
            $1:project_id AS project_id,
            $1:parent_id AS parent_id,
            $1:node_type AS node_type,
            $1:created_on AS created_on,
            $1:created_by AS created_by,
            $1:modified_on AS modified_on,
            $1:modified_by AS modified_by,
            $1:version_number AS version_number,
            $1:file_handle_id AS file_handle_id,
            $1:name AS name,
            $1:is_public AS is_public,
            $1:is_controlled AS is_controlled,
            $1:is_restricted AS is_restricted,
            NULLIF(
                REGEXP_REPLACE(
                    metadata$filename,
                    '.*nodesnapshots\/snapshot_date\=(.*)\/.*', '\\1'
                ),
                '__HIVE_DEFAULT_PARTITION__'
            ) AS snapshot_date,
            $1:effective_ars AS effective_ars,
            PARSE_JSON(REPLACE(REPLACE($1:annotations, '\n', '\\n'), '\r', '\\r')) AS annotations,
            PARSE_JSON(REPLACE(REPLACE($1:derived_annotations, '\n', '\\n'), '\r', '\\r')) AS derived_annotations,
            $1:version_comment AS version_comment,
            $1:version_label AS version_label,
            $1:alias AS alias,
            $1:activity_id AS activity_id,
            PARSE_JSON($1:column_model_ids) AS column_model_ids,
            PARSE_JSON($1:scope_ids) AS scope_ids,
            PARSE_JSON($1:items) AS items,
            PARSE_JSON($1:reference) AS reference,
            $1:is_search_enabled AS is_search_enabled,
            $1:defining_sql AS defining_sql,
            PARSE_JSON(REPLACE(REPLACE($1:internal_annotations, '\n', '\\n'), '\r', '\\r')) AS internal_annotations,
            PARSE_JSON(REPLACE(REPLACE($1:version_history, '\n', '\\n'), '\r', '\\r')) AS version_history,
            PARSE_JSON(REPLACE(REPLACE($1:project_storage_usage, '\n', '\\n'), '\r', '\\r')) AS project_storage_usage
        from
            @{{stage_storage_integration}}_stage/nodesnapshots/ --noqa: TMP
    )
    pattern = '.*nodesnapshots/snapshot_date=.*/.*';

-- Resume the ROOT task and its child task
SELECT SYSTEM$TASK_DEPENDENTS_ENABLE( 'refresh_synapse_warehouse_s3_stage_task' );
