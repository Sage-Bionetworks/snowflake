USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Drop the task that clones to the deprecated synapse.filedownload table
-- This task was created in V1.14.0 and is no longer needed as consumers
-- have migrated to synapse_event.objectdownload_event (a dynamic table)
ALTER TASK REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK SUSPEND;
DROP TASK IF EXISTS clone_filedownload_task;
SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK');
