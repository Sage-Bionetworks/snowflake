-- Drop any scheduled tasks
USE SCHEMA {{database_name}}.synapse_raw;
-- Suspend ROOT TASK
ALTER TASK REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK SUSPEND;
-- Drop LATEST_TABLE UPSERTING TASK
DROP TASK UPSERT_TO_USERPROFILE_LATEST_TASK;
-- Resume the ROOT task and its child tasks
SELECT SYSTEM$TASK_DEPENDENTS_ENABLE( 'REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK' );