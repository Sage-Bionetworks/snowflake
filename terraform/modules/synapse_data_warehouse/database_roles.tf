# ── SYNAPSE_DATA_WAREHOUSE database roles ─────────────────────────────────────
# Mirrors the full database_roles/ V__ migration sequence (current state):
#   V2.31.0 — SYNAPSE, SYNAPSE_RAW, SCHEMACHANGE admin roles
#   V2.37.0 — analyst aggregate + object-type-specific read roles
#   V2.39.0 — ALL_ADMIN proxy role
#   V2.45.0 — *_ALL_DEVELOPER roles
#   V2.47.1 — SYNAPSE_AGGREGATE roles
#   V2.49.1 — SYNAPSE_EVENT roles
#   V2.64.1 — SYNAPSE_FUNCTION_READ role
#   V2.66.1 — RDS_LANDING roles
#   V2.67.1 — RDS_RAW roles
#   V2.68.0 — RDS_RAW_VIEW_READ role
#
# Ownership grants (GRANT OWNERSHIP ON DATABASE ROLE) are handled here;
# object-level privilege grants (SELECT, USAGE on tables/stages) belong in
# admin/future_grants/ schemachange migrations — not Terraform.
# provider: snowflake.sysadmin (CREATE DATABASE ROLE requires object owner or SYSADMIN)

locals {
  # SYNAPSE schema roles (V2.31.0 + V2.37.0 + V2.45.0 + V2.64.1)
  synapse_db_roles = [
    "SYNAPSE_ALL_ADMIN",
    "SYNAPSE_ALL_ANALYST",
    "SYNAPSE_ALL_DEVELOPER",
    "SYNAPSE_TABLE_READ",
    "SYNAPSE_STAGE_READ",
    "SYNAPSE_VIEW_READ",
    "SYNAPSE_TASK_READ",
    "SYNAPSE_FUNCTION_READ",
  ]

  # SYNAPSE_RAW schema roles (V2.31.0 + V2.37.0 + V2.45.0)
  synapse_raw_db_roles = [
    "SYNAPSE_RAW_ALL_ADMIN",
    "SYNAPSE_RAW_ALL_ANALYST",
    "SYNAPSE_RAW_ALL_DEVELOPER",
    "SYNAPSE_RAW_TABLE_READ",
    "SYNAPSE_RAW_STAGE_READ",
    "SYNAPSE_RAW_STREAM_READ",
    "SYNAPSE_RAW_TASK_READ",
  ]

  # SCHEMACHANGE schema roles (V2.31.0 + V2.37.0 + V2.45.0)
  schemachange_db_roles = [
    "SCHEMACHANGE_ALL_ADMIN",
    "SCHEMACHANGE_ALL_ANALYST",
    "SCHEMACHANGE_ALL_DEVELOPER",
    "SCHEMACHANGE_TABLE_READ",
  ]

  # SYNAPSE_AGGREGATE schema roles (V2.47.1)
  synapse_aggregate_db_roles = [
    "SYNAPSE_AGGREGATE_ALL_ADMIN",
    "SYNAPSE_AGGREGATE_ALL_ANALYST",
    "SYNAPSE_AGGREGATE_ALL_DEVELOPER",
    "SYNAPSE_AGGREGATE_TABLE_READ",
  ]

  # SYNAPSE_EVENT schema roles (V2.49.1)
  synapse_event_db_roles = [
    "SYNAPSE_EVENT_ALL_ADMIN",
    "SYNAPSE_EVENT_ALL_ANALYST",
    "SYNAPSE_EVENT_ALL_DEVELOPER",
    "SYNAPSE_EVENT_TABLE_READ",
  ]

  # RDS_LANDING schema roles (V2.66.1)
  rds_landing_db_roles = [
    "RDS_LANDING_ALL_ADMIN",
    "RDS_LANDING_ALL_DEVELOPER",
    "RDS_LANDING_TABLE_READ",
    "RDS_LANDING_STAGE_READ",
  ]

  # RDS_RAW schema roles (V2.67.1 + V2.68.0)
  rds_raw_db_roles = [
    "RDS_RAW_ALL_ADMIN",
    "RDS_RAW_ALL_DEVELOPER",
    "RDS_RAW_TABLE_READ",
    "RDS_RAW_STAGE_READ",
    "RDS_RAW_VIEW_READ",
  ]

  # Proxy admin (V2.39.0)
  proxy_db_roles = ["ALL_ADMIN"]

  all_db_roles = toset(concat(
    local.synapse_db_roles,
    local.synapse_raw_db_roles,
    local.schemachange_db_roles,
    local.synapse_aggregate_db_roles,
    local.synapse_event_db_roles,
    local.rds_landing_db_roles,
    local.rds_raw_db_roles,
    local.proxy_db_roles,
  ))
}

resource "snowflake_database_role" "sdw" {
  for_each = local.all_db_roles
  provider = snowflake.sysadmin
  database = var.database_name
  name     = each.value
}

# ── Ownership grants (database role → database role / account role) ───────────
# Mirrors the GRANT OWNERSHIP ON DATABASE ROLE ... statements in V2.31.0–V2.68.0.
# provider: snowflake.securityadmin

