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

resource "snowflake_user" "sjobe" {
  provider = snowflake.useradmin
  name         = "sophia.jobe@sagebase.org"
  login_name   = "sophia.jobe@sagebase.org"
}

resource "snowflake_user" "xguo" {
  provider = snowflake.useradmin
  name         = "xindi.guo@sagebase.org"
  login_name   = "xindi.guo@sagebase.org"
}

resource "snowflake_user" "avanderlinden" {
  provider = snowflake.useradmin
  name         = "abby.vanderlinden@sagebase.org"
  login_name   = "abby.vanderlinden@sagebase.org"
}

resource "snowflake_user" "psnyder" {
  provider = snowflake.useradmin
  name         = "phil.snyder@sagebase.org"
  login_name   = "phil.snyder@sagebase.org"
}

resource "snowflake_user" "cnayan" {
  provider = snowflake.useradmin
  name         = "chelsea.nayan@sagebase.org"
  login_name   = "chelsea.nayan@sagebase.org"
}

resource "snowflake_user" "apaynter" {
  provider = snowflake.useradmin
  name         = "alex.paynter@sagebase.org"
  login_name   = "alex.paynter@sagebase.org"
}

resource "snowflake_user" "xschildwachter" {
  provider = snowflake.useradmin
  name         = "x.schildwachter@sagebase.org"
  login_name   = "x.schildwachter@sagebase.org"
}

resource "snowflake_user" "nedmonds" {
  provider = snowflake.useradmin
  name         = "natosha.edmonds@sagebase.org"
  login_name   = "natosha.edmonds@sagebase.org"
}

resource "snowflake_user" "kboske" {
  provider = snowflake.useradmin
  name         = "kevin.boske@sagebase.org"
  login_name   = "kevin.boske@sagebase.org"
}

resource "snowflake_user" "rallaway" {
  provider = snowflake.useradmin
  name         = "robert.allaway@sagebase.org"
  login_name   = "robert.allaway@sagebase.org"
}

resource "snowflake_user" "nlee" {
  provider = snowflake.useradmin
  name         = "nicholas.lee@sagebase.org"
  login_name   = "nicholas.lee@sagebase.org"
}

resource "snowflake_user" "vbaham" {
  provider = snowflake.useradmin
  name         = "victor.baham@sagebase.org"
  login_name   = "victor.baham@sagebase.org"
}
