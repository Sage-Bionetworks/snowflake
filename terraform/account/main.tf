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
      name = "snowflake-account"
    }
  }
}

# Default provider operates as ACCOUNTADMIN — required for integrations and policies.
provider "snowflake" {
  organization_name      = var.snowflake_organization_name
  account_name           = var.snowflake_account_name
  user                   = var.snowflake_user
  authenticator          = "SNOWFLAKE_JWT"
  private_key            = var.snowflake_private_key
  private_key_passphrase = var.snowflake_private_key_passphrase
  role                   = "ACCOUNTADMIN"
}
