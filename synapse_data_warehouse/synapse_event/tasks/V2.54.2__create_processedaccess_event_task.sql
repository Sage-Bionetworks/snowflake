use database {{database_name}}; --noqa: JJ01,PRS,TMP

-- Step 1) Pause the upstream tasks
alter task synapse_raw.refresh_synapse_warehouse_s3_stage_task suspend;
alter task synapse_raw.processedaccess_task suspend;

-- Step 2) Create the task of interest
create or replace task synapse_event.create_access_event_task
after synapse_raw.processedaccess_task
as
    create or replace table synapse_event.access_event
    clone synapse_raw.processedaccess;

-- Step 3) Resume the ROOT task and its child tasks
SELECT SYSTEM$TASK_DEPENDENTS_ENABLE( 'synapse_raw.REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK' );
