-- Creates the remaining child tasks under proxy task B
-- Each task loads a separate data type from `RDS_SNAPSHOTS_STAGE`
USE SCHEMA {{database_name}}.RDS_LANDING; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE TASK COPY_PORTAL_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO portal FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:MODIFIED_BY::BIGINT                        AS modified_by,
            $1:MODIFIED_ON::TIMESTAMP_NTZ(9)              AS modified_on,
            $1:NAME::VARCHAR                              AS name,
            $1:ENDPOINT::VARCHAR                          AS endpoint,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/PORTAL/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_PRINCIPAL_OIDC_BINDING_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO principal_oidc_binding FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:PRINCIPAL_ID::BIGINT                       AS principal_id,
            $1:ALIAS_ID::BIGINT                           AS alias_id,
            $1:PROVIDER::VARCHAR                          AS provider,
            $1:SUBJECT::VARCHAR                           AS subject,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/PRINCIPAL_OIDC_BINDING/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_PRINCIPAL_PREFIX_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO principal_prefix FROM (
        SELECT
            $1:TOKEN::VARCHAR                             AS token,
            $1:PRINCIPAL_ID::BIGINT                       AS principal_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/PRINCIPAL_PREFIX/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_PROCESSED_MESSAGES_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO processed_messages FROM (
        SELECT
            $1:CHANGE_NUM::BIGINT                         AS change_num,
            $1:TIME_STAMP::TIMESTAMP_NTZ(9)               AS time_stamp,
            $1:QUEUE_NAME::VARCHAR                        AS queue_name,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/PROCESSED_MESSAGES/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_PROJECT_SETTING_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO project_setting FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:PROJECT_ID::BIGINT                         AS project_id,
            $1:TYPE::VARCHAR                              AS type,
            $1:ETAG::VARCHAR                              AS etag,
            $1:JSON::VARCHAR                              AS json,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/PROJECT_SETTING/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_PROJECT_STAT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO project_stat FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:PROJECT_ID::BIGINT                         AS project_id,
            $1:USER_ID::BIGINT                            AS user_id,
            $1:LAST_ACCESSED::BIGINT                      AS last_accessed,
            $1:ETAG::VARCHAR                              AS etag,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/PROJECT_STAT/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_PROJECT_STORAGE_DATA_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO project_storage_data FROM (
        SELECT
            $1:PROJECT_ID::BIGINT                         AS project_id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:MODIFIED_ON::TIMESTAMP_NTZ(9)              AS modified_on,
            $1:RUNTIME_MS::BIGINT                         AS runtime_ms,
            $1:STORAGE_LOCATION_DATA::VARCHAR             AS storage_location_data,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/PROJECT_STORAGE_DATA/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_PROJECT_STORAGE_LIMIT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO project_storage_limit FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:MODIFIED_BY::BIGINT                        AS modified_by,
            $1:MODIFIED_ON::TIMESTAMP_NTZ(9)              AS modified_on,
            $1:PROJECT_ID::BIGINT                         AS project_id,
            $1:STORAGE_LOCATION_ID::BIGINT                AS storage_location_id,
            $1:MAX_BYTES::BIGINT                          AS max_bytes,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/PROJECT_STORAGE_LIMIT/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_QUARANTINED_EMAILS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO quarantined_emails FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:EMAIL::VARCHAR                             AS email,
            $1:ETAG::VARCHAR                              AS etag,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:UPDATED_ON::TIMESTAMP_NTZ(9)               AS updated_on,
            $1:EXPIRES_ON::TIMESTAMP_NTZ(9)               AS expires_on,
            $1:REASON::VARCHAR                            AS reason,
            $1:REASON_DETAILS::VARCHAR                    AS reason_details,
            $1:SES_MESSAGE_ID::VARCHAR                    AS ses_message_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/QUARANTINED_EMAILS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_QUIZ_RESPONSE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO quiz_response FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::BIGINT                         AS created_on,
            $1:REVOKED_ON::BIGINT                         AS revoked_on,
            $1:QUIZ_ID::BIGINT                            AS quiz_id,
            $1:SCORE::BIGINT                              AS score,
            ($1:PASSED::VARCHAR != CHR(0))                AS passed,
            $1:RESPONSE_JSON::VARCHAR                     AS response_json,
            $1:PASSING_JSON::VARCHAR                      AS passing_json,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/QUIZ_RESPONSE/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_RECORDSET_VALIDATION_STATS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO recordset_validation_stats FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:RECORDSET_ID::BIGINT                       AS recordset_id,
            $1:RECORDSET_VERSION::BIGINT                  AS recordset_version,
            $1:STATS_JSON::VARCHAR                        AS stats_json,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/RECORDSET_VALIDATION_STATS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_RESEARCH_PROJECT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO research_project FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ACCESS_REQUIREMENT_ID::BIGINT              AS access_requirement_id,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::BIGINT                         AS created_on,
            $1:MODIFIED_BY::BIGINT                        AS modified_by,
            $1:MODIFIED_ON::BIGINT                        AS modified_on,
            $1:ETAG::VARCHAR                              AS etag,
            $1:PROJECT_LEAD::VARCHAR                      AS project_lead,
            $1:INSTITUTION::VARCHAR                       AS institution,
            $1:IDU::BINARY                                AS idu,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/RESEARCH_PROJECT/
    )
    -- The parquet files for this data type will contain one or more binary columns
    -- that cannot be UTF-8 decoded, so BINARY_AS_TEXT must be set to FALSE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_SEARCH_CONFIGURATION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO search_configuration FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:ORGANIZATION_NAME::VARCHAR                 AS organization_name,
            $1:NAME::VARCHAR                              AS name,
            $1:DESCRIPTION::VARCHAR                       AS description,
            $1:DEFAULT_ANALYZER::VARCHAR                  AS default_analyzer,
            $1:COLUMN_ANALYZER_OVERRIDES::VARCHAR         AS column_analyzer_overrides,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:MODIFIED_BY::BIGINT                        AS modified_by,
            $1:MODIFIED_ON::TIMESTAMP_NTZ(9)              AS modified_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/SEARCH_CONFIGURATION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_SEARCH_CONFIG_OBJECT_BINDING_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO search_config_object_binding FROM (
        SELECT
            $1:BIND_ID::BIGINT                            AS bind_id,
            $1:SEARCH_CONFIG_ID::BIGINT                   AS search_config_id,
            $1:OBJECT_ID::BIGINT                          AS object_id,
            $1:OBJECT_TYPE::VARCHAR                       AS object_type,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/SEARCH_CONFIG_OBJECT_BINDING/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_SENT_MESSAGES_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO sent_messages FROM (
        SELECT
            $1:CHANGE_NUM::BIGINT                         AS change_num,
            $1:TIME_STAMP::TIMESTAMP_NTZ(9)               AS time_stamp,
            $1:OBJECT_ID::BIGINT                          AS object_id,
            $1:OBJECT_VERSION::BIGINT                     AS object_version,
            $1:OBJECT_TYPE::VARCHAR                       AS object_type,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/SENT_MESSAGES/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_SES_NOTIFICATIONS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO ses_notifications FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:INSTANCE_NUMBER::BIGINT                    AS instance_number,
            $1:SES_MESSAGE_ID::VARCHAR                    AS ses_message_id,
            $1:SES_FEEDBACK_ID::VARCHAR                   AS ses_feedback_id,
            $1:NOTIFICATION_TYPE::VARCHAR                 AS notification_type,
            $1:NOTIFICATION_SUBTYPE::VARCHAR              AS notification_subtype,
            $1:NOTIFICATION_REASON::VARCHAR               AS notification_reason,
            $1:NOTIFICATION_BODY::VARCHAR                 AS notification_body,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/SES_NOTIFICATIONS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_STACK_STATUS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO stack_status FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:CURRENT_MESSAGE::VARCHAR                   AS current_message,
            $1:PENDING_MESSAGE::VARCHAR                   AS pending_message,
            $1:STATUS::VARCHAR                            AS status,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/STACK_STATUS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_STATISTICS_MONTHLY_PROJECT_FILES_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO statistics_monthly_project_files FROM (
        SELECT
            $1:PROJECT_ID::BIGINT                         AS project_id,
            $1:MONTH::VARCHAR                             AS month,
            $1:EVENT_TYPE::VARCHAR                        AS event_type,
            $1:LAST_UPDATED_ON::BIGINT                    AS last_updated_on,
            $1:FILES_COUNT::BIGINT                        AS files_count,
            $1:USERS_COUNT::BIGINT                        AS users_count,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/STATISTICS_MONTHLY_PROJECT_FILES/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_STATISTICS_MONTHLY_STATUS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO statistics_monthly_status FROM (
        SELECT
            $1:OBJECT_TYPE::VARCHAR                       AS object_type,
            $1:MONTH::VARCHAR                             AS month,
            $1:STATUS::VARCHAR                            AS status,
            $1:LAST_STARTED_ON::BIGINT                    AS last_started_on,
            $1:LAST_UPDATED_ON::BIGINT                    AS last_updated_on,
            $1:ERROR_MESSAGE::VARCHAR                     AS error_message,
            $1:ERROR_DETAILS::BINARY                      AS error_details,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/STATISTICS_MONTHLY_STATUS/
    )
    -- The parquet files for this data type will contain one or more binary columns
    -- that cannot be UTF-8 decoded, so BINARY_AS_TEXT must be set to FALSE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_STORAGE_LOCATION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO storage_location FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:DESCRIPTION::VARCHAR                       AS description,
            $1:UPLOAD_TYPE::VARCHAR                       AS upload_type,
            $1:ETAG::VARCHAR                              AS etag,
            $1:JSON::VARCHAR                              AS json,
            $1:DATA_HASH::VARCHAR                         AS data_hash,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/STORAGE_LOCATION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_SUBMISSION_CONTRIBUTOR_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO submission_contributor FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:SUBMISSION_ID::BIGINT                      AS submission_id,
            $1:PRINCIPAL_ID::BIGINT                       AS principal_id,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/SUBMISSION_CONTRIBUTOR/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_SUBSCRIPTION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO subscription FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:SUBSCRIBER_ID::BIGINT                      AS subscriber_id,
            $1:OBJECT_ID::BIGINT                          AS object_id,
            $1:OBJECT_TYPE::VARCHAR                       AS object_type,
            $1:CREATED_ON::BIGINT                         AS created_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/SUBSCRIPTION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_SUBSTATUS_ANNOTATIONS_BLOB_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO substatus_annotations_blob FROM (
        SELECT
            $1:SUBMISSION_ID::BIGINT                      AS submission_id,
            $1:VERSION::BIGINT                            AS version,
            $1:ANNOTATIONS_BLOB::BINARY                   AS annotations_blob,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/SUBSTATUS_ANNOTATIONS_BLOB/
    )
    -- The parquet files for this data type will contain one or more binary columns
    -- that cannot be UTF-8 decoded, so BINARY_AS_TEXT must be set to FALSE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_SUBSTATUS_ANNOTATIONS_OWNER_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO substatus_annotations_owner FROM (
        SELECT
            $1:SUBMISSION_ID::BIGINT                      AS submission_id,
            $1:EVALUATION_ID::BIGINT                      AS evaluation_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/SUBSTATUS_ANNOTATIONS_OWNER/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_SUBSTATUS_DOUBLEANNOTATION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO substatus_doubleannotation FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ATTRIBUTE::VARCHAR                         AS attribute,
            $1:SUBMISSION_ID::BIGINT                      AS submission_id,
            $1:VALUE::FLOAT                               AS value,
            ($1:IS_PRIVATE::NUMBER != 0)                  AS is_private,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/SUBSTATUS_DOUBLEANNOTATION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_SUBSTATUS_LONGANNOTATION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO substatus_longannotation FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ATTRIBUTE::VARCHAR                         AS attribute,
            $1:SUBMISSION_ID::BIGINT                      AS submission_id,
            $1:VALUE::BIGINT                              AS value,
            ($1:IS_PRIVATE::NUMBER != 0)                  AS is_private,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/SUBSTATUS_LONGANNOTATION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_SUBSTATUS_STRINGANNOTATION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO substatus_stringannotation FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ATTRIBUTE::VARCHAR                         AS attribute,
            $1:SUBMISSION_ID::BIGINT                      AS submission_id,
            $1:VALUE::VARCHAR                             AS value,
            ($1:IS_PRIVATE::NUMBER != 0)                  AS is_private,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/SUBSTATUS_STRINGANNOTATION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_SYNAPSE_REALM_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO synapse_realm FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:NAME::VARCHAR                              AS name,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/SYNAPSE_REALM/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_SYNAPSE_REALM_IDP_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO synapse_realm_idp FROM (
        SELECT
            $1:REALM_ID::BIGINT                           AS realm_id,
            $1:PROVIDER::VARCHAR                          AS provider,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/SYNAPSE_REALM_IDP/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_SYNAPSE_REALM_PRINCIPAL_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO synapse_realm_principal FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:REALM_ID::BIGINT                           AS realm_id,
            $1:PRINCIPAL_ID::BIGINT                       AS principal_id,
            $1:TYPE::VARCHAR                              AS type,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/SYNAPSE_REALM_PRINCIPAL/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_SYNONYM_SET_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO synonym_set FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:ORGANIZATION_NAME::VARCHAR                 AS organization_name,
            $1:NAME::VARCHAR                              AS name,
            $1:DESCRIPTION::VARCHAR                       AS description,
            $1:DEFINITION::VARCHAR                        AS definition,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:MODIFIED_BY::BIGINT                        AS modified_by,
            $1:MODIFIED_ON::TIMESTAMP_NTZ(9)              AS modified_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/SYNONYM_SET/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_TABLE_ID_SEQUENCE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO table_id_sequence FROM (
        SELECT
            $1:TABLE_ID::BIGINT                           AS table_id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:ROW_VERSION::BIGINT                        AS row_version,
            $1:SEQUENCE::BIGINT                           AS sequence,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/TABLE_ID_SEQUENCE/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_TABLE_ROW_CHANGE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO table_row_change FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:TABLE_ID::BIGINT                           AS table_id,
            $1:ROW_VERSION::BIGINT                        AS row_version,
            $1:ETAG::VARCHAR                              AS etag,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::BIGINT                         AS created_on,
            $1:S3_BUCKET::VARCHAR                         AS s3_bucket,
            $1:S3_KEY::VARCHAR                            AS s3_key,
            $1:ROW_COUNT::BIGINT                          AS row_count,
            $1:CHANGE_TYPE::VARCHAR                       AS change_type,
            $1:TRX_ID::BIGINT                             AS trx_id,
            ($1:HAS_FILE_REFS::NUMBER != 0)               AS has_file_refs,
            ($1:SEARCH_ENABLED::NUMBER != 0)              AS search_enabled,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/TABLE_ROW_CHANGE/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_TABLE_SNAPSHOT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO table_snapshot FROM (
        SELECT
            $1:SNAPSHOT_ID::BIGINT                        AS snapshot_id,
            $1:TABLE_ID::BIGINT                           AS table_id,
            $1:VERSION::BIGINT                            AS version,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:BUCKET_NAME::VARCHAR                       AS bucket_name,
            $1:KEY::VARCHAR                               AS key,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/TABLE_SNAPSHOT/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_TABLE_STATUS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO table_status FROM (
        SELECT
            $1:TABLE_ID::BIGINT                           AS table_id,
            $1:VERSION::BIGINT                            AS version,
            $1:STATE::VARCHAR                             AS state,
            $1:RESET_TOKEN::VARCHAR                       AS reset_token,
            $1:LAST_TABLE_CHANGE_ETAG::VARCHAR            AS last_table_change_etag,
            $1:STARTED_ON::BIGINT                         AS started_on,
            $1:CHANGED_ON::BIGINT                         AS changed_on,
            $1:PROGRESS_MESSAGE::VARCHAR                  AS progress_message,
            $1:PROGRESS_CURRENT::BIGINT                   AS progress_current,
            $1:PROGRESS_TOTAL::BIGINT                     AS progress_total,
            $1:ERROR_MESSAGE::VARCHAR                     AS error_message,
            $1:ERROR_DETAILS::BINARY                      AS error_details,
            $1:RUNTIME_MS::BIGINT                         AS runtime_ms,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/TABLE_STATUS/
    )
    -- The parquet files for this data type will contain one or more binary columns
    -- that cannot be UTF-8 decoded, so BINARY_AS_TEXT must be set to FALSE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_TABLE_TRANSACTION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO table_transaction FROM (
        SELECT
            $1:TRX_ID::BIGINT                             AS trx_id,
            $1:TABLE_ID::BIGINT                           AS table_id,
            $1:STARTED_BY::BIGINT                         AS started_by,
            $1:STARTED_ON::BIGINT                         AS started_on,
            $1:ETAG::VARCHAR                              AS etag,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/TABLE_TRANSACTION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_TABLE_TRX_TO_VERSION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO table_trx_to_version FROM (
        SELECT
            $1:TRX_ID::BIGINT                             AS trx_id,
            $1:VERSION::BIGINT                            AS version,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/TABLE_TRX_TO_VERSION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_TEAM_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO team FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:ICON::BIGINT                               AS icon,
            $1:PROPERTIES::BINARY                         AS properties,
            $1:STATE::VARCHAR                             AS state,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/TEAM/
    )
    -- The parquet files for this data type will contain one or more binary columns
    -- that cannot be UTF-8 decoded, so BINARY_AS_TEXT must be set to FALSE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_TERMS_OF_SERVICE_AGREEMENT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO terms_of_service_agreement FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:VERSION::VARCHAR                           AS version,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/TERMS_OF_SERVICE_AGREEMENT/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_TERMS_OF_SERVICE_LATEST_VERSION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO terms_of_service_latest_version FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:UPDATED_ON::TIMESTAMP_NTZ(9)               AS updated_on,
            $1:VERSION::VARCHAR                           AS version,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/TERMS_OF_SERVICE_LATEST_VERSION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_TERMS_OF_SERVICE_REQUIREMENT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO terms_of_service_requirement FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:MIN_VERSION::VARCHAR                       AS min_version,
            $1:ENFORCED_ON::TIMESTAMP_NTZ(9)              AS enforced_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/TERMS_OF_SERVICE_REQUIREMENT/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_TEXT_ANALYZER_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO text_analyzer FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:NAME::VARCHAR                              AS name,
            $1:DESCRIPTION::VARCHAR                       AS description,
            $1:ORGANIZATION_NAME::VARCHAR                 AS organization_name,
            $1:SETTINGS::VARCHAR                          AS settings,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:MODIFIED_BY::BIGINT                        AS modified_by,
            $1:MODIFIED_ON::TIMESTAMP_NTZ(9)              AS modified_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/TEXT_ANALYZER/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_THROTTLE_RULES_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO throttle_rules FROM (
        SELECT
            $1:THROTTLE_ID::BIGINT                        AS throttle_id,
            $1:NORMALIZED_PATH::VARCHAR                   AS normalized_path,
            $1:MAX_CALLS_PER_USER_PER_PERIOD::BIGINT      AS max_calls_per_user_per_period,
            $1:PERIOD_IN_SECONDS::BIGINT                  AS period_in_seconds,
            $1:MODIFIED_ON::TIMESTAMP_NTZ(9)              AS modified_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/THROTTLE_RULES/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_TRASH_CAN_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO trash_can FROM (
        SELECT
            $1:NODE_ID::BIGINT                            AS node_id,
            $1:NODE_NAME::VARCHAR                         AS node_name,
            $1:DELETED_BY::BIGINT                         AS deleted_by,
            $1:DELETED_ON::TIMESTAMP_NTZ(9)               AS deleted_on,
            $1:PARENT_ID::BIGINT                          AS parent_id,
            $1:ETAG::VARCHAR                              AS etag,
            ($1:PRIORITY_PURGE::NUMBER != 0)              AS priority_purge,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/TRASH_CAN/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_UNSUCCESSFUL_LOGIN_LOCKOUT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO unsuccessful_login_lockout FROM (
        SELECT
            $1:USER_ID::BIGINT                            AS user_id,
            $1:UNSUCCESSFUL_LOGIN_COUNT::BIGINT           AS unsuccessful_login_count,
            $1:LOCKOUT_EXPIRATION::BIGINT                 AS lockout_expiration,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/UNSUCCESSFUL_LOGIN_LOCKOUT/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_USER_GROUP_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO user_group FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:CREATION_DATE::TIMESTAMP_NTZ(9)            AS creation_date,
            ($1:ISINDIVIDUAL::VARCHAR != CHR(0))          AS isindividual,
            $1:ETAG::VARCHAR                              AS etag,
            $1:REALM::BIGINT                              AS realm,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/USER_GROUP/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_USER_PROFILE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO user_profile FROM (
        SELECT
            $1:OWNER_ID::BIGINT                           AS owner_id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:PROPERTIES::BINARY                         AS properties,
            $1:PICTURE_ID::BIGINT                         AS picture_id,
            ($1:SEND_EMAIL_NOTIFICATION::NUMBER != 0)     AS send_email_notification,
            $1:FIRST_NAME::BINARY                         AS first_name,
            $1:LAST_NAME::BINARY                          AS last_name,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/USER_PROFILE/
    )
    -- The parquet files for this data type will contain one or more binary columns
    -- that cannot be UTF-8 decoded, so BINARY_AS_TEXT must be set to FALSE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_USER_STATUS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO user_status FROM (
        SELECT
            $1:PRINCIPAL_ID::BIGINT                       AS principal_id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:LAST_SEEN_ON::TIMESTAMP_NTZ(9)             AS last_seen_on,
            ($1:DISABLED::NUMBER != 0)                    AS disabled,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/USER_STATUS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_USER_TWO_FA_STATUS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO user_two_fa_status FROM (
        SELECT
            $1:PRINCIPAL_ID::BIGINT                       AS principal_id,
            ($1:ENABLED::NUMBER != 0)                     AS enabled,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/USER_TWO_FA_STATUS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_V2_WIKI_ATTACHMENT_RESERVATION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO v2_wiki_attachment_reservation FROM (
        SELECT
            $1:WIKI_ID::BIGINT                            AS wiki_id,
            $1:FILE_HANDLE_ID::BIGINT                     AS file_handle_id,
            $1:TIME_STAMP::TIMESTAMP_NTZ(9)               AS time_stamp,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/V2_WIKI_ATTACHMENT_RESERVATION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_V2_WIKI_MARKDOWN_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO v2_wiki_markdown FROM (
        SELECT
            $1:WIKI_ID::BIGINT                            AS wiki_id,
            $1:FILE_HANDLE_ID::BIGINT                     AS file_handle_id,
            $1:MARKDOWN_VERSION::BIGINT                   AS markdown_version,
            $1:MODIFIED_ON::BIGINT                        AS modified_on,
            $1:MODIFIED_BY::BIGINT                        AS modified_by,
            $1:TITLE::VARCHAR                             AS title,
            $1:ATTACHMENT_ID_LIST::BINARY                 AS attachment_id_list,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/V2_WIKI_MARKDOWN/
    )
    -- The parquet files for this data type will contain one or more binary columns
    -- that cannot be UTF-8 decoded, so BINARY_AS_TEXT must be set to FALSE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_V2_WIKI_OWNERS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO v2_wiki_owners FROM (
        SELECT
            $1:OWNER_ID::BIGINT                           AS owner_id,
            $1:OWNER_OBJECT_TYPE::VARCHAR                 AS owner_object_type,
            $1:ROOT_WIKI_ID::BIGINT                       AS root_wiki_id,
            $1:ORDER_HINT::BINARY                         AS order_hint,
            $1:ETAG::VARCHAR                              AS etag,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/V2_WIKI_OWNERS/
    )
    -- The parquet files for this data type will contain one or more binary columns
    -- that cannot be UTF-8 decoded, so BINARY_AS_TEXT must be set to FALSE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_V2_WIKI_PAGE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO v2_wiki_page FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:TITLE::VARCHAR                             AS title,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::BIGINT                         AS created_on,
            $1:MODIFIED_BY::BIGINT                        AS modified_by,
            $1:MODIFIED_ON::BIGINT                        AS modified_on,
            $1:PARENT_ID::BIGINT                          AS parent_id,
            $1:ROOT_ID::BIGINT                            AS root_id,
            $1:MARKDOWN_VERSION::BIGINT                   AS markdown_version,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/V2_WIKI_PAGE/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_VALIDATION_JSON_SCHEMA_INDEX_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO validation_json_schema_index FROM (
        SELECT
            $1:VERSION_ID::BIGINT                         AS version_id,
            $1:VALIDATION_SCHEMA::VARCHAR                 AS validation_schema,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/VALIDATION_JSON_SCHEMA_INDEX/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_VERIFICATION_FILE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO verification_file FROM (
        SELECT
            $1:VERIFICATION_ID::BIGINT                    AS verification_id,
            $1:FILE_HANDLE_ID::BIGINT                     AS file_handle_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/VERIFICATION_FILE/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_VERIFICATION_STATE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO verification_state FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:VERIFICATION_ID::BIGINT                    AS verification_id,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::BIGINT                         AS created_on,
            $1:STATE::VARCHAR                             AS state,
            $1:REASON::BINARY                             AS reason,
            $1:NOTES::BINARY                              AS notes,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/VERIFICATION_STATE/
    )
    -- The parquet files for this data type will contain one or more binary columns
    -- that cannot be UTF-8 decoded, so BINARY_AS_TEXT must be set to FALSE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_VERIFICATION_SUBMISSION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO verification_submission FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::BIGINT                         AS created_on,
            $1:SERIALIZED::BINARY                         AS serialized,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/VERIFICATION_SUBMISSION/
    )
    -- The parquet files for this data type will contain one or more binary columns
    -- that cannot be UTF-8 decoded, so BINARY_AS_TEXT must be set to FALSE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_VIEW_SCOPE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO view_scope FROM (
        SELECT
            $1:VIEW_ID::BIGINT                            AS view_id,
            $1:CONTAINER_ID::BIGINT                       AS container_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/VIEW_SCOPE/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_VIEW_TYPE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO view_type FROM (
        SELECT
            $1:VIEW_ID::BIGINT                            AS view_id,
            $1:VIEW_OBJECT_TYPE::VARCHAR                  AS view_object_type,
            $1:VIEW_TYPE_MASK::BIGINT                     AS view_type_mask,
            $1:ETAG::VARCHAR                              AS etag,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/VIEW_TYPE/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_WEBHOOK_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO webhook FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:MODIFIED_ON::TIMESTAMP_NTZ(9)              AS modified_on,
            $1:OBJECT_ID::BIGINT                          AS object_id,
            $1:OBJECT_TYPE::VARCHAR                       AS object_type,
            $1:EVENT_TYPES::VARCHAR                       AS event_types,
            $1:INVOKE_ENDPOINT::VARCHAR                   AS invoke_endpoint,
            ($1:IS_ENABLED::NUMBER != 0)                  AS is_enabled,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/WEBHOOK/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_WEBHOOK_ALLOWED_DOMAIN_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO webhook_allowed_domain FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:PATTERN::VARCHAR                           AS pattern,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/WEBHOOK_ALLOWED_DOMAIN/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_WEBHOOK_VERIFICATION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_B
AS
    COPY INTO webhook_verification FROM (
        SELECT
            $1:WEBHOOK_ID::BIGINT                         AS webhook_id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:MODIFIED_ON::TIMESTAMP_NTZ(9)              AS modified_on,
            $1:CODE::VARCHAR                              AS code,
            $1:CODE_EXPIRES_ON::TIMESTAMP_NTZ(9)          AS code_expires_on,
            $1:CODE_MESSAGE_ID::VARCHAR                   AS code_message_id,
            $1:STATUS::VARCHAR                            AS status,
            $1:MESSAGE::VARCHAR                           AS message,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/WEBHOOK_VERIFICATION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('REFRESH_RDS_SNAPSHOTS_STAGE_TASK');
