resource "snowflake_role" "genie" {
  provider = snowflake.useradmin
  name    = "GENIE_ADMIN"
  comment = "GENIE snowflake administrators"
}

resource "snowflake_role_grants" "genie_grants" {
  provider = snowflake.securityadmin
  role_name = snowflake_role.genie.name

  roles = [
    "USERADMIN",
  ]

  users = [
    snowflake_user.apaynter.name,
    snowflake_user.cnayan.name,
    snowflake_user.xguo.name,
  ]
}

resource "snowflake_role" "recover_data_analytics" {
  provider = snowflake.useradmin
  name    = "RECOVER_DATA_ANALYTICS"
  comment = "RECOVER data analytics team"
}

resource "snowflake_role_grants" "recover_data_analytics_grants" {
  provider = snowflake.securityadmin
  role_name = snowflake_role.recover_data_analytics.name

  roles = [
    "USERADMIN",
  ]

  users = [
    snowflake_user.meghasyam.name,
    snowflake_user.panbarasu.name,
    snowflake_user.eneto.name,
  ]
}
