USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Drop the task that clones to the deprecated synapse.fileupload table
-- This task was created in V1.14.0 and is no longer needed as consumers
-- have migrated to synapse_event.fileupload_event
DROP TASK IF EXISTS clone_fileupload_task;
