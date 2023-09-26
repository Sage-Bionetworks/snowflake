
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
