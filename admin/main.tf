terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "0.71"
    }
  }
  cloud {
    organization = "sage-bionetworks"

    workspaces {
      name = "snowflake"
    }
  }
}

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

resource "snowflake_warehouse" "warehouse" {
  name           = "COMPUTE_ORG"
  warehouse_size = "XSMALL"
  auto_suspend   = 90
  warehouse_type = "STANDARD"
  auto_resume    = true
  initially_suspended = null
  max_concurrency_level = 8 // default
  query_acceleration_max_scale_factor = 8 // default
  statement_queued_timeout_in_seconds = 0 // default
  statement_timeout_in_seconds = 10800 // default is 2 days
}

resource "snowflake_user" "user" {
  provider = snowflake.useradmin
  name         = "thomas.yu@sagebase.org"
  login_name   = "thomas.yu@sagebase.org"
}

resource "snowflake_user" "bmacdonald" {
  provider = snowflake.useradmin
  name         = "brad.macdonald@sagebase.org"
  login_name   = "brad.macdonald@sagebase.org"
}

resource "snowflake_user" "rxu" {
  provider = snowflake.useradmin
  name         = "rixing.xu@sagebase.org"
  login_name   = "rixing.xu@sagebase.org"
}

resource "snowflake_user" "dthach" {
  provider = snowflake.useradmin
  name         = "diep.thach@sagebase.org"
  login_name   = "diep.thach@sagebase.org"
}

resource "snowflake_user" "avu" {
  provider = snowflake.useradmin
  name         = "anh.nguyet.vu@sagebase.org"
  login_name   = "anh.nguyet.vu@sagebase.org"
}

resource "snowflake_user" "lfoschini" {
  provider = snowflake.useradmin
  name         = "luca.foschini@sagebase.org"
  login_name   = "luca.foschini@sagebase.org"
}
