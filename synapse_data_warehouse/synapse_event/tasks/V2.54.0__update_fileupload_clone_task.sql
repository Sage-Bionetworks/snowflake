use schema {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Step 1) Pause the upstream tasks & the task of interest before updating
alter task refresh_synapse_warehouse_s3_stage_task suspend;
alter task fileupload_task suspend;
alter task clone_fileupload_task suspend;

-- Step 2) Replace the task of interest
create or replace task clone_fileupload_task
    after fileupload_task
    as
        create or replace table {{database_name}}.synapse_event.fileupload_event --noqa: TMP
        clone fileupload;

-- Step 3) Resume the upstream tasks & the task of interest
alter task clone_fileupload_task resume;
alter task fileupload_task resume;
alter task refresh_synapse_warehouse_s3_stage_task resume;

-- Step 4) Add a primary key to the event table
alter table {{database_name}}.synapse_event.fileupload_event --noqa: JJ01,PRS,TMP
    add constraint fileupload_event_primary_key
    primary key (user_id, file_handle_id);
