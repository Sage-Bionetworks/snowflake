-- Configure environment
USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP,CP02

-- Add the new columns
ALTER TABLE nodesnapshots ADD COLUMN project_storage_usage <data-type> COMMENT 'For nodes of type project includes the project storage usage data for each storage location in the project.';
