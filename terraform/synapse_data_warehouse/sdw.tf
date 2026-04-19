# ── SYNAPSE_DATA_WAREHOUSE environments ───────────────────────────────────────
# The reusable module is instantiated once for prod and once for dev.
# Each call receives environment-specific values; all resource definitions live
# in modules/synapse_data_warehouse/.

module "prod" {
  source = "../modules/synapse_data_warehouse"

  providers = {
    snowflake.sysadmin      = snowflake.sysadmin
    snowflake.securityadmin = snowflake.securityadmin
    snowflake.accountadmin  = snowflake.accountadmin
  }

  database_name                       = "SYNAPSE_DATA_WAREHOUSE"
  stage_storage_integration           = "SYNAPSE_PROD_WAREHOUSE_S3"
  stage_url                           = var.synapse_prod_stage_url
  snapshots_stage_storage_integration = "SYNAPSE_SNAPSHOTS_PROD"
  snapshots_stage_url                 = var.synapse_snapshots_prod_stage_url
  stack                               = "prod"
  admin_role                          = "SYNAPSE_DATA_WAREHOUSE_ADMIN"
  analyst_role                        = "SYNAPSE_DATA_WAREHOUSE_ANALYST"
  proxy_admin_role                    = "SYNAPSE_DATA_WAREHOUSE_PROXY_ADMIN"
}

module "dev" {
  source = "../modules/synapse_data_warehouse"

  providers = {
    snowflake.sysadmin      = snowflake.sysadmin
    snowflake.securityadmin = snowflake.securityadmin
    snowflake.accountadmin  = snowflake.accountadmin
  }

  database_name                       = "SYNAPSE_DATA_WAREHOUSE_DEV"
  stage_storage_integration           = "SYNAPSE_DEV_WAREHOUSE_S3"
  stage_url                           = var.synapse_dev_stage_url
  snapshots_stage_storage_integration = "SYNAPSE_SNAPSHOTS_DEV"
  snapshots_stage_url                 = var.synapse_snapshots_dev_stage_url
  stack                               = "dev"
  admin_role                          = "SYNAPSE_DATA_WAREHOUSE_DEV_ADMIN"
  analyst_role                        = "SYNAPSE_DATA_WAREHOUSE_DEV_ANALYST"
  proxy_admin_role                    = "SYNAPSE_DATA_WAREHOUSE_DEV_PROXY_ADMIN"
}
