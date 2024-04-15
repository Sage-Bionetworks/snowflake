use role accountadmin;
use schema {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
alter task refresh_synapse_warehouse_s3_stage_task suspend;
alter task filesnapshots_task suspend;
alter task UPSERT_TO_FILE_LATEST_TASK suspend;
alter task REMOVE_DELETE_FILES_TASK suspend;
alter task filesnapshots_task MODIFY AS
    copy into filesnapshots from (
        select
            $1:change_type as change_type,
            $1:change_timestamp as change_timestamp,
            $1:change_user_id as change_user_id,
            $1:snapshot_timestamp as snapshot_timestamp,
            $1:id as id,
            $1:created_by as created_by,
            $1:created_on as created_on,
            $1:modified_on as modified_on,
            $1:concrete_type as concrete_type,
            $1:content_md5 as content_md5,
            $1:content_type as content_type,
            $1:file_name as file_name,
            $1:storage_location_id as storage_location_id,
            $1:content_size as content_size,
            $1:bucket as bucket,
            $1:key as key,
            $1:preview_id as preview_id,
            $1:is_preview as is_preview,
            $1:status as status,
            NULLIF(
                REGEXP_REPLACE(
                    metadata$filename,
                    '.*filesnapshots\/snapshot_date\=(.*)\/.*',
                    '\\1'
                ),
                '__HIVE_DEFAULT_PARTITION__'
            ) as snapshot_date
        from
            @{{stage_storage_integration}}_stage/filesnapshots --noqa: TMP
    )
    pattern = '.*filesnapshots/snapshot_date=.*/.*';

alter task REMOVE_DELETE_FILES_TASK resume;
alter task UPSERT_TO_FILE_LATEST_TASK resume;
alter task filesnapshots_task resume;
alter task refresh_synapse_warehouse_s3_stage_task resume;
