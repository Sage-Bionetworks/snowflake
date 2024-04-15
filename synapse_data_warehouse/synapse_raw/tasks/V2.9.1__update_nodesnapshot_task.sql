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
            $1:effective_ars as effective_ars
        from @{{stage_storage_integration}}_stage/nodesnapshots/ --noqa: TMP
    )
    pattern = '.*nodesnapshots/snapshot_date=.*/.*';

alter task REMOVE_DELETE_NODES_TASK resume;
alter task UPSERT_TO_NODE_LATEST_TASK resume;
alter task NODESNAPSHOT_TASK resume;
alter task refresh_synapse_warehouse_s3_stage_task resume;
