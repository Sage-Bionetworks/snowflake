USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Momentarily suspend the ROOT task so we can remove the child tasks
ALTER TASK IF EXISTS REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK SUSPEND;

-- Remove the tasks in question
DROP TASK IF EXISTS UPSERT_TO_NODE_LATEST_TASK;
DROP TASK IF EXISTS REMOVE_DELETE_NODES_TASK;

-- Resume the ROOT task and its child tasks
SELECT SYSTEM$TASK_DEPENDENTS_ENABLE( 'REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK' );