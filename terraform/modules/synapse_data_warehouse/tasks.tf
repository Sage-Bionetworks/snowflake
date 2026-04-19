# ── SYNAPSE_DATA_WAREHOUSE tasks ───────────────────────────────────────────────
# Represents the current active task DAG after all V__ migrations.
# Dropped tasks are NOT included (see comments below for dropped tasks).
#
# DAG structure (SYNAPSE_RAW schema):
#   refresh_synapse_warehouse_s3_stage_task  ← root, cron 23:00 daily LA time
#     ├─ certifiedquiz_task
#     │    └─ upsert_to_certifiedquiz_latest_task
#     ├─ certifiedquizquestion_task          (leaf — downstream task dropped V2.29.1)
#     ├─ nodesnapshot_task                   (leaf — downstream task dropped V2.26.1)
#     ├─ filesnapshots_task                  (leaf — downstream task dropped V2.36.1)
#     ├─ userprofilesnapshot_task            (leaf — downstream task dropped V2.30.1)
#     ├─ teammembersnapshots_task            (leaf — downstream task dropped V2.42.1)
#     ├─ aclsnapshots_task                   (leaf)
#     ├─ teamsnapshots_task                  (leaf)
#     ├─ usergroupsnapshots_task             (leaf)
#     ├─ verificationsubmissionsnapshots_task (leaf)
#     ├─ append_to_filehandleassociationsnapshots_task (leaf)
#     ├─ append_to_fileinventory_task        (leaf)
#     ├─ processedaccess_task
#     │    ├─ clone_process_access_task
#     │    └─ create_access_event_task
#     ├─ filedownload_task
#     │    └─ clone_filedownload_task
#     └─ fileupload_task
#          ├─ clone_fileupload_task
#          └─ create_fileupload_event_task
#
# SYNAPSE schema:
#   backup_synapse_data_warehouse_task  ← root, cron 03:00 Sundays LA time
#     └─ revoke_backup_synapse_access   (started = false in both envs; resume prod manually)
#
# SQL bodies below reflect the latest ALTER TASK MODIFY AS state.
# All tasks use USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE (serverless); no warehouse needed.
# provider: snowflake.accountadmin (tasks were created with USE ROLE ACCOUNTADMIN in SQL)

# ── Root task: stage refresh ──────────────────────────────────────────────────
resource "snowflake_task" "refresh_stage" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK"

  user_task_managed_initial_warehouse_size = "SMALL"
  schedule { using_cron = "0 23 * * * America/Los_Angeles" }
  started = true

  sql_statement = "ALTER STAGE IF EXISTS ${var.stage_storage_integration}_STAGE REFRESH"

  depends_on = [snowflake_stage.synapse_warehouse_s3]
}

# ── Tier 1: COPY INTO tasks (after stage refresh) ─────────────────────────────

resource "snowflake_task" "certifiedquiz" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "CERTIFIEDQUIZ_TASK"
  user_task_managed_initial_warehouse_size = "SMALL"
  after   = ["REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK"]
  started = true

  sql_statement = <<-SQL
    COPY INTO certifiedquiz
    FROM (
      SELECT
        $1:response_id AS response_id,
        $1:user_id AS user_id,
        $1:passed AS passed,
        $1:passed_on AS passed_on,
        $1:stack AS stack,
        $1:instance AS instance,
        NULLIF(
          REGEXP_REPLACE(metadata$filename,
            '.*certifiedquizrecords\\/record_date\\=(.*)\\/.* ', '\\1'),
          '__HIVE_DEFAULT_PARTITION__'
        ) AS record_date
      FROM @${var.stage_storage_integration}_STAGE/certifiedquizrecords
    )
    PATTERN = '.*certifiedquizrecords/record_date=.*/.*'
  SQL
}

