USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Momentarily suspend the ROOT task so we can remove the child tasks
ALTER TASK REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK SUSPEND;

-- Remove the tasks in question
DROP TASK UPSERT_TO_CERTIFIEDQUIZQUESTION_LATEST_TASK;

-- Resume the ROOT task and its child tasks
SELECT SYSTEM$TASK_DEPENDENTS_ENABLE( 'REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK' );
