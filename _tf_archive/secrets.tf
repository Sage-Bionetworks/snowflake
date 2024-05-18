variable "snowflake_user" {
  description = "The username for snowflake user"
  type        = string
  sensitive   = true
}

variable "snowflake_pwd" {
  description = "The password for the snowflake user"
  type        = string
  sensitive   = true
}

variable "snowflake_account" {
  description = "The snowflake account"
  type        = string
  sensitive   = true
}

variable "saml2_issuer" {
  description = "Google SAML issuer"
  type        = string
  sensitive   = true
}

variable "saml2_sso_url" {
  description = "Google SAML SSO URL"
  type        = string
  sensitive   = true
}

variable "saml2_x509_cert" {
  description = "Google SAML x509 certificate"
  type        = string
  sensitive   = true
}
