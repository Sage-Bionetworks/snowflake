use role accountadmin;
use schema {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
alter task refresh_synapse_warehouse_s3_stage_task suspend;
alter task FILEDOWNLOAD_TASK suspend;
alter task CLONE_FILEDOWNLOAD_TASK suspend;
alter task FILEDOWNLOAD_TASK MODIFY AS
    copy into
        filedownload
    from (
        select
            $1:timestamp as timestamp,
            $1:user_id as user_id,
            $1:project_id as project_id,
            $1:file_handle_id as file_handle_id,
            $1:downloaded_file_handle_id as downloaded_file_handle_id,
            $1:association_object_id as association_object_id,
            $1:association_object_type as association_object_type,
            $1:stack as stack,
            $1:instance as instance,
            NULLIF(
                REGEXP_REPLACE(
                    metadata$filename,
                    '.*filedownloadrecords\/record_date\=(.*)\/.*',
                    '\\1'
                ),
                '__HIVE_DEFAULT_PARTITION__'
            ) as record_date,
            $1:session_id as session_id
        from
            @{{stage_storage_integration}}_stage/filedownloadrecords --noqa: TMP
    )
    pattern = '.*filedownloadrecords/record_date=.*/.*';

alter task CLONE_FILEDOWNLOAD_TASK resume;
alter task FILEDOWNLOAD_TASK resume;
alter task refresh_synapse_warehouse_s3_stage_task resume;
