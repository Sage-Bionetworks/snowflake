terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "0.71"
    }
  }
}

provider "snowflake" {
  account = "mqzfhld-vp00034"
  username = "thomasyu888"
  password = "QNy26EJ!KMP7RScr"
  role = "SYSADMIN"
}

provider "snowflake" {
  alias = "useradmin"
  account = "mqzfhld-vp00034"
  username = "thomasyu888"
  password = "QNy26EJ!KMP7RScr"
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