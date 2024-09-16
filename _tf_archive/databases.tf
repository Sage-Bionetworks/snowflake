resource "snowflake_database" "synapse_data_warehouse" {
  name = "SYNAPSE_DATA_WAREHOUSE"
}

# resource "snowflake_schema" "synapse_raw_schema" {
#   database = snowflake_database.synapse_data_warehouse.name
#   name     = "SYNAPSE_RAW"

#   is_transient        = false
#   is_managed          = true
#   data_retention_days = 1
# }