resource "snowflake_task" "certifiedquizquestion" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "CERTIFIEDQUIZQUESTION_TASK"
  user_task_managed_initial_warehouse_size = "SMALL"
  after   = ["REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK"]
  started = true

  sql_statement = <<-SQL
    COPY INTO certifiedquizquestion
    FROM (
      SELECT
        $1:response_id AS response_id,
        $1:question_index AS question_index,
        $1:is_correct AS is_correct,
        $1:stack AS stack,
        $1:instance AS instance,
        NULLIF(
          REGEXP_REPLACE(metadata$filename,
            '.*certifiedquizquestionrecords\\/record_date\\=(.*)\\/.* ', '\\1'),
          '__HIVE_DEFAULT_PARTITION__'
        ) AS record_date
      FROM @${var.stage_storage_integration}_STAGE/certifiedquizquestionrecords
    )
    PATTERN = '.*certifiedquizquestionrecords/record_date=.*/.*'
  SQL
}

resource "snowflake_task" "nodesnapshot" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "NODESNAPSHOT_TASK"
  user_task_managed_initial_warehouse_size = "SMALL"
  after   = ["REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK"]
  started = true

  # SQL body reflects V2.25.1 (adds version_history, annotations, derived_annotations, etc.)
  sql_statement = <<-SQL
    COPY INTO nodesnapshots
    FROM (
      SELECT
        $1:change_type AS change_type,
        $1:change_timestamp AS change_timestamp,
        $1:change_user_id AS change_user_id,
        $1:snapshot_timestamp AS snapshot_timestamp,
        $1:id AS id,
        $1:benefactor_id AS benefactor_id,
        $1:project_id AS project_id,
        $1:parent_id AS parent_id,
        $1:node_type AS node_type,
        $1:created_on AS created_on,
        $1:created_by AS created_by,
        $1:modified_on AS modified_on,
        $1:modified_by AS modified_by,
        $1:version_number AS version_number,
        $1:file_handle_id AS file_handle_id,
        $1:name AS name,
        $1:is_public AS is_public,
        $1:is_controlled AS is_controlled,
        $1:is_restricted AS is_restricted,
        NULLIF(
          REGEXP_REPLACE(metadata$filename,
            '.*nodesnapshots\\/snapshot_date\\=(.*)\\/.* ', '\\1'),
          '__HIVE_DEFAULT_PARTITION__'
        ) AS snapshot_date,
        $1:effective_ars AS effective_ars,
        PARSE_JSON(REPLACE(REPLACE($1:annotations, '\n', '\\n'), '\r', '\\r')) AS annotations,
        PARSE_JSON(REPLACE(REPLACE($1:derived_annotations, '\n', '\\n'), '\r', '\\r')) AS derived_annotations,
        $1:version_comment AS version_comment,
        $1:version_label AS version_label,
        $1:alias AS alias,
        $1:activity_id AS activity_id,
        PARSE_JSON($1:column_model_ids) AS column_model_ids,
        PARSE_JSON($1:scope_ids) AS scope_ids,
        PARSE_JSON($1:items) AS items,
        PARSE_JSON($1:reference) AS reference,
        $1:is_search_enabled AS is_search_enabled,
        $1:defining_sql AS defining_sql,
        PARSE_JSON(REPLACE(REPLACE($1:internal_annotations, '\n', '\\n'), '\r', '\\r')) AS internal_annotations,
        PARSE_JSON(REPLACE(REPLACE($1:version_history, '\n', '\\n'), '\r', '\\r')) AS version_history
      FROM @${var.stage_storage_integration}_STAGE/nodesnapshots/
    )
    PATTERN = '.*nodesnapshots/snapshot_date=.*/.*'
  SQL
}

