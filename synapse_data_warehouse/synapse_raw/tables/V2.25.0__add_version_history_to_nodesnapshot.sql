-- Configure environment
USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP,CP02
USE WAREHOUSE compute_xsmall;

-- Add `version_history` column
ALTER TABLE nodesnapshots
  ADD COLUMN version_history VARIANT
  COMMENT 'The list of entity versions, at the time of the snapshot.';
