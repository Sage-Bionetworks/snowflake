# ── SYNAPSE_DATA_WAREHOUSE schemas ────────────────────────────────────────────
# Mirrors: synapse_data_warehouse/synapse_raw/V1.0.0__create_schemas.sql,
#          synapse_data_warehouse/synapse_aggregate/V2.47.0__create_synapse_aggregate_schema.sql,
#          synapse_data_warehouse/synapse_event/V2.49.0__create_synapse_event_schema.sql,
#          synapse_data_warehouse/rds_landing/V2.66.0__create_rds_landing_schema.sql,
#          synapse_data_warehouse/rds_raw/V2.67.0__create_rds_raw_schema.sql
#
# SCHEMACHANGE schema is auto-created by schemachange itself — not managed here.
# provider: snowflake.sysadmin

# SYNAPSE_RAW — raw S3 Parquet ingest (snapshot tables, stages, streams, tasks)
resource "snowflake_schema" "synapse_raw" {
  provider            = snowflake.sysadmin
  database            = var.database_name
  name                = "SYNAPSE_RAW"
  with_managed_access = true
}

# SYNAPSE — transformed/materialized tables and dynamic tables consumed by dbt
resource "snowflake_schema" "synapse" {
  provider            = snowflake.sysadmin
  database            = var.database_name
  name                = "SYNAPSE"
  with_managed_access = true
}

# SYNAPSE_AGGREGATE — time-window aggregations of user activity (dynamic tables)
resource "snowflake_schema" "synapse_aggregate" {
  provider = snowflake.sysadmin
  database = var.database_name
  name     = "SYNAPSE_AGGREGATE"
}

# SYNAPSE_EVENT — derived event tables retaining the most recent snapshot per event
resource "snowflake_schema" "synapse_event" {
  provider = snowflake.sysadmin
  database = var.database_name
  name     = "SYNAPSE_EVENT"
  comment  = "Event data is derived from raw data by retaining only the most recent snapshot for each distinct event. The identifier of an event is determined by a subset of columns which uniquely identifies the occurrence or instance of an event."
}

# RDS_LANDING — external tables + stages for MySQL RDS snapshot ingestion
resource "snowflake_schema" "rds_landing" {
  provider = snowflake.sysadmin
  database = var.database_name
  name     = "RDS_LANDING"
}

# RDS_RAW — MySQL RDS snapshot tables (access approvals, requirements, ACLs)
resource "snowflake_schema" "rds_raw" {
  provider = snowflake.sysadmin
  database = var.database_name
  name     = "RDS_RAW"
}
