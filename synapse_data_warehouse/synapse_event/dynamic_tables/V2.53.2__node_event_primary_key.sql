USE SCHEMA {{database_name}}.synapse_event; --noqa: JJ01,PRS,TMP

ALTER TABLE node_event 
  ADD CONSTRAINT composite_primary_keys 
  PRIMARY KEY (id, version_number, change_type, modified_on);
