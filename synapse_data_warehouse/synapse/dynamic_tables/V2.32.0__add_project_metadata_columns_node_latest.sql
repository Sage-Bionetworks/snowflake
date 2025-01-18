-- Configure environment
USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP,CP02

-- Add the new columns
ALTER TABLE nodesnapshots ADD COLUMN maxAllowedFileBytes <data-type> COMMENT '<column description>';
ALTER TABLE nodesnapshots ADD COLUMN storageLocationID <data-type> COMMENT '<column description>';
ALTER TABLE nodesnapshots ADD COLUMN isOverLimit <data-type> COMMENT '<column description>';
