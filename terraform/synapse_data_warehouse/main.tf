terraform {
  required_version = ">= 1.5"

  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 1.0"
    }
  }

  cloud {
    organization = "sage-bionetworks"
    workspaces {
      name = "snowflake-sdw"
    }
  }
}

# All three providers are passed into the reusable SDW module.
# No resources are defined directly in this root module.

provider "snowflake" {
  alias                  = "sysadmin"
  organization_name      = var.snowflake_organization_name
  account_name           = var.snowflake_account_name
  user                   = var.snowflake_user
  authenticator          = "SNOWFLAKE_JWT"
  private_key            = var.snowflake_private_key
  private_key_passphrase = var.snowflake_private_key_passphrase
  role                   = "SYSADMIN"
}

provider "snowflake" {
  alias                  = "securityadmin"
  organization_name      = var.snowflake_organization_name
  account_name           = var.snowflake_account_name
  user                   = var.snowflake_user
  authenticator          = "SNOWFLAKE_JWT"
  private_key            = var.snowflake_private_key
  private_key_passphrase = var.snowflake_private_key_passphrase
  role                   = "SECURITYADMIN"
}

provider "snowflake" {
  alias                  = "accountadmin"
  organization_name      = var.snowflake_organization_name
  account_name           = var.snowflake_account_name
  user                   = var.snowflake_user
  authenticator          = "SNOWFLAKE_JWT"
  private_key            = var.snowflake_private_key
  private_key_passphrase = var.snowflake_private_key_passphrase
  role                   = "ACCOUNTADMIN"
}
