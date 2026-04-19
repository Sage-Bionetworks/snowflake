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
      name = "snowflake-identity"
    }
  }
}

# Default provider as USERADMIN — creates users and roles.
provider "snowflake" {
  organization_name      = var.snowflake_organization_name
  account_name           = var.snowflake_account_name
  user                   = var.snowflake_user
  authenticator          = "SNOWFLAKE_JWT"
  private_key            = var.snowflake_private_key
  private_key_passphrase = var.snowflake_private_key_passphrase
  role                   = "USERADMIN"
}

# SECURITYADMIN — assigns roles to users/roles (GRANT ROLE requires SECURITYADMIN).
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

# ACCOUNTADMIN — account-level privilege grants (EXECUTE TASK, APPLY MASKING POLICY, etc.)
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
