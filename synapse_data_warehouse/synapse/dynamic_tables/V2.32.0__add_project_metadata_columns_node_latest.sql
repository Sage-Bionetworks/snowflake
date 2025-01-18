-- Configure environment
USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP,CP02

-- Add the new columns
ALTER TABLE node_latest ADD COLUMN maxAllowedFileBytes <data-type> COMMENT '<column description>';
ALTER TABLE node_latest ADD COLUMN storageLocationID <data-type> COMMENT '<column description>';
ALTER TABLE node_latest ADD COLUMN isOverLimit <data-type> COMMENT '<column description>';
