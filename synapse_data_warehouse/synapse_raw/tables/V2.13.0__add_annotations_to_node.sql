USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
ALTER TABLE NODESNAPSHOTS ADD COLUMN annotations STRING;
ALTER TABLE NODESNAPSHOTS ADD COLUMN derived_annotations STRING;