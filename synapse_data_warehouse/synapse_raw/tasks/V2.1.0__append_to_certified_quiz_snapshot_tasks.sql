use role accountadmin;
use schema {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
alter task refresh_synapse_warehouse_s3_stage_task suspend;
create task if not exists append_to_certifiedquizsnapshot_task
    user_task_managed_initial_warehouse_size = 'SMALL'
    AFTER refresh_synapse_warehouse_s3_stage_task
as
    copy into
        certifiedquizsnapshots
    from (
        select
            $1:change_type as change_type,
            $1:change_timestamp as change_timestamp,
            $1:snapshot_timestamp as snapshot_timestamp,
            $1:response_id as response_id,
            $1:user_id as user_id,
            $1:passed as passed,
            $1:passed_on as passed_on,
            $1:stack as stack,
            $1:instance as instance,
            NULLIF(
                regexp_replace(
                    METADATA$FILENAME,
                    '.*certifiedquizsnapshots\/snapshot_date\=(.*)\/.*',
                    '\\1'),
                '__HIVE_DEFAULT_PARTITION__'
            ) as snapshot_date
        from
            @{{stage_storage_integration}}_stage/certifiedquizsnapshots --noqa: TMP
        )
    pattern='.*certifiedquizsnapshots/snapshot_date=.*/.*';

create task if not exists append_to_certifiedquizquestionsnapshots_task
    user_task_managed_initial_warehouse_size = 'SMALL'
    AFTER refresh_synapse_warehouse_s3_stage_task
as
    copy into
        certifiedquizquestionsnapshots
    from (
        select
            $1:change_type as change_type,
            $1:change_timestamp as change_timestamp,
            $1:change_user_id as change_user_id,
            $1:snapshot_timestamp as snapshot_timestamp,
            $1:response_id as response_id,
            $1:question_index as question_index,
            $1:is_correct as is_correct,
            $1:stack as stack,
            $1:instance as instance,
            NULLIF(
                regexp_replace(
                    METADATA$FILENAME,
                    '.*certifiedquizquestionsnapshots\/snapshot_date\=(.*)\/.*',
                    '\\1'),
                '__HIVE_DEFAULT_PARTITION__'
            ) as snapshot_date
        from
            @{{stage_storage_integration}}_stage/certifiedquizquestionsnapshots --noqa: TMP
        )
        pattern='.*certifiedquizquestionsnapshots/snapshot_date=.*/.*';

alter task append_to_certifiedquizsnapshot_task resume;
alter task append_to_certifiedquizquestionsnapshots_task resume;
alter task refresh_synapse_warehouse_s3_stage_task resume;
