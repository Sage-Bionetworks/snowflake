# ── Snowflake connection ──────────────────────────────────────────────────────

variable "snowflake_organization_name" {
  description = "Snowflake organization name — first segment of the account locator (e.g. 'MQZFHLD')"
  type        = string
}

variable "snowflake_account_name" {
  description = "Snowflake account name — second segment of the account locator (e.g. 'VP00034')"
  type        = string
}

variable "snowflake_user" {
  description = "Snowflake user to authenticate as (ADMIN_SERVICE for most operations)"
  type        = string
}

variable "snowflake_private_key" {
  description = "PEM-encoded RSA private key for key-pair authentication"
  type        = string
  sensitive   = true
}

variable "snowflake_private_key_passphrase" {
  description = "Passphrase for the encrypted private key; omit if key is unencrypted"
  type        = string
  sensitive   = true
  default     = null
}

# ── SYNAPSE_DATA_WAREHOUSE stage URLs ─────────────────────────────────────────
# These correspond to SNOWFLAKE_SYNAPSE_STAGE_URL / SNOWFLAKE_SNAPSHOTS_STAGE_URL
# env vars used by schemachange.  Passed in from GitHub Secrets / HCP Terraform.

variable "synapse_prod_stage_url" {
  description = "S3 URL for the prod Synapse event/snapshot external stage (SNOWFLAKE_SYNAPSE_STAGE_URL prod)"
  type        = string
}

variable "synapse_dev_stage_url" {
  description = "S3 URL for the dev Synapse event/snapshot external stage (SNOWFLAKE_SYNAPSE_STAGE_URL dev)"
  type        = string
}

variable "synapse_snapshots_prod_stage_url" {
  description = "S3 URL for the prod RDS-snapshot external stage (SNOWFLAKE_SNAPSHOTS_STAGE_URL prod)"
  type        = string
}

variable "synapse_snapshots_dev_stage_url" {
  description = "S3 URL for the dev RDS-snapshot external stage (SNOWFLAKE_SNAPSHOTS_STAGE_URL dev)"
  type        = string
}
