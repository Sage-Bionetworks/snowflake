USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
ALTER TABLE NODESNAPSHOTS ADD COLUMN annotations VARIANT;
ALTER TABLE NODESNAPSHOTS ADD COLUMN derived_annotations VARIANT;
