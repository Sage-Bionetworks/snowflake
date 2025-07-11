USE SCHEMA {{database_name}}.synapse_aggregate; --noqa: JJ01,PRS,TMP

ALTER TABLE objectdownload_aggregate
  ADD CONSTRAINT composite_primary_keys 
  PRIMARY KEY (agg_year, agg_month, agg_day, agg_project_id, agg_object_type, agg_object_id);