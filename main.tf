terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "0.69.0"
      # TODO: version = "0.71.0"
    }
  }
  cloud {
    organization = "sage-bionetworks"

    workspaces {
      name = "snowflake"
    }
  }
}

provider "snowflake" {
  account = var.snowflake_account
  username = var.snowflake_user
  password = var.snowflake_pwd
  role = "SYSADMIN"
}

provider "snowflake" {
  alias = "useradmin"
  account = var.snowflake_account
  username = var.snowflake_user
  password = var.snowflake_pwd
  role = "USERADMIN"
}

provider "snowflake" {
  alias = "accountadmin"
  account = var.snowflake_account
  username = var.snowflake_user
  password = var.snowflake_pwd
  role = "ACCOUNTADMIN"
}