# SYNAPSE namespace (V2.31.0 + V2.37.0 + V2.45.0 + V2.64.1)
resource "snowflake_grant_database_role" "synapse_all_analyst_owned_by_all_admin" {
  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.SYNAPSE_ALL_ANALYST"
  parent_database_role_name = "${var.database_name}.SYNAPSE_ALL_ADMIN"
}

resource "snowflake_grant_database_role" "synapse_type_reads_owned_by_all_admin" {
  for_each = toset(["SYNAPSE_TABLE_READ", "SYNAPSE_STAGE_READ", "SYNAPSE_VIEW_READ", "SYNAPSE_TASK_READ", "SYNAPSE_FUNCTION_READ"])

  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.${each.value}"
  parent_database_role_name = "${var.database_name}.SYNAPSE_ALL_ADMIN"
}

resource "snowflake_grant_database_role" "synapse_type_reads_to_all_analyst" {
  for_each = toset(["SYNAPSE_TABLE_READ", "SYNAPSE_STAGE_READ", "SYNAPSE_VIEW_READ", "SYNAPSE_TASK_READ", "SYNAPSE_FUNCTION_READ"])

  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.${each.value}"
  parent_database_role_name = "${var.database_name}.SYNAPSE_ALL_ANALYST"
}

resource "snowflake_grant_database_role" "synapse_all_developer_inherits_analyst" {
  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.SYNAPSE_ALL_ANALYST"
  parent_database_role_name = "${var.database_name}.SYNAPSE_ALL_DEVELOPER"
}

resource "snowflake_grant_database_role" "synapse_all_developer_inherits_function_read" {
  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.SYNAPSE_FUNCTION_READ"
  parent_database_role_name = "${var.database_name}.SYNAPSE_ALL_DEVELOPER"
}

# SYNAPSE_RAW namespace (V2.31.0 + V2.37.0 + V2.45.0)
resource "snowflake_grant_database_role" "synapse_raw_analyst_owned_by_all_admin" {
  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.SYNAPSE_RAW_ALL_ANALYST"
  parent_database_role_name = "${var.database_name}.SYNAPSE_RAW_ALL_ADMIN"
}

resource "snowflake_grant_database_role" "synapse_raw_type_reads_owned_by_all_admin" {
  for_each = toset(["SYNAPSE_RAW_TABLE_READ", "SYNAPSE_RAW_STAGE_READ", "SYNAPSE_RAW_STREAM_READ", "SYNAPSE_RAW_TASK_READ"])

  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.${each.value}"
  parent_database_role_name = "${var.database_name}.SYNAPSE_RAW_ALL_ADMIN"
}

resource "snowflake_grant_database_role" "synapse_raw_type_reads_to_all_analyst" {
  for_each = toset(["SYNAPSE_RAW_TABLE_READ", "SYNAPSE_RAW_STAGE_READ", "SYNAPSE_RAW_STREAM_READ", "SYNAPSE_RAW_TASK_READ"])

  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.${each.value}"
  parent_database_role_name = "${var.database_name}.SYNAPSE_RAW_ALL_ANALYST"
}

# SYNAPSE_RAW developer inherits type-specific reads directly (not via analyst)
resource "snowflake_grant_database_role" "synapse_raw_developer_type_reads" {
  for_each = toset(["SYNAPSE_RAW_TABLE_READ", "SYNAPSE_RAW_STAGE_READ", "SYNAPSE_RAW_STREAM_READ", "SYNAPSE_RAW_TASK_READ"])

  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.${each.value}"
  parent_database_role_name = "${var.database_name}.SYNAPSE_RAW_ALL_DEVELOPER"
}

# SCHEMACHANGE namespace
resource "snowflake_grant_database_role" "schemachange_analyst_owned_by_all_admin" {
  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.SCHEMACHANGE_ALL_ANALYST"
  parent_database_role_name = "${var.database_name}.SCHEMACHANGE_ALL_ADMIN"
}

resource "snowflake_grant_database_role" "schemachange_table_read_owned_by_all_admin" {
  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.SCHEMACHANGE_TABLE_READ"
  parent_database_role_name = "${var.database_name}.SCHEMACHANGE_ALL_ADMIN"
}

resource "snowflake_grant_database_role" "schemachange_table_read_to_analyst" {
  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.SCHEMACHANGE_TABLE_READ"
  parent_database_role_name = "${var.database_name}.SCHEMACHANGE_ALL_ANALYST"
}

resource "snowflake_grant_database_role" "schemachange_developer_inherits_analyst" {
  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.SCHEMACHANGE_ALL_ANALYST"
  parent_database_role_name = "${var.database_name}.SCHEMACHANGE_ALL_DEVELOPER"
}

# SYNAPSE_AGGREGATE namespace (V2.47.1)
resource "snowflake_grant_database_role" "synapse_agg_analyst_owned_by_admin" {
  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.SYNAPSE_AGGREGATE_ALL_ANALYST"
  parent_database_role_name = "${var.database_name}.SYNAPSE_AGGREGATE_ALL_ADMIN"
}