resource "snowflake_task" "filesnapshots" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "FILESNAPSHOTS_TASK"
  user_task_managed_initial_warehouse_size = "SMALL"
  after   = ["REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK"]
  started = true

  sql_statement = <<-SQL
    COPY INTO filesnapshots
    FROM (
      SELECT
        $1:change_type AS change_type,
        $1:change_timestamp AS change_timestamp,
        $1:change_user_id AS change_user_id,
        $1:snapshot_timestamp AS snapshot_timestamp,
        $1:id AS id,
        $1:created_by AS created_by,
        $1:created_on AS created_on,
        $1:modified_on AS modified_on,
        $1:concrete_type AS concrete_type,
        $1:content_md5 AS content_md5,
        $1:content_type AS content_type,
        MD5($1:file_name) AS file_name,
        $1:storage_location_id AS storage_location_id,
        $1:content_size AS content_size,
        $1:bucket AS bucket,
        MD5($1:key) AS key,
        $1:preview_id AS preview_id,
        $1:is_preview AS is_preview,
        $1:status AS status,
        NULLIF(
          REGEXP_REPLACE(metadata$filename,
            '.*filesnapshots\\/snapshot_date\\=(.*)\\/.* ', '\\1'),
          '__HIVE_DEFAULT_PARTITION__'
        ) AS snapshot_date
      FROM @${var.stage_storage_integration}_STAGE/filesnapshots
    )
    PATTERN = '.*filesnapshots/snapshot_date=.*/.*'
  SQL
}

resource "snowflake_task" "userprofilesnapshot" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "USERPROFILESNAPSHOT_TASK"
  user_task_managed_initial_warehouse_size = "SMALL"
  after   = ["REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK"]
  started = true

  sql_statement = <<-SQL
    COPY INTO userprofilesnapshot
    FROM (
      SELECT
        $1:change_type AS change_type,
        $1:change_timestamp AS change_timestamp,
        $1:change_user_id AS change_user_id,
        $1:snapshot_timestamp AS snapshot_timestamp,
        $1:id AS id,
        $1:user_name AS user_name,
        $1:first_name AS first_name,
        $1:last_name AS last_name,
        REGEXP_REPLACE($1:email, '.+\\@', '*****@') AS email,
        $1:location AS location,
        $1:company AS company,
        $1:position AS position,
        NULLIF(
          REGEXP_REPLACE(metadata$filename,
            '.*userprofilesnapshots\\/snapshot_date\\=(.*)\\/.* ', '\\1'),
          '__HIVE_DEFAULT_PARTITION__'
        ) AS snapshot_date
      FROM @${var.stage_storage_integration}_STAGE/userprofilesnapshots
    )
    PATTERN = '.*userprofilesnapshots/snapshot_date=.*/.*'
  SQL
}

resource "snowflake_task" "teammembersnapshots" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "TEAMMEMBERSNAPSHOTS_TASK"
  user_task_managed_initial_warehouse_size = "SMALL"
  after   = ["REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK"]
  started = true

  sql_statement = <<-SQL
    COPY INTO teammembersnapshots
    FROM (
      SELECT
        $1:change_type AS change_type,
        $1:change_timestamp AS change_timestamp,
        $1:change_user_id AS change_user_id,
        $1:snapshot_timestamp AS snapshot_timestamp,
        $1:team_id AS team_id,
        $1:member_id AS member_id,
        $1:is_admin AS is_admin,
        NULLIF(
          REGEXP_REPLACE(metadata$filename,
            '.*teammembersnapshots\\/snapshot_date\\=(.*)\\/.* ', '\\1'),
          '__HIVE_DEFAULT_PARTITION__'
        ) AS snapshot_date
      FROM @${var.stage_storage_integration}_STAGE/teammembersnapshots
    )
    PATTERN = '.*teammembersnapshots/snapshot_date=.*/.*'
  SQL
}

resource "snowflake_task" "aclsnapshots" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "ACLSNAPSHOTS_TASK"
  user_task_managed_initial_warehouse_size = "SMALL"
  after   = ["REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK"]
  started = true

  sql_statement = <<-SQL
    COPY INTO aclsnapshots
    FROM (
      SELECT
        $1:change_timestamp AS change_timestamp,
        $1:change_type AS change_type,
        $1:snapshot_timestamp AS snapshot_timestamp,
        $1:owner_id AS owner_id,
        $1:owner_type AS owner_type,
        $1:created_on AS created_on,
        $1:resource_access AS resource_access,
        NULLIF(
          REGEXP_REPLACE(metadata$filename,
            '.*aclsnapshots\\/snapshot_date\\=(.*)\\/.* ', '\\1'),
          '__HIVE_DEFAULT_PARTITION__'
        ) AS snapshot_date
      FROM @${var.stage_storage_integration}_STAGE/aclsnapshots
    )
    PATTERN = '.*aclsnapshots/snapshot_date=.*/.*'
  SQL
}

