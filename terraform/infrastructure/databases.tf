# ── Databases ──────────────────────────────────────────────────────────────────
# Mirrors: admin/databases.sql (current state — DROP statements excluded;
# Terraform should never manage dropped databases)
# Default provider (SYSADMIN) creates databases.
#
# Note: SYNAPSE_DATA_WAREHOUSE_DEV_{branch} clone databases are ephemeral and
# created by CI, not Terraform. Do not add them here.

locals {
  databases = toset([
    "GENIE",
    "SAGE",
    "DATA_ANALYTICS",
    "SYNAPSE_DATA_WAREHOUSE",
    "SYNAPSE_DATA_WAREHOUSE_DEV",
    "METADATA",
  ])
}

resource "snowflake_database" "databases" {
  for_each = local.databases
  name     = each.value
}
