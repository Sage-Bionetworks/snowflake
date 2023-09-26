resource "snowflake_role" "genie" {
  provider = snowflake.useradmin
  name    = "GENIE_ADMIN"
  comment = "GENIE snowflake administrators"
}

resource "snowflake_role_grants" "genie_grants" {
  provider = snowflake.securityadmin
  role_name = snowflake_role.genie.name

  roles = [
    "SYSADMIN",
  ]

  users = [
    snowflake_user.apaynter.name,
    snowflake_user.cnayan.name,
    snowflake_user.xguo.name,
  ]
}