resource "snowflake_task" "teamsnapshots" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "TEAMSNAPSHOTS_TASK"
  user_task_managed_initial_warehouse_size = "SMALL"
  after   = ["REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK"]
  started = true

  sql_statement = <<-SQL
    COPY INTO teamsnapshots
    FROM (
      SELECT
        $1:change_type AS change_type,
        $1:change_timestamp AS change_timestamp,
        $1:change_user_id AS change_user_id,
        $1:snapshot_timestamp AS snapshot_timestamp,
        $1:id AS id,
        $1:name AS name,
        $1:can_public_join AS can_public_join,
        $1:created_on AS created_on,
        $1:created_by AS created_by,
        $1:modified_on AS modified_on,
        $1:modified_by AS modified_by,
        NULLIF(
          REGEXP_REPLACE(metadata$filename,
            '.*teamsnapshots\\/snapshot_date\\=(.*)\\/.* ', '\\1'),
          '__HIVE_DEFAULT_PARTITION__'
        ) AS snapshot_date
      FROM @${var.stage_storage_integration}_STAGE/teamsnapshots
    )
    PATTERN = '.*teamsnapshots/snapshot_date=.*/.*'
  SQL
}

resource "snowflake_task" "usergroupsnapshots" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "USERGROUPSNAPSHOTS_TASK"
  user_task_managed_initial_warehouse_size = "SMALL"
  after   = ["REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK"]
  started = true

  sql_statement = <<-SQL
    COPY INTO usergroupsnapshots
    FROM (
      SELECT
        $1:change_type AS change_type,
        $1:change_timestamp AS change_timestamp,
        $1:change_user_id AS change_user_id,
        $1:snapshot_timestamp AS snapshot_timestamp,
        $1:id AS id,
        $1:is_individual AS is_individual,
        $1:created_on AS created_on,
        NULLIF(
          REGEXP_REPLACE(metadata$filename,
            '.*usergroupsnapshots\\/snapshot_date\\=(.*)\\/.* ', '\\1'),
          '__HIVE_DEFAULT_PARTITION__'
        ) AS snapshot_date
      FROM @${var.stage_storage_integration}_STAGE/usergroupsnapshots
    )
    PATTERN = '.*usergroupsnapshots/snapshot_date=.*/.*'
  SQL
}

resource "snowflake_task" "verificationsubmissionsnapshots" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "VERIFICATIONSUBMISSIONSNAPSHOTS_TASK"
  user_task_managed_initial_warehouse_size = "SMALL"
  after   = ["REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK"]
  started = true

  sql_statement = <<-SQL
    COPY INTO verificationsubmissionsnapshots
    FROM (
      SELECT
        $1:change_timestamp AS change_timestamp,
        $1:change_type AS change_type,
        $1:snapshot_timestamp AS snapshot_timestamp,
        $1:id AS id,
        $1:created_on AS created_on,
        $1:created_by AS created_by,
        $1:state_history AS state_history,
        NULLIF(
          REGEXP_REPLACE(metadata$filename,
            '.*verificationsubmissionsnapshots\\/snapshot_date\\=(.*)\\/.* ', '\\1'),
          '__HIVE_DEFAULT_PARTITION__'
        ) AS snapshot_date
      FROM @${var.stage_storage_integration}_STAGE/verificationsubmissionsnapshots
    )
    PATTERN = '.*verificationsubmissionsnapshots/snapshot_date=.*/.*'
  SQL
}

