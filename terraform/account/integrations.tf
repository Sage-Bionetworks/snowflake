# ── Integrations ───────────────────────────────────────────────────────────────
# Covers SAML2, OAuth (Tableau), and S3 storage integrations.
# All require ACCOUNTADMIN (the default provider in this root module).
# Mirrors: admin/integrations.sql

# ── Google SSO (SAML2) ────────────────────────────────────────────────────────
resource "snowflake_saml2_integration" "google_sso" {
  name                                = "GOOGLE_SSO"
  saml2_provider                      = "CUSTOM"
  saml2_issuer                        = var.saml2_issuer
  saml2_sso_url                       = var.saml2_sso_url
  saml2_x509_cert                     = var.saml2_x509_cert
  saml2_snowflake_acs_url             = "https://mqzfhld-vp00034.snowflakecomputing.com/fed/login"
  saml2_snowflake_issuer_url          = "https://mqzfhld-vp00034.snowflakecomputing.com"
  enabled                             = true
  saml2_sp_initiated_login_page_label = "GOOGLE_SSO"
  saml2_enable_sp_initiated           = true
  saml2_sign_request                  = true
}

# ── Tableau OAuth ─────────────────────────────────────────────────────────────
resource "snowflake_oauth_integration_for_partner_applications" "tableau_server" {
  name                         = "TS_OAUTH_INT2"
  oauth_client                 = "TABLEAU_SERVER"
  enabled                      = true
  oauth_refresh_token_validity = 86400
}

resource "snowflake_oauth_integration_for_partner_applications" "tableau_desktop" {
  name                         = "TD_OAUTH_INT2"
  oauth_client                 = "TABLEAU_DESKTOP"
  enabled                      = true
  oauth_refresh_token_validity = 36000
}

# ── S3 storage integrations ───────────────────────────────────────────────────
# Synapse RDS snapshot pipeline (SNOW-392) — dev + prod
resource "snowflake_storage_integration" "synapse_snapshots_dev" {
  name                      = "SYNAPSE_SNAPSHOTS_DEV"
  type                      = "EXTERNAL_STAGE"
  enabled                   = true
  storage_provider          = "S3"
  storage_aws_role_arn      = "arn:aws:iam::766808016710:role/snowflake-role-synapse-snowflake-rds-snapshots-dev"
  storage_allowed_locations = ["s3://synapse-snowflake-rds-snapshots-dev"]
}

resource "snowflake_storage_integration" "synapse_snapshots_prod" {
  name                      = "SYNAPSE_SNAPSHOTS_PROD"
  type                      = "EXTERNAL_STAGE"
  enabled                   = true
  storage_provider          = "S3"
  storage_aws_role_arn      = "arn:aws:iam::766808016710:role/snowflake-role-synapse-snowflake-rds-snapshots-prod"
  storage_allowed_locations = ["s3://synapse-snowflake-rds-snapshots-prod"]
}

# Synapse event/file-handle data (SNOW-14) — dev + prod
resource "snowflake_storage_integration" "synapse_prod_warehouse_s3" {
  name    = "SYNAPSE_PROD_WAREHOUSE_S3"
  type    = "EXTERNAL_STAGE"
  enabled = true
  storage_provider     = "S3"
  storage_aws_role_arn = "arn:aws:iam::325565585839:role/snowflake-access-SnowflakeServiceRole-2JSCDRkX8TcW"
  storage_allowed_locations = [
    "s3://prod.datawarehouse.sagebase.org",
    "s3://prod.filehandles.sagebase.org",
  ]
}

resource "snowflake_storage_integration" "synapse_dev_warehouse_s3" {
  name    = "SYNAPSE_DEV_WAREHOUSE_S3"
  type    = "EXTERNAL_STAGE"
  enabled = true
  storage_provider     = "S3"
  storage_aws_role_arn = "arn:aws:iam::449435941126:role/snowflake-access-SnowflakeServiceRole-BKQMHdbc4uU4"
  storage_allowed_locations = [
    "s3://dev.datawarehouse.sagebase.org",
    "s3://dev.filehandles.sagebase.org",
  ]
}
