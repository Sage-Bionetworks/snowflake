# ── Account roles ──────────────────────────────────────────────────────────────
# Mirrors: admin/roles.sql
# Default provider (USERADMIN) creates roles.
# Role-to-role and role-to-user grants live in role_grants.tf (SECURITYADMIN).

locals {
  account_roles = {
    # System-wide
    MASKING_ADMIN    = "Manages column-level masking policies across all databases"
    DATA_ENGINEER    = "Synapse data engineering — full access to SDW schemas"
    DATA_ANALYTICS   = "Broad read access for analysts across all public schemas"
    TASKADMIN        = "Execute and manage Snowflake tasks (EXECUTE TASK privilege)"
    DPE_OPS          = "DPE operational role for pipeline administration"
    SAGE_LEADERS     = "Sage Bionetworks leadership — inherits DATA_ANALYTICS"

    # Domain / project roles
    GENIE_ADMIN      = "GENIE cancer genomics snowflake administrators"
    AD               = "Alzheimer's Disease data access (SAGE.AD schema)"
    FAIR             = "FAIR data team"
    GOVERNANCE       = "Data governance team"
    NF_ADMIN         = "NF Rare Disease data admin (SAGE.NF schema)"
    SCIDATA_ADMIN    = "SciData admin (SAGE.SCIDATA schema)"
    TECH_PRODUCT     = "Raw RDS snapshot access for product analytics"

    # SYNAPSE_DATA_WAREHOUSE (prod)
    SYNAPSE_DATA_WAREHOUSE_ADMIN       = "Full admin on SYNAPSE_DATA_WAREHOUSE (prod)"
    SYNAPSE_DATA_WAREHOUSE_ANALYST     = "Read access on SYNAPSE_DATA_WAREHOUSE (prod)"
    SYNAPSE_DATA_WAREHOUSE_PROXY_ADMIN = "Owns database roles in SYNAPSE_DATA_WAREHOUSE"

    # SYNAPSE_DATA_WAREHOUSE_DEV
    SYNAPSE_DATA_WAREHOUSE_DEV_ADMIN       = "Full admin on SYNAPSE_DATA_WAREHOUSE_DEV"
    SYNAPSE_DATA_WAREHOUSE_DEV_ANALYST     = "Read access on SYNAPSE_DATA_WAREHOUSE_DEV"
    SYNAPSE_DATA_WAREHOUSE_DEV_PROXY_ADMIN = "Owns database roles in SYNAPSE_DATA_WAREHOUSE_DEV"

    # SAGE database
    SAGE_ADMIN              = "Admin for the SAGE cross-cutting database"
    SAGE_CITATIONS_ADMIN    = "Admin for SAGE.CITATIONS schema"
    SAGE_CITATIONS_ANALYST  = "Read access for SAGE.CITATIONS schema"
    SAGE_GOVERNANCE_ADMIN   = "Admin for SAGE.GOVERNANCE schema"
    SAGE_GOVERNANCE_ANALYST = "Read access for SAGE.GOVERNANCE schema"

    # Google Analytics
    GOOGLE_ANALYTICS_AGGREGATE_ADMIN = "Admin for SAGE.GOOGLE_ANALYTICS_AGGREGATE schema"
  }
}

resource "snowflake_account_role" "roles" {
  for_each = local.account_roles
  name     = each.key
  comment  = each.value
  # Default provider (USERADMIN) is used
}
