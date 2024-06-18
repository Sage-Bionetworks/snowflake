use role accountadmin;
use schema {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

alter task refresh_synapse_warehouse_s3_stage_task suspend;
create task if not exists append_to_projectsettingsnapshots_task
    user_task_managed_initial_warehouse_size = 'SMALL'
    AFTER refresh_synapse_warehouse_s3_stage_task
as
    copy into
        projectsettingsnapshots
    from (
        select
            $1:change_timestamp as change_timestamp,
            $1:change_type as change_type,
            $1:change_user_id as change_user_id,
            $1:snapshot_timestamp as snapshot_timestamp,
            $1:id as id,
            $1:concrete_type as concrete_type,
            $1:project_id as project_id,
            $1:settings_type as settings_type,
            $1:etag as etag,
            $1:locations as locations,
            NULLIF(
                regexp_replace(
                    METADATA$FILENAME,
                    '.*projectsettingsnapshots\/snapshot_date\=(.*)\/.*',
                    '\\1'),
                '__HIVE_DEFAULT_PARTITION__'
            ) as snapshot_date
        from
            @{{stage_storage_integration}}_stage/projectsettingsnapshots --noqa: TMP
        )
    pattern='.*projectsettingsnapshots/snapshot_date=.*/.*';
alter task append_to_projectsettingsnapshots_task resume;
alter task refresh_synapse_warehouse_s3_stage_task resume;