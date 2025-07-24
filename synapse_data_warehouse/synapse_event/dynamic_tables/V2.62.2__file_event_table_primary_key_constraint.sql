USE SCHEMA {{database_name}}.synapse_event; --noqa: JJ01,PRS,TMP

ALTER TABLE file_event
  ADD CONSTRAINT composite_primary_keys 
  PRIMARY KEY (id, change_type, change_timestamp, modified_on);
