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

# ── SAML2 / Google SSO ────────────────────────────────────────────────────────
# Sourced from GitHub Secrets / HCP Terraform variable set. Never hardcode.

variable "saml2_issuer" {
  description = "Google Workspace SAML2 issuer URL"
  type        = string
  sensitive   = true
}

variable "saml2_sso_url" {
  description = "Google Workspace SAML2 SSO redirect URL"
  type        = string
  sensitive   = true
}

variable "saml2_x509_cert" {
  description = "Google Workspace SAML2 x509 certificate (PEM body, no header/footer lines)"
  type        = string
  sensitive   = true
}
