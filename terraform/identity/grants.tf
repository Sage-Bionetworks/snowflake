# ── Privilege grants ───────────────────────────────────────────────────────────
# Covers warehouse usage, database/schema privileges, integration grants, and
# account-level privilege grants (EXECUTE TASK, APPLY MASKING POLICY, etc.).
# Mirrors: admin/grants.sql
#
# Does NOT include:
#   - Ownership transfers → admin/ownership_grants/ (side-effect: auto-suspends tasks)
#   - Future grants       → admin/future_grants/    (versioned schemachange migrations)

# ── Account-level privileges ──────────────────────────────────────────────────
# provider: snowflake.accountadmin

resource "snowflake_grant_privileges_to_account_role" "taskadmin_execute_task" {
  provider   = snowflake.accountadmin
  role_name  = "TASKADMIN"
  privileges = ["EXECUTE TASK", "EXECUTE MANAGED TASK"]
  on_account = true
}

resource "snowflake_grant_privileges_to_account_role" "masking_admin_apply_policy" {
  provider   = snowflake.accountadmin
  role_name  = "MASKING_ADMIN"
  privileges = ["APPLY MASKING POLICY"]
  on_account = true
}

resource "snowflake_grant_privileges_to_account_role" "data_engineer_create_database" {
  provider   = snowflake.accountadmin
  role_name  = "DATA_ENGINEER"
  privileges = ["CREATE DATABASE"]
  on_account = true
}

resource "snowflake_grant_privileges_to_account_role" "sdw_admin_create_database" {
  provider   = snowflake.accountadmin
  role_name  = "SYNAPSE_DATA_WAREHOUSE_ADMIN"
  privileges = ["CREATE DATABASE"]
  on_account = true
}

resource "snowflake_grant_privileges_to_account_role" "sdw_dev_admin_create_database" {
  provider   = snowflake.accountadmin
  role_name  = "SYNAPSE_DATA_WAREHOUSE_DEV_ADMIN"
  privileges = ["CREATE DATABASE"]
  on_account = true
}

# ── Warehouse usage ───────────────────────────────────────────────────────────
# provider: snowflake.securityadmin

resource "snowflake_grant_privileges_to_account_role" "warehouse_compute_xsmall" {
  for_each   = toset(["DATA_ANALYTICS", "GOVERNANCE", "TECH_PRODUCT"])
  provider   = snowflake.securityadmin
  role_name  = each.value
  privileges = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = "COMPUTE_XSMALL"
  }
}

resource "snowflake_grant_privileges_to_account_role" "warehouse_tableau_xsmall" {
  provider   = snowflake.securityadmin
  role_name  = "GENIE_ADMIN"
  privileges = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = "TABLEAU_XSMALL"
  }
}

# ── Storage integration grants ────────────────────────────────────────────────
resource "snowflake_grant_privileges_to_account_role" "integration_synapse_prod_s3" {
  for_each   = toset(["SYSADMIN", "DATA_ENGINEER"])
  provider   = snowflake.securityadmin
  role_name  = each.value
  privileges = ["USAGE"]
  on_account_object {
    object_type = "INTEGRATION"
    object_name = "SYNAPSE_PROD_WAREHOUSE_S3"
  }
}

resource "snowflake_grant_privileges_to_account_role" "integration_synapse_dev_s3" {
  provider   = snowflake.securityadmin
  role_name  = "SYSADMIN"
  privileges = ["USAGE"]
  on_account_object {
    object_type = "INTEGRATION"
    object_name = "SYNAPSE_DEV_WAREHOUSE_S3"
  }
}

resource "snowflake_grant_privileges_to_account_role" "integration_snapshots_dev" {
  for_each   = toset(["DATA_ENGINEER", "SYNAPSE_DATA_WAREHOUSE_DEV_PROXY_ADMIN"])
  provider   = snowflake.securityadmin
  role_name  = each.value
  privileges = ["USAGE"]
  on_account_object {
    object_type = "INTEGRATION"
    object_name = "SYNAPSE_SNAPSHOTS_DEV"
  }
}

resource "snowflake_grant_privileges_to_account_role" "integration_snapshots_prod" {
  for_each   = toset(["DATA_ENGINEER", "SYNAPSE_DATA_WAREHOUSE_PROXY_ADMIN"])
  provider   = snowflake.securityadmin
  role_name  = each.value
  privileges = ["USAGE"]
  on_account_object {
    object_type = "INTEGRATION"
    object_name = "SYNAPSE_SNAPSHOTS_PROD"
  }
}