resource "snowflake_task" "processedaccess" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "PROCESSEDACCESS_TASK"
  user_task_managed_initial_warehouse_size = "SMALL"
  after   = ["REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK"]
  started = true

  sql_statement = <<-SQL
    COPY INTO processedaccess
    FROM (
      SELECT
        $1:session_id AS session_id,
        $1:timestamp AS timestamp,
        $1:user_id AS user_id,
        $1:method AS method,
        $1:request_url AS request_url,
        $1:user_agent AS user_agent,
        $1:host AS host,
        $1:origin AS origin,
        $1:x_forwarded_for AS x_forwarded_for,
        $1:via AS via,
        $1:thread_id AS thread_id,
        $1:elapse_ms AS elapse_ms,
        $1:success AS success,
        $1:stack AS stack,
        $1:instance AS instance,
        $1:vm_id AS vm_id,
        $1:return_object_id AS return_object_id,
        $1:query_string AS query_string,
        $1:response_status AS response_status,
        $1:oauth_client_id AS oauth_client_id,
        $1:basic_auth_username AS basic_auth_username,
        $1:auth_method AS auth_method,
        $1:normalized_method_signature AS normalized_method_signature,
        $1:client AS client,
        $1:client_version AS client_version,
        $1:entity_id AS entity_id,
        NULLIF(
          REGEXP_REPLACE(metadata$filename,
            '.*processedaccessrecord\\/record_date\\=(.*)\\/.* ', '\\1'),
          '__HIVE_DEFAULT_PARTITION__'
        ) AS record_date
      FROM @${var.stage_storage_integration}_STAGE/processedaccessrecord
    )
    PATTERN = '.*processedaccessrecord/record_date=.*/.*'
  SQL
}

resource "snowflake_task" "filedownload" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "FILEDOWNLOAD_TASK"
  user_task_managed_initial_warehouse_size = "SMALL"
  after   = ["REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK"]
  started = true

  sql_statement = <<-SQL
    COPY INTO filedownload
    FROM (
      SELECT
        $1:timestamp AS timestamp,
        $1:user_id AS user_id,
        $1:project_id AS project_id,
        $1:file_handle_id AS file_handle_id,
        $1:downloaded_file_handle_id AS downloaded_file_handle_id,
        $1:association_object_id AS association_object_id,
        $1:association_object_type AS association_object_type,
        $1:stack AS stack,
        $1:instance AS instance,
        $1:session_id AS session_id,
        NULLIF(
          REGEXP_REPLACE(metadata$filename,
            '.*filedownloadrecords\\/record_date\\=(.*)\\/.* ', '\\1'),
          '__HIVE_DEFAULT_PARTITION__'
        ) AS record_date
      FROM @${var.stage_storage_integration}_STAGE/filedownloadrecords
    )
    PATTERN = '.*filedownloadrecords/record_date=.*/.*'
  SQL
}

resource "snowflake_task" "fileupload" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "FILEUPLOAD_TASK"
  user_task_managed_initial_warehouse_size = "SMALL"
  after   = ["REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK"]
  started = true

  sql_statement = <<-SQL
    COPY INTO fileupload
    FROM (
      SELECT
        $1:timestamp AS timestamp,
        $1:user_id AS user_id,
        $1:project_id AS project_id,
        $1:file_handle_id AS file_handle_id,
        $1:association_object_id AS association_object_id,
        $1:association_object_type AS association_object_type,
        $1:stack AS stack,
        $1:instance AS instance,
        NULLIF(
          REGEXP_REPLACE(metadata$filename,
            '.*fileuploadrecords\\/record_date\\=(.*)\\/.* ', '\\1'),
          '__HIVE_DEFAULT_PARTITION__'
        ) AS record_date
      FROM @${var.stage_storage_integration}_STAGE/fileuploadrecords
    )
    PATTERN = '.*fileuploadrecords/record_date=.*/.*'
  SQL
}

