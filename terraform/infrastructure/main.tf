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
      name = "snowflake-infrastructure"
    }
  }
}

# Default provider as SYSADMIN — creates warehouses and databases.
provider "snowflake" {
  organization_name      = var.snowflake_organization_name
  account_name           = var.snowflake_account_name
  user                   = var.snowflake_user
  authenticator          = "SNOWFLAKE_JWT"
  private_key            = var.snowflake_private_key
  private_key_passphrase = var.snowflake_private_key_passphrase
  role                   = "SYSADMIN"
}