# ── Database-level grants ─────────────────────────────────────────────────────

resource "snowflake_grant_privileges_to_account_role" "sage_db_public" {
  provider   = snowflake.securityadmin
  role_name  = "PUBLIC"
  privileges = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = "SAGE"
  }
}

resource "snowflake_grant_privileges_to_account_role" "sage_db_data_engineer" {
  provider   = snowflake.securityadmin
  role_name  = "DATA_ENGINEER"
  privileges = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = "SAGE"
  }
}

resource "snowflake_grant_privileges_to_account_role" "sage_db_data_analytics" {
  provider   = snowflake.securityadmin
  role_name  = "DATA_ANALYTICS"
  privileges = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = "SAGE"
  }
}

resource "snowflake_grant_privileges_to_account_role" "ip_info_data_engineer" {
  provider   = snowflake.securityadmin
  role_name  = "DATA_ENGINEER"
  privileges = ["IMPORTED PRIVILEGES"]
  on_account_object {
    object_type = "DATABASE"
    object_name = "IP_INFO"
  }
}

resource "snowflake_grant_privileges_to_account_role" "ip_info_governance" {
  provider   = snowflake.securityadmin
  role_name  = "GOVERNANCE"
  privileges = ["IMPORTED PRIVILEGES"]
  on_account_object {
    object_type = "DATABASE"
    object_name = "IP_INFO"
  }
}

resource "snowflake_grant_privileges_to_account_role" "ip_info_data_analytics" {
  provider   = snowflake.securityadmin
  role_name  = "DATA_ANALYTICS"
  privileges = ["IMPORTED PRIVILEGES"]
  on_account_object {
    object_type = "DATABASE"
    object_name = "IP_INFO"
  }
}

# ── Schema-level grants ───────────────────────────────────────────────────────

resource "snowflake_grant_privileges_to_account_role" "sage_ad_schema_ad_role" {
  provider   = snowflake.securityadmin
  role_name  = "AD"
  privileges = ["ALL PRIVILEGES"]
  on_schema {
    schema_name = "SAGE.AD"
  }
}

resource "snowflake_grant_privileges_to_account_role" "sage_ad_usage_ad_role" {
  provider   = snowflake.securityadmin
  role_name  = "AD"
  privileges = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = "SAGE"
  }
}

resource "snowflake_grant_privileges_to_account_role" "sage_nf_schema" {
  provider   = snowflake.securityadmin
  role_name  = "NF_ADMIN"
  privileges = ["ALL PRIVILEGES"]
  on_schema {
    schema_name = "SAGE.NF"
  }
}

resource "snowflake_grant_privileges_to_account_role" "sage_scidata_schema" {
  provider   = snowflake.securityadmin
  role_name  = "SCIDATA_ADMIN"
  privileges = ["ALL PRIVILEGES"]
  on_schema {
    schema_name = "SAGE.SCIDATA"
  }
}

resource "snowflake_grant_privileges_to_account_role" "masking_policy_create_on_synapse" {
  provider   = snowflake.securityadmin
  role_name  = "MASKING_ADMIN"
  privileges = ["CREATE MASKING POLICY"]
  on_schema {
    schema_name = "SYNAPSE_DATA_WAREHOUSE.SYNAPSE"
  }
}

resource "snowflake_grant_privileges_to_account_role" "governance_procedures" {
  provider   = snowflake.securityadmin
  role_name  = "GOVERNANCE"
  privileges = ["USAGE"]
  on_schema_object {
    all {
      object_type_plural = "PROCEDURES"
      in_database        = "SYNAPSE_DATA_WAREHOUSE"
    }
  }
}

# ── Database role → account role grants ──────────────────────────────────────
# Grants SDW database roles to the matching account roles so the RBAC hierarchy
# described in admin/CLAUDE.md flows through correctly.
# provider: snowflake.securityadmin

resource "snowflake_grant_database_role" "synapse_all_analyst_to_data_analytics" {
  provider                 = snowflake.securityadmin
  database_role_name       = "SYNAPSE_DATA_WAREHOUSE.SYNAPSE_ALL_ANALYST"
  parent_account_role_name = "DATA_ANALYTICS"
}

resource "snowflake_grant_database_role" "schemachange_all_analyst_to_data_analytics" {
  provider                 = snowflake.securityadmin
  database_role_name       = "SYNAPSE_DATA_WAREHOUSE.SCHEMACHANGE_ALL_ANALYST"
  parent_account_role_name = "DATA_ANALYTICS"
}
