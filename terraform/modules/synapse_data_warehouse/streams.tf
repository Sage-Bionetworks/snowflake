# ── SYNAPSE_DATA_WAREHOUSE streams ────────────────────────────────────────────
# Mirrors current stream state after all V__ migrations:
#   Created: V1.13.0__create_streams.sql
#   Modified: V2.2.0__recreate_certified_quiz_streams.sql (new source tables)
#   Removed: V2.26.2__delete_nodesnapshots_stream.sql (NODESNAPSHOTS_STREAM dropped)
#
# Streams capture change data from snapshot tables and are consumed by merge
# tasks (upsert_to_*_latest_task). Streams depend on the tables they monitor,
# which are managed by schemachange — not Terraform.
# provider: snowflake.sysadmin

locals {
  # Current active streams in SYNAPSE_RAW (NODESNAPSHOTS_STREAM was dropped in V2.26.2)
  # Map of stream_name => source_table_name
  synapse_raw_streams = {
    ACLSNAPSHOTS_STREAM                    = "ACLSNAPSHOTS"
    CERTIFIEDQUIZ_STREAM                   = "CERTIFIEDQUIZSNAPSHOTS"           # V2.2.0: now on CERTIFIEDQUIZSNAPSHOTS
    CERTIFIEDQUIZQUESTION_STREAM           = "CERTIFIEDQUIZQUESTIONSNAPSHOTS"   # V2.2.0: now on CERTIFIEDQUIZQUESTIONSNAPSHOTS
    USERPROFILESNAPSHOT_STREAM             = "USERPROFILESNAPSHOT"
    TEAMMEMBERSNAPSHOTS_STREAM             = "TEAMMEMBERSNAPSHOTS"
    FILESNAPSHOTS_STREAM                   = "FILESNAPSHOTS"
    TEAMSNAPSHOTS_STREAM                   = "TEAMSNAPSHOTS"
    USERGROUPSNAPSHOTS_STREAM              = "USERGROUPSNAPSHOTS"
    VERIFICATIONSUBMISSIONSNAPSHOTS_STREAM = "VERIFICATIONSUBMISSIONSNAPSHOTS"
  }
}

# Create each stream in the database managed by this module instance.
resource "snowflake_stream_on_table" "synapse_raw" {
  for_each = local.synapse_raw_streams

  provider = snowflake.sysadmin
  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = each.key

  # Source table is managed by schemachange — reference by fully qualified name
  table = "${var.database_name}.SYNAPSE_RAW.${each.value}"

  # append_only = false (default): capture inserts, updates, and deletes
  # show_initial_rows = false (default): only new changes after stream creation

  depends_on = [snowflake_schema.synapse_raw]
}