resource "snowflake_task" "append_filehandleassociationsnapshots" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "APPEND_TO_FILEHANDLEASSOCIATIONSNAPSHOTS_TASK"
  user_task_managed_initial_warehouse_size = "SMALL"
  after   = ["REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK"]
  started = true

  sql_statement = <<-SQL
    COPY INTO filehandleassociationsnapshots
    FROM (
      SELECT
        $1:associateid AS associateid,
        $1:associatetype AS associatetype,
        $1:filehandleid AS filehandleid,
        $1:instance AS instance,
        $1:stack AS stack,
        $1:timestamp AS timestamp
      FROM @SYNAPSE_FILEHANDLES_STAGE
    )
  SQL

  depends_on = [snowflake_stage.synapse_filehandles]
}

resource "snowflake_task" "append_fileinventory" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "APPEND_TO_FILEINVENTORY_TASK"
  user_task_managed_initial_warehouse_size = "SMALL"
  after   = ["REFRESH_SYNAPSE_WAREHOUSE_S3_STAGE_TASK"]
  started = true

  # SQL body from V2.12.2 (final ALTER TASK MODIFY AS — adds snapshot_date from file metadata)
  sql_statement = <<-SQL
    COPY INTO fileinventory
    FROM (
      SELECT
        $1:bucket AS bucket,
        $1:e_tag AS e_tag,
        $1:encryption_status AS encryption_status,
        $1:intelligent_tiering_access_tier AS intelligent_tiering_access_tier,
        $1:is_delete_marker AS is_delete_marker,
        $1:is_latest AS is_latest,
        $1:is_multipart_uploaded AS is_multipart_uploaded,
        $1:key AS key,
        $1:last_modified_date AS last_modified_date,
        $1:object_owner AS object_owner,
        $1:size AS size,
        $1:storage_class AS storage_class,
        metadata$file_last_modified AS snapshot_date
      FROM @${var.stage_storage_integration}_STAGE/inventory
    )
    PATTERN = '.*defaultInventory/data/.*'
  SQL
}

# ── Tier 2: downstream tasks ──────────────────────────────────────────────────

resource "snowflake_task" "upsert_certifiedquiz_latest" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "UPSERT_TO_CERTIFIEDQUIZ_LATEST_TASK"
  user_task_managed_initial_warehouse_size = "XSMALL"
  after   = ["CERTIFIEDQUIZ_TASK"]
  started = true

  sql_statement = <<-SQL
    MERGE INTO ${var.database_name}.SYNAPSE.CERTIFIEDQUIZ_LATEST AS TARGET_TABLE
    USING (
      WITH CQQ_RANKED AS (
        SELECT
          *,
          ROW_NUMBER() OVER (
            PARTITION BY USER_ID
            ORDER BY INSTANCE DESC, RESPONSE_ID DESC
          ) AS ROW_NUM
        FROM CERTIFIEDQUIZ_STREAM
      )
      SELECT * EXCLUDE ROW_NUM FROM CQQ_RANKED WHERE ROW_NUM = 1
    ) AS SOURCE_TABLE ON TARGET_TABLE.USER_ID = SOURCE_TABLE.USER_ID
    WHEN MATCHED THEN UPDATE SET
      TARGET_TABLE.RESPONSE_ID = SOURCE_TABLE.RESPONSE_ID,
      TARGET_TABLE.PASSED = SOURCE_TABLE.PASSED,
      TARGET_TABLE.PASSED_ON = SOURCE_TABLE.PASSED_ON,
      TARGET_TABLE.STACK = SOURCE_TABLE.STACK,
      TARGET_TABLE.INSTANCE = SOURCE_TABLE.INSTANCE,
      TARGET_TABLE.RECORD_DATE = SOURCE_TABLE.RECORD_DATE
    WHEN NOT MATCHED THEN INSERT (RESPONSE_ID, USER_ID, PASSED, PASSED_ON, STACK, INSTANCE, RECORD_DATE)
    VALUES (SOURCE_TABLE.RESPONSE_ID, SOURCE_TABLE.USER_ID, SOURCE_TABLE.PASSED, SOURCE_TABLE.PASSED_ON,
            SOURCE_TABLE.STACK, SOURCE_TABLE.INSTANCE, SOURCE_TABLE.RECORD_DATE)
  SQL
}

