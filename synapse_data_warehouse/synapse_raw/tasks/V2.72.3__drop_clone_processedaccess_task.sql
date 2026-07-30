USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Drop the task that clones to the deprecated synapse.processedaccess table
-- This task was created in V1.14.0 and is no longer needed as consumers
-- have migrated to synapse_event.access_event
DROP TASK IF EXISTS clone_process_access_task;
