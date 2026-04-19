# ── Per-environment configuration ────────────────────────────────────────────
# These map directly to the sdw_databases local in the old flat structure.

variable "database_name" {
  description = "Snowflake database managed by this module instance (e.g. SYNAPSE_DATA_WAREHOUSE or SYNAPSE_DATA_WAREHOUSE_DEV)"
  type        = string
}

variable "stage_storage_integration" {
  description = "Name of the storage integration for the main Synapse S3 stage (e.g. SYNAPSE_PROD_WAREHOUSE_S3)"
  type        = string
}

variable "stage_url" {
  description = "S3 URL for the main Synapse event/snapshot external stage"
  type        = string
}

variable "snapshots_stage_storage_integration" {
  description = "Name of the storage integration for the RDS-snapshot stage (e.g. SYNAPSE_SNAPSHOTS_PROD)"
  type        = string
}

variable "snapshots_stage_url" {
  description = "S3 URL for the RDS-snapshot external stage"
  type        = string
}

variable "stack" {
  description = "Stack identifier used in S3 URLs — 'prod' or 'dev'"
  type        = string
}

variable "admin_role" {
  description = "Account role that receives SYNAPSE_*_ALL_ADMIN database roles (e.g. SYNAPSE_DATA_WAREHOUSE_ADMIN)"
  type        = string
}

variable "analyst_role" {
  description = "Account role that receives SYNAPSE_*_ALL_ANALYST database roles (e.g. SYNAPSE_DATA_WAREHOUSE_ANALYST)"
  type        = string
}

variable "proxy_admin_role" {
  description = "Account role that owns the ALL_ADMIN database role (e.g. SYNAPSE_DATA_WAREHOUSE_PROXY_ADMIN)"
  type        = string
}