resource "snowflake_task" "clone_processedaccess" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "CLONE_PROCESS_ACCESS_TASK"
  user_task_managed_initial_warehouse_size = "XSMALL"
  after   = ["PROCESSEDACCESS_TASK"]
  started = true

  sql_statement = "CREATE OR REPLACE TABLE ${var.database_name}.SYNAPSE.PROCESSEDACCESS CLONE ${var.database_name}.SYNAPSE_RAW.PROCESSEDACCESS"
}

resource "snowflake_task" "clone_filedownload" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "CLONE_FILEDOWNLOAD_TASK"
  user_task_managed_initial_warehouse_size = "XSMALL"
  after   = ["FILEDOWNLOAD_TASK"]
  started = true

  sql_statement = "CREATE OR REPLACE TABLE ${var.database_name}.SYNAPSE.FILEDOWNLOAD CLONE ${var.database_name}.SYNAPSE_RAW.FILEDOWNLOAD"
}

resource "snowflake_task" "clone_fileupload" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "CLONE_FILEUPLOAD_TASK"
  user_task_managed_initial_warehouse_size = "XSMALL"
  after   = ["FILEUPLOAD_TASK"]
  started = true

  sql_statement = "CREATE OR REPLACE TABLE ${var.database_name}.SYNAPSE.FILEUPLOAD CLONE ${var.database_name}.SYNAPSE_RAW.FILEUPLOAD"
}

resource "snowflake_task" "create_fileupload_event" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "CREATE_FILEUPLOAD_EVENT_TASK"
  user_task_managed_initial_warehouse_size = "XSMALL"
  after   = ["FILEUPLOAD_TASK"]
  started = true

  sql_statement = "CREATE OR REPLACE TABLE ${var.database_name}.SYNAPSE_EVENT.FILEUPLOAD_EVENT CLONE ${var.database_name}.SYNAPSE_RAW.FILEUPLOAD"

  depends_on = [snowflake_schema.synapse_event]
}

resource "snowflake_task" "create_access_event" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE_RAW"
  name     = "CREATE_ACCESS_EVENT_TASK"
  user_task_managed_initial_warehouse_size = "XSMALL"
  after   = ["PROCESSEDACCESS_TASK"]
  started = true

  sql_statement = "CREATE OR REPLACE TABLE ${var.database_name}.SYNAPSE_EVENT.ACCESS_EVENT CLONE ${var.database_name}.SYNAPSE_RAW.PROCESSEDACCESS"

  depends_on = [snowflake_schema.synapse_event]
}

# ── SYNAPSE schema: backup task (V2.59.0) ─────────────────────────────────────
# Runs weekly (Sundays 03:00 LA) to clone the prod database.
# started = false — comment in V2.59.0 notes prod resume must be done manually;
# dev should also remain suspended to avoid unnecessary clones.

resource "snowflake_task" "backup_synapse_data_warehouse" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE"
  name     = "BACKUP_SYNAPSE_DATA_WAREHOUSE_TASK"
  user_task_managed_initial_warehouse_size = "XSMALL"
  schedule { using_cron = "0 3 * * 0 America/Los_Angeles" }
  started = false  # Resume manually in prod only (see V2.59.0 comment)

  sql_statement = "CREATE OR REPLACE DATABASE BACKUP_SYNAPSE_DATA_WAREHOUSE CLONE SYNAPSE_DATA_WAREHOUSE"

  depends_on = [snowflake_schema.synapse]
}

resource "snowflake_task" "revoke_backup_synapse_access" {
  provider = snowflake.accountadmin

  database = var.database_name
  schema   = "SYNAPSE"
  name     = "REVOKE_BACKUP_SYNAPSE_ACCESS"
  user_task_managed_initial_warehouse_size = "XSMALL"
  after   = ["BACKUP_SYNAPSE_DATA_WAREHOUSE_TASK"]
  started = false  # Controlled by parent task resumed state

  sql_statement = "REVOKE USAGE ON DATABASE BACKUP_SYNAPSE_DATA_WAREHOUSE FROM ROLE SYNAPSE_DATA_WAREHOUSE_ANALYST"
}
