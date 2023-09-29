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

resource "snowflake_role" "data_engineering" {
  provider = snowflake.useradmin
  name    = "DATA_ENGINEERING"
  comment = "Synapse data engineering"
}

resource "snowflake_role_grants" "data_engineering_grants" {
  provider = snowflake.securityadmin
  role_name = snowflake_role.data_engineering.name

  roles = [
    "USERADMIN",
  ]

  users = [
    snowflake_user.bmacdonald.name,
    snowflake_user.rxu.name,
    snowflake_user.psnyder.name,
    snowflake_user.bfauble.name,
  ]
}

resource "snowflake_database_grant" "data_engineering_grant" {
  database_name = "SYNAPSE_DATA_WAREHOUSE"

  privilege = "ALL PRIVILEGES"
  roles     = [snowflake_role_grants.data_engineering_grants]

  with_grant_option = false
}

# resource "snowflake_schema_grant" "data_engineering_grant" {
#   database_name = "SYNAPSE_DATA_WAREHOUSE"
#   schema_name   = "SYNAPSE_RAW"

#   privilege = "ALL PRIVILEGES"
#   roles     = [snowflake_role.data_engineering.name]

#   on_future         = true
#   with_grant_option = false
# }

# resource "snowflake_schema_grant" "grant" {
#   database_name = "SYNAPSE_DATA_WAREHOUSE"
#   schema_name   = "SYNAPSE"

#   privilege = "ALL PRIVILEGES"
#   roles     = [snowflake_role.data_engineering.name]

#   on_future         = true
#   with_grant_option = false
# }
