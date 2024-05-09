use role accountadmin;
use schema {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
alter task refresh_synapse_warehouse_s3_stage_task suspend;
create task if not exists append_to_fileassociation_task
    user_task_managed_initial_warehouse_size = 'SMALL'
    AFTER refresh_synapse_warehouse_s3_stage_task
as
    copy into
        filehandle_association
    from (
        select
            $1:associateid as associateid,
            $1:associatetype as associatetype,
            $1:filehandleid as filehandleid,
            $1:instance as instance,
            $1:stack as stack,
            $1:timestamp as timestamp
        from
            @synapse_filehandles_stage --noqa: TMP
    );
SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('refresh_synapse_warehouse_s3_stage_task');