resource "snowflake_grant_database_role" "synapse_agg_table_read_to_analyst" {
  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.SYNAPSE_AGGREGATE_TABLE_READ"
  parent_database_role_name = "${var.database_name}.SYNAPSE_AGGREGATE_ALL_ANALYST"
}

resource "snowflake_grant_database_role" "synapse_agg_developer_inherits_analyst" {
  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.SYNAPSE_AGGREGATE_ALL_ANALYST"
  parent_database_role_name = "${var.database_name}.SYNAPSE_AGGREGATE_ALL_DEVELOPER"
}

# SYNAPSE_EVENT namespace (V2.49.1)
resource "snowflake_grant_database_role" "synapse_event_analyst_owned_by_admin" {
  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.SYNAPSE_EVENT_ALL_ANALYST"
  parent_database_role_name = "${var.database_name}.SYNAPSE_EVENT_ALL_ADMIN"
}

resource "snowflake_grant_database_role" "synapse_event_table_read_to_analyst" {
  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.SYNAPSE_EVENT_TABLE_READ"
  parent_database_role_name = "${var.database_name}.SYNAPSE_EVENT_ALL_ANALYST"
}

resource "snowflake_grant_database_role" "synapse_event_developer_inherits_analyst" {
  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.SYNAPSE_EVENT_ALL_ANALYST"
  parent_database_role_name = "${var.database_name}.SYNAPSE_EVENT_ALL_DEVELOPER"
}

# RDS_LANDING namespace (V2.66.1)
resource "snowflake_grant_database_role" "rds_landing_developer_inherits_type_reads" {
  for_each = toset(["RDS_LANDING_TABLE_READ", "RDS_LANDING_STAGE_READ"])

  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.${each.value}"
  parent_database_role_name = "${var.database_name}.RDS_LANDING_ALL_DEVELOPER"
}

# RDS_RAW namespace (V2.67.1 + V2.68.0)
resource "snowflake_grant_database_role" "rds_raw_developer_inherits_type_reads" {
  for_each = toset(["RDS_RAW_TABLE_READ", "RDS_RAW_STAGE_READ", "RDS_RAW_VIEW_READ"])

  provider                  = snowflake.securityadmin
  database_role_name        = "${var.database_name}.${each.value}"
  parent_database_role_name = "${var.database_name}.RDS_RAW_ALL_DEVELOPER"
}

# ── Database role → account role grants ──────────────────────────────────────
# Grant top-level database roles to their corresponding account roles.
# provider: snowflake.securityadmin

# Admin roles to {DATABASE}_ADMIN account role
resource "snowflake_grant_database_role" "schema_admins_to_db_admin" {
  for_each = toset(["SYNAPSE_ALL_ADMIN", "SYNAPSE_RAW_ALL_ADMIN", "SCHEMACHANGE_ALL_ADMIN", "ALL_ADMIN"])

  provider                 = snowflake.securityadmin
  database_role_name       = "${var.database_name}.${each.value}"
  parent_account_role_name = var.admin_role
}

# Analyst aggregate roles to {DATABASE}_ANALYST account role
resource "snowflake_grant_database_role" "schema_analysts_to_db_analyst" {
  for_each = toset(["SYNAPSE_ALL_ANALYST", "SYNAPSE_RAW_ALL_ANALYST", "SCHEMACHANGE_ALL_ANALYST"])

  provider                 = snowflake.securityadmin
  database_role_name       = "${var.database_name}.${each.value}"
  parent_account_role_name = var.analyst_role
}

# Developer roles to DATA_ENGINEER account role
resource "snowflake_grant_database_role" "schema_developers_to_data_engineer" {
  for_each = toset(["SYNAPSE_ALL_DEVELOPER", "SYNAPSE_RAW_ALL_DEVELOPER", "SCHEMACHANGE_ALL_DEVELOPER"])

  provider                 = snowflake.securityadmin
  database_role_name       = "${var.database_name}.${each.value}"
  parent_account_role_name = "DATA_ENGINEER"
}

# SYNAPSE_AGGREGATE and SYNAPSE_EVENT admin roles → proxy admin account role
resource "snowflake_grant_database_role" "new_schema_admins_to_proxy_admin" {
  for_each = toset(["SYNAPSE_AGGREGATE_ALL_ADMIN", "SYNAPSE_EVENT_ALL_ADMIN", "RDS_LANDING_ALL_ADMIN", "RDS_RAW_ALL_ADMIN"])

  provider                 = snowflake.securityadmin
  database_role_name       = "${var.database_name}.${each.value}"
  parent_account_role_name = var.proxy_admin_role
}

# RDS developer roles → DATA_ENGINEER
resource "snowflake_grant_database_role" "rds_developers_to_data_engineer" {
  for_each = toset(["RDS_LANDING_ALL_DEVELOPER", "RDS_RAW_ALL_DEVELOPER"])

  provider                 = snowflake.securityadmin
  database_role_name       = "${var.database_name}.${each.value}"
  parent_account_role_name = "DATA_ENGINEER"
}
