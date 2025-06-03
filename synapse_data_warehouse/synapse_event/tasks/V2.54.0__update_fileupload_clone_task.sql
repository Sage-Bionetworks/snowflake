use database {{database_name}}; --noqa: JJ01,PRS,TMP

-- Step 1) Pause the upstream tasks & the task of interest before updating
alter task synapse_raw.refresh_synapse_warehouse_s3_stage_task suspend;
alter task synapse_raw.fileupload_task suspend;
alter task synapse_raw.clone_fileupload_task suspend;

-- Step 2) Replace the task of interest
create or replace task synapse_raw.clone_fileupload_task
after synapse_raw.fileupload_task
as
    create or replace table synapse_event.fileupload_event
    clone synapse_raw.fileupload;

-- Step 3) Resume the upstream tasks & the task of interest
alter task synapse_raw.clone_fileupload_task resume;
alter task synapse_raw.fileupload_task resume;
alter task synapse_raw.refresh_synapse_warehouse_s3_stage_task resume;

-- Step 4) Add a primary key to the event table
alter table synapse_event.fileupload_event
add constraint fileupload_event_primary_key
primary key (user_id, file_handle_id);
