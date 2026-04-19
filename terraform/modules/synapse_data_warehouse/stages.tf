# ── SYNAPSE_DATA_WAREHOUSE external stages ────────────────────────────────────
# Mirrors:
#   synapse_data_warehouse/synapse_raw/V1.1.0__create_stages.sql
#   synapse_data_warehouse/synapse_raw/V2.16.0__create_file_association_stages.sql
#   synapse_data_warehouse/rds_landing/V2.69.0__create_stage.sql
#
# Stages require an existing storage integration (managed in account/ root module).
# provider: snowflake.sysadmin

# ── SYNAPSE_RAW: main Parquet event/snapshot stage ────────────────────────────
# Named {integration}_STAGE, e.g. SYNAPSE_PROD_WAREHOUSE_S3_STAGE (prod)
# Receives: all Synapse snapshot and event Parquet files from S3.
resource "snowflake_stage" "synapse_warehouse_s3" {
  provider = snowflake.sysadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "${var.stage_storage_integration}_STAGE"

  storage_integration = var.stage_storage_integration
  url                 = var.stage_url
  file_format         = "TYPE = PARQUET COMPRESSION = AUTO"
  directory           = "ENABLE = TRUE"

  depends_on = [snowflake_schema.synapse_raw]
}

# ── SYNAPSE_RAW: file-handle association stage ────────────────────────────────
# Receives: file handle association Parquet records from S3.
resource "snowflake_stage" "synapse_filehandles" {
  provider = snowflake.sysadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "SYNAPSE_FILEHANDLES_STAGE"

  storage_integration = var.stage_storage_integration
  url                 = "s3://${var.stack}.filehandles.sagebase.org/fileHandleAssociations/records/"
  file_format         = "TYPE = PARQUET COMPRESSION = AUTO"
  directory           = "ENABLE = TRUE"

  depends_on = [snowflake_schema.synapse_raw]
}

# ── RDS_LANDING: MySQL RDS snapshot Parquet stage ─────────────────────────────
# Receives: RDS export Parquet files for the 2026 Synapse RDS → Snowflake pipeline (SNOW-392).
resource "snowflake_stage" "rds_snapshots" {
  provider = snowflake.sysadmin

  database = var.database_name
  schema   = "RDS_LANDING"
  name     = "RDS_SNAPSHOTS_STAGE"

  storage_integration = var.snapshots_stage_storage_integration
  url                 = var.snapshots_stage_url
  file_format         = "TYPE = PARQUET COMPRESSION = AUTO"
  directory           = "ENABLE = TRUE"

  depends_on = [snowflake_schema.rds_landing]
}
