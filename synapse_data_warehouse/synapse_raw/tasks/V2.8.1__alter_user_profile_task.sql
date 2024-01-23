use role accountadmin;
use schema {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
alter task refresh_synapse_warehouse_s3_stage_task suspend;
alter task userprofilesnapshot_task suspend;
alter task UPSERT_TO_USERPROFILE_LATEST_TASK suspend;
alter task userprofilesnapshot_task MODIFY AS
    copy into
        userprofilesnapshot
    from (
        select
            $1:change_type as change_type,
            $1:change_timestamp as change_timestamp,
            $1:change_user_id as change_user_id,
            $1:snapshot_timestamp as snapshot_timestamp,
            $1:id as id,
            $1:user_name as user_name,
            $1:first_name as first_name,
            $1:last_name as last_name,
            $1:email as email,
            $1:location as location,
            $1:company as company,
            $1:position as position,
            NULLIF(
                REGEXP_REPLACE(
                    metadata$filename,
                    '.*userprofilesnapshots\/snapshot_date\=(.*)\/.*', '\\1'
                ),
                '__HIVE_DEFAULT_PARTITION__'
            ) as snapshot_date
            $1:created_on as created_on
        from
            @{{stage_storage_integration}}_stage/userprofilesnapshots --noqa: TMP
    )
    pattern = '.*userprofilesnapshots/snapshot_date=.*/.*';

alter task UPSERT_TO_USERPROFILE_LATEST_TASK resume;
alter task userprofilesnapshot_task resume;
alter task refresh_synapse_warehouse_s3_stage_task resume;
