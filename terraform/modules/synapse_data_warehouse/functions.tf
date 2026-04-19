# ── SYNAPSE_DATA_WAREHOUSE SQL functions ──────────────────────────────────────
# Mirrors: synapse_data_warehouse/synapse/functions/V2.64.0__sage_employees_function.sql
# provider: snowflake.sysadmin

# list_sage_users() — returns Synapse user IDs for current Sage employees.
# Queries team_id 273957 (the Sage staff Synapse team) via TEAMMEMBER_LATEST.
resource "snowflake_function_sql" "list_sage_users" {
  provider = snowflake.sysadmin

  database = var.database_name
  schema   = "SYNAPSE"
  name     = "LIST_SAGE_USERS"

  return_type = "TABLE(USER_ID NUMBER)"
  comment     = "Returns a table with column `user_id` containing the Synapse user IDs of current Sage employees"

  function_definition = <<-SQL
    SELECT member_id AS user_id
    FROM ${var.database_name}.synapse.teammember_latest
    WHERE team_id = 273957
  SQL

  depends_on = [snowflake_schema.synapse]
}
