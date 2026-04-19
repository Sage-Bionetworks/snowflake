# ── Warehouses ─────────────────────────────────────────────────────────────────
# Mirrors: admin/warehouses/V1.0.0 → V1.21.0 (current state after all migrations)
# Default provider (SYSADMIN) creates warehouses.
#
# Naming conventions (from admin/CLAUDE.md):
#   - XSMALL for most workloads; MEDIUM only for COPY INTO operations
#   - initially_suspended = true, auto_resume = true on all warehouses
#   - Tableau warehouse: auto_suspend = 300 (long, to keep query cache warm)
#   - All others: auto_suspend = 60–90 s
#   - statement_timeout_in_seconds = 10800 (3 h) to prevent runaway queries

locals {
  warehouses = {
    # General-purpose compute (renamed from COMPUTE_ORG in V1.1.0)
    COMPUTE_XSMALL = {
      size              = "XSMALL"
      auto_suspend      = 70
      max_cluster_count = 50  # Temporarily elevated (V1.21.0); reduce to 10 post-workshop
    }

    # Heavy ingestion (COPY INTO); kept small cluster count — serial by nature
    COMPUTE_MEDIUM = {
      size              = "MEDIUM"
      auto_suspend      = 70
      max_cluster_count = 1
    }

    # RECOVER project workloads
    RECOVER_XSMALL = {
      size              = "XSMALL"
      auto_suspend      = 90
      max_cluster_count = 1
    }

    # Tableau (renamed from TABLEAU in V1.1.0); longer suspend for cache warm-up
    TABLEAU_XSMALL = {
      size              = "XSMALL"
      auto_suspend      = 300
      max_cluster_count = 1
    }
  }
}

resource "snowflake_warehouse" "warehouses" {
  for_each = local.warehouses

  name           = each.key
  warehouse_type = "STANDARD"
  warehouse_size = each.value.size
  auto_suspend   = each.value.auto_suspend
  auto_resume    = true
  initially_suspended          = true
  max_cluster_count            = each.value.max_cluster_count
  statement_timeout_in_seconds = 10800
}
