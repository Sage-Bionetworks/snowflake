-- Creates the maximum number of child tasks we are allowed
-- under proxy task A (100 - 14 existing tasks). Each task loads
-- a separate data type from `RDS_SNAPSHOTS_STAGE`
USE SCHEMA {{database_name}}.RDS_LANDING; --noqa: JJ01,PRS,TMP

-- Some tables' parquet files contain one or more binary columns that cannot be UTF-8
-- decoded, so those tasks override FILE_FORMAT with BINARY_AS_TEXT = FALSE
CREATE OR REPLACE TASK COPY_ACTIVITY_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO activity FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::BIGINT                         AS created_on,
            $1:MODIFIED_BY::BIGINT                        AS modified_by,
            $1:MODIFIED_ON::BIGINT                        AS modified_on,
            $1:SERIALIZED_OBJECT::BINARY                  AS serialized_object,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/ACTIVITY/
    )
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_AGENT_REGISTRATION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO agent_registration FROM (
        SELECT
            $1:REGISTRATION_ID::BIGINT                    AS registration_id,
            $1:AWS_AGENT_ID::VARCHAR                      AS aws_agent_id,
            $1:AWS_ALIAS_ID::VARCHAR                      AS aws_alias_id,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:AGENT_TYPE::VARCHAR                        AS agent_type,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/AGENT_REGISTRATION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_AGENT_SESSION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO agent_session FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:MODIFIED_ON::TIMESTAMP_NTZ(9)              AS modified_on,
            $1:SESSION_ID::VARCHAR                        AS session_id,
            $1:REGISTRATION_ID::BIGINT                    AS registration_id,
            $1:ACCESS_LEVEL::VARCHAR                      AS access_level,
            $1:CONTEXT::VARCHAR                           AS context,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/AGENT_SESSION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_AGENT_TRACE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO agent_trace FROM (
        SELECT
            $1:JOB_ID::BIGINT                             AS job_id,
            $1:TIME_STAMP::BIGINT                         AS time_stamp,
            $1:MESSAGE::VARCHAR                           AS message,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/AGENT_TRACE/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_ASYNCH_JOB_STATUS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO asynch_job_status FROM (
        SELECT
            $1:JOB_ID::BIGINT                             AS job_id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:JOB_STATE::VARCHAR                         AS job_state,
            $1:JOB_TYPE::VARCHAR                          AS job_type,
            ($1:CANCELING::VARCHAR != CHR(0))             AS canceling,
            $1:EXCEPTION::VARCHAR                         AS exception,
            $1:ERROR_MESSAGE::VARCHAR                     AS error_message,
            $1:ERROR_DETAILS::VARCHAR                     AS error_details,
            $1:PROGRESS_CURRENT::BIGINT                   AS progress_current,
            $1:PROGRESS_TOTAL::BIGINT                     AS progress_total,
            $1:PROGRESS_MESSAGE::VARCHAR                  AS progress_message,
            $1:STARTED_ON::TIMESTAMP_NTZ(9)               AS started_on,
            $1:STARTED_BY::BIGINT                         AS started_by,
            $1:CHANGED_ON::TIMESTAMP_NTZ(9)               AS changed_on,
            $1:REQUEST_BODY::VARCHAR                      AS request_body,
            $1:RESPONSE_BODY::VARCHAR                     AS response_body,
            $1:RUNTIME_MS::BIGINT                         AS runtime_ms,
            $1:REQUEST_HASH::VARCHAR                      AS request_hash,
            $1:CONTEXT::VARCHAR                           AS context,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/ASYNCH_JOB_STATUS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_AUTHENTICATED_ON_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO authenticated_on FROM (
        SELECT
            $1:PRINCIPAL_ID::BIGINT                       AS principal_id,
            $1:AUTHENTICATED_ON::TIMESTAMP_NTZ(9)         AS authenticated_on,
            $1:ETAG::VARCHAR                              AS etag,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/AUTHENTICATED_ON/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_AUTHORIZATION_CONSENT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO authorization_consent FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:USER_ID::BIGINT                            AS user_id,
            $1:CLIENT_ID::BIGINT                          AS client_id,
            $1:SCOPE_HASH::VARCHAR                        AS scope_hash,
            $1:GRANTED_ON::BIGINT                         AS granted_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/AUTHORIZATION_CONSENT/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_BOUND_COLUMN_ORDINAL_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO bound_column_ordinal FROM (
        SELECT
            $1:COLUMN_ID::BIGINT                          AS column_id,
            $1:OBJECT_ID::BIGINT                          AS object_id,
            $1:OBJECT_VERSION::BIGINT                     AS object_version,
            $1:ORDINAL::BIGINT                            AS ordinal,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/BOUND_COLUMN_ORDINAL/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_BOUND_COLUMN_OWNER_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO bound_column_owner FROM (
        SELECT
            $1:OBJECT_ID::BIGINT                          AS object_id,
            $1:ETAG::VARCHAR                              AS etag,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/BOUND_COLUMN_OWNER/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_CERTIFIED_USERS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO certified_users FROM (
        SELECT
            $1:USER_ID::BIGINT                            AS user_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/CERTIFIED_USERS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_CHALLENGE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO challenge FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:TEAM_ID::BIGINT                            AS team_id,
            $1:PROJECT_ID::BIGINT                         AS project_id,
            $1:SERIALIZED_ENTITY::BINARY                  AS serialized_entity,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/CHALLENGE/
    )
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_CHALLENGE_TEAM_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO challenge_team FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:TEAM_ID::BIGINT                            AS team_id,
            $1:CHALLENGE_ID::BIGINT                       AS challenge_id,
            $1:SERIALIZED_ENTITY::BINARY                  AS serialized_entity,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/CHALLENGE_TEAM/
    )
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_CHANGES_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO changes FROM (
        SELECT
            $1:CHANGE_NUM::BIGINT                         AS change_num,
            $1:TIME_STAMP::TIMESTAMP_NTZ(9)               AS time_stamp,
            $1:OBJECT_ID::BIGINT                          AS object_id,
            $1:OBJECT_VERSION::BIGINT                     AS object_version,
            $1:USER_ID::BIGINT                            AS user_id,
            $1:OBJECT_TYPE::VARCHAR                       AS object_type,
            $1:CHANGE_TYPE::VARCHAR                       AS change_type,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/CHANGES/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_COLUMN_ANALYZER_OVERRIDE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO column_analyzer_override FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:ORGANIZATION_NAME::VARCHAR                 AS organization_name,
            $1:NAME::VARCHAR                              AS name,
            $1:DESCRIPTION::VARCHAR                       AS description,
            $1:OVERRIDES::VARCHAR                         AS overrides,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:MODIFIED_BY::BIGINT                        AS modified_by,
            $1:MODIFIED_ON::TIMESTAMP_NTZ(9)              AS modified_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/COLUMN_ANALYZER_OVERRIDE/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_COLUMN_MODEL_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO column_model FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:NAME::VARCHAR                              AS name,
            $1:HASH::VARCHAR                              AS hash,
            $1:JSON::VARCHAR                              AS json,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/COLUMN_MODEL/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_COMMENT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO comment FROM (
        SELECT
            $1:MESSAGE_ID::BIGINT                         AS message_id,
            $1:OBJECT_TYPE::VARCHAR                       AS object_type,
            $1:OBJECT_ID::BIGINT                          AS object_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/COMMENT/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_CREDENTIAL_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO credential FROM (
        SELECT
            $1:PRINCIPAL_ID::BIGINT                       AS principal_id,
            $1:PASS_HASH::VARCHAR                         AS pass_hash,
            $1:MODIFIED_ON::TIMESTAMP_NTZ(9)              AS modified_on,
            $1:EXPIRES_ON::TIMESTAMP_NTZ(9)               AS expires_on,
            $1:ETAG::VARCHAR                              AS etag,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/CREDENTIAL/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_CURATION_TASK_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO curation_task FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:DATA_TYPE::VARCHAR                         AS data_type,
            $1:PROJECT_ID::BIGINT                         AS project_id,
            $1:INSTRUCTIONS::VARCHAR                      AS instructions,
            $1:ETAG::VARCHAR                              AS etag,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:MODIFIED_BY::BIGINT                        AS modified_by,
            $1:MODIFIED_ON::TIMESTAMP_NTZ(9)              AS modified_on,
            $1:TASK_PROPERTIES::VARCHAR                   AS task_properties,
            $1:ASSIGNEE::BIGINT                           AS assignee,
            $1:STATE::VARCHAR                             AS state,
            $1:EXECUTION_DETAILS::VARCHAR                 AS execution_details,
            $1:STATE_UPDATED_BY::BIGINT                   AS state_updated_by,
            $1:STATE_UPDATED_ON::TIMESTAMP_NTZ(9)         AS state_updated_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/CURATION_TASK/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_DATA_TYPE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO data_type FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:OBJECT_ID::BIGINT                          AS object_id,
            $1:OBJECT_TYPE::VARCHAR                       AS object_type,
            $1:DATA_TYPE::VARCHAR                         AS data_type,
            $1:UPDATED_BY::BIGINT                         AS updated_by,
            $1:UPDATED_ON::BIGINT                         AS updated_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DATA_TYPE/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_DERIVED_ANNOTATIONS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO derived_annotations FROM (
        SELECT
            $1:OBJECT_ID::BIGINT                          AS object_id,
            $1:ANNO_KEYS::VARCHAR                         AS anno_keys,
            $1:ANNOTATIONS::VARCHAR                       AS annotations,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DERIVED_ANNOTATIONS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_DISCUSSION_REPLY_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO discussion_reply FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:THREAD_ID::BIGINT                          AS thread_id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:MODIFIED_ON::TIMESTAMP_NTZ(9)              AS modified_on,
            $1:MESSAGE_KEY::VARCHAR                       AS message_key,
            ($1:IS_EDITED::NUMBER != 0)                   AS is_edited,
            ($1:IS_DELETED::NUMBER != 0)                  AS is_deleted,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DISCUSSION_REPLY/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_DISCUSSION_SEARCH_INDEX_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO discussion_search_index FROM (
        SELECT
            $1:FORUM_ID::BIGINT                           AS forum_id,
            $1:THREAD_ID::BIGINT                          AS thread_id,
            ($1:THREAD_DELETED::NUMBER != 0)              AS thread_deleted,
            $1:REPLY_ID::BIGINT                           AS reply_id,
            ($1:REPLY_DELETED::NUMBER != 0)               AS reply_deleted,
            $1:SEARCH_CONTENT::VARCHAR                    AS search_content,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DISCUSSION_SEARCH_INDEX/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_DISCUSSION_THREAD_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO discussion_thread FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:FORUM_ID::BIGINT                           AS forum_id,
            $1:TITLE::BINARY                              AS title,
            $1:ETAG::VARCHAR                              AS etag,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:MODIFIED_ON::TIMESTAMP_NTZ(9)              AS modified_on,
            $1:MESSAGE_KEY::VARCHAR                       AS message_key,
            ($1:IS_EDITED::NUMBER != 0)                   AS is_edited,
            ($1:IS_DELETED::NUMBER != 0)                  AS is_deleted,
            ($1:IS_PINNED::NUMBER != 0)                   AS is_pinned,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DISCUSSION_THREAD/
    )
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_DISCUSSION_THREAD_ENTITY_REFERENCE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO discussion_thread_entity_reference FROM (
        SELECT
            $1:THREAD_ID::BIGINT                          AS thread_id,
            $1:ENTITY_ID::BIGINT                          AS entity_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DISCUSSION_THREAD_ENTITY_REFERENCE/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_DISCUSSION_THREAD_STATS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO discussion_thread_stats FROM (
        SELECT
            $1:THREAD_ID::BIGINT                          AS thread_id,
            $1:NUMBER_OF_VIEWS::BIGINT                    AS number_of_views,
            $1:NUMBER_OF_REPLIES::BIGINT                  AS number_of_replies,
            $1:LAST_ACTIVITY::TIMESTAMP_NTZ(9)            AS last_activity,
            $1:ACTIVE_AUTHORS::VARCHAR                    AS active_authors,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DISCUSSION_THREAD_STATS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_DISCUSSION_THREAD_SUBMISSION_REFERENCE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO discussion_thread_submission_reference FROM (
        SELECT
            $1:THREAD_ID::BIGINT                          AS thread_id,
            $1:SUBMISSION_ID::BIGINT                      AS submission_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DISCUSSION_THREAD_SUBMISSION_REFERENCE/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_DISCUSSION_THREAD_VIEW_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO discussion_thread_view FROM (
        SELECT
            $1:THREAD_ID::BIGINT                          AS thread_id,
            $1:USER_ID::BIGINT                            AS user_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DISCUSSION_THREAD_VIEW/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_DOCKER_COMMIT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO docker_commit FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:OWNER_ID::BIGINT                           AS owner_id,
            $1:TAG::VARCHAR                               AS tag,
            $1:DIGEST::VARCHAR                            AS digest,
            $1:CREATED_ON::BIGINT                         AS created_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DOCKER_COMMIT/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_DOCKER_REPOSITORY_NAME_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO docker_repository_name FROM (
        SELECT
            $1:OWNER_ID::BIGINT                           AS owner_id,
            $1:REPOSITORY_NAME::VARCHAR                   AS repository_name,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DOCKER_REPOSITORY_NAME/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_DOI_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO doi FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:DOI_STATUS::VARCHAR                        AS doi_status,
            $1:PORTAL_ID::BIGINT                          AS portal_id,
            $1:OBJECT_ID::VARCHAR                         AS object_id,
            $1:OBJECT_TYPE::VARCHAR                       AS object_type,
            $1:OBJECT_VERSION::BIGINT                     AS object_version,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:UPDATED_BY::BIGINT                         AS updated_by,
            $1:UPDATED_ON::TIMESTAMP_NTZ(9)               AS updated_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DOI/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_DOWNLOAD_LIST_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO download_list FROM (
        SELECT
            $1:PRINCIPAL_ID::BIGINT                       AS principal_id,
            $1:UPDATED_ON::BIGINT                         AS updated_on,
            $1:ETAG::VARCHAR                              AS etag,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DOWNLOAD_LIST/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_DOWNLOAD_LIST_ITEM_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO download_list_item FROM (
        SELECT
            $1:PRINCIPAL_ID::BIGINT                       AS principal_id,
            $1:ASSOCIATED_OBJECT_ID::BIGINT               AS associated_object_id,
            $1:ASSOCIATED_OBJECT_TYPE::VARCHAR            AS associated_object_type,
            $1:FILE_HANDLE_ID::BIGINT                     AS file_handle_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DOWNLOAD_LIST_ITEM/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_DOWNLOAD_LIST_ITEM_V2_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO download_list_item_v2 FROM (
        SELECT
            $1:PRINCIPAL_ID::BIGINT                       AS principal_id,
            $1:ENTITY_ID::BIGINT                          AS entity_id,
            $1:VERSION_NUMBER::BIGINT                     AS version_number,
            $1:ADDED_ON::TIMESTAMP_NTZ(9)                 AS added_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DOWNLOAD_LIST_ITEM_V2/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_DOWNLOAD_LIST_V2_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO download_list_v2 FROM (
        SELECT
            $1:PRINCIPAL_ID::BIGINT                       AS principal_id,
            $1:UPDATED_ON::TIMESTAMP_NTZ(9)               AS updated_on,
            $1:ETAG::VARCHAR                              AS etag,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DOWNLOAD_LIST_V2/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_DOWNLOAD_ORDER_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO download_order FROM (
        SELECT
            $1:ORDER_ID::BIGINT                           AS order_id,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::BIGINT                         AS created_on,
            $1:FILE_NAME::VARCHAR                         AS file_name,
            $1:TOTAL_SIZE_BYTES::BIGINT                   AS total_size_bytes,
            $1:TOTAL_NUM_FILES::BIGINT                    AS total_num_files,
            $1:FILES_BLOB::BINARY                         AS files_blob,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DOWNLOAD_ORDER/
    )
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_EVALUATION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO evaluation FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:NAME::VARCHAR                              AS name,
            $1:DESCRIPTION::BINARY                        AS description,
            $1:OWNER_ID::BIGINT                           AS owner_id,
            $1:CREATED_ON::BIGINT                         AS created_on,
            $1:CONTENT_SOURCE::BIGINT                     AS content_source,
            $1:STATUS::BIGINT                             AS status,
            $1:SUBMISSION_INSTRUCTIONS_MESSAGE::BINARY    AS submission_instructions_message,
            $1:SUBMISSION_RECEIPT_MESSAGE::BINARY         AS submission_receipt_message,
            $1:QUOTA_JSON::VARCHAR                        AS quota_json,
            $1:START_TIMESTAMP::BIGINT                    AS start_timestamp,
            $1:END_TIMESTAMP::BIGINT                      AS end_timestamp,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/EVALUATION/
    )
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_EVALUATION_ROUNDS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO evaluation_rounds FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:EVALUATION_ID::BIGINT                      AS evaluation_id,
            $1:ROUND_START::TIMESTAMP_NTZ(9)              AS round_start,
            $1:ROUND_END::TIMESTAMP_NTZ(9)                AS round_end,
            $1:LIMITS::VARCHAR                            AS limits,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/EVALUATION_ROUNDS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_EVALUATION_SUBMISSION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO evaluation_submission FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:NAME::VARCHAR                              AS name,
            $1:EVALUATION_ID::BIGINT                      AS evaluation_id,
            $1:EVALUATION_ROUND_ID::BIGINT                AS evaluation_round_id,
            $1:USER_ID::BIGINT                            AS user_id,
            $1:SUBMITTER_ALIAS::VARCHAR                   AS submitter_alias,
            $1:ENTITY_ID::BIGINT                          AS entity_id,
            $1:ENTITY_BUNDLE::BINARY                      AS entity_bundle,
            $1:ENTITY_VERSION::BIGINT                     AS entity_version,
            $1:CREATED_ON::BIGINT                         AS created_on,
            $1:TEAM_ID::BIGINT                            AS team_id,
            $1:DOCKER_REPO_NAME::VARCHAR                  AS docker_repo_name,
            $1:DOCKER_DIGEST::VARCHAR                     AS docker_digest,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/EVALUATION_SUBMISSION/
    )
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_EVALUATION_SUBMISSIONS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO evaluation_submissions FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:EVAL_ID::BIGINT                            AS eval_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/EVALUATION_SUBMISSIONS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_EVALUATION_SUBMISSION_FILE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO evaluation_submission_file FROM (
        SELECT
            $1:SUBMISSION_ID::BIGINT                      AS submission_id,
            $1:FILE_HANDLE_ID::BIGINT                     AS file_handle_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/EVALUATION_SUBMISSION_FILE/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_EVALUATION_SUBMISSION_STATUS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO evaluation_submission_status FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:SUBSTATUS_VERSION::BIGINT                  AS substatus_version,
            $1:MODIFIED_ON::BIGINT                        AS modified_on,
            $1:STATUS::BIGINT                             AS status,
            $1:ANNOTATIONS::VARCHAR                       AS annotations,
            $1:SCORE::FLOAT                               AS score,
            $1:ENTITY_JSON::VARCHAR                       AS entity_json,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/EVALUATION_SUBMISSION_STATUS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_FAVORITE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO favorite FROM (
        SELECT
            $1:FAVORITE_ID::BIGINT                        AS favorite_id,
            $1:PRINCIPAL_ID::BIGINT                       AS principal_id,
            $1:NODE_ID::BIGINT                            AS node_id,
            $1:CREATED_ON::BIGINT                         AS created_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/FAVORITE/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_FEATURE_STATUS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO feature_status FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:FEATURE_TYPE::VARCHAR                      AS feature_type,
            ($1:ENABLED::NUMBER != 0)                     AS enabled,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/FEATURE_STATUS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_FILES_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO files FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:PREVIEW_ID::BIGINT                         AS preview_id,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:UPDATED_ON::TIMESTAMP_NTZ(9)               AS updated_on,
            $1:METADATA_TYPE::VARCHAR                     AS metadata_type,
            $1:CONTENT_TYPE::VARCHAR                      AS content_type,
            $1:CONTENT_SIZE::BIGINT                       AS content_size,
            $1:CONTENT_MD5::VARCHAR                       AS content_md5,
            $1:BUCKET_NAME::VARCHAR                       AS bucket_name,
            $1:NAME::VARCHAR                              AS name,
            $1:KEY::VARCHAR                               AS key,
            $1:STORAGE_LOCATION_ID::BIGINT                AS storage_location_id,
            $1:ENDPOINT::VARCHAR                          AS endpoint,
            ($1:IS_PREVIEW::NUMBER != 0)                  AS is_preview,
            $1:STATUS::VARCHAR                            AS status,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/FILES/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_FILES_SCANNER_STATUS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO files_scanner_status FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:STARTED_ON::TIMESTAMP_NTZ(9)               AS started_on,
            $1:UPDATED_ON::TIMESTAMP_NTZ(9)               AS updated_on,
            $1:JOBS_STARTED_COUNT::BIGINT                 AS jobs_started_count,
            $1:JOBS_COMPLETED_COUNT::BIGINT               AS jobs_completed_count,
            $1:SCANNED_ASSOCIATIONS_COUNT::BIGINT         AS scanned_associations_count,
            $1:RELINKED_FILES_COUNT::BIGINT               AS relinked_files_count,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/FILES_SCANNER_STATUS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_FORM_DATA_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO form_data FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:NAME::VARCHAR                              AS name,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:MODIFIED_ON::TIMESTAMP_NTZ(9)              AS modified_on,
            $1:GROUP_ID::BIGINT                           AS group_id,
            $1:FILE_HANDLE_ID::BIGINT                     AS file_handle_id,
            $1:SUBMITTED_ON::TIMESTAMP_NTZ(9)             AS submitted_on,
            $1:REVIEWED_ON::TIMESTAMP_NTZ(9)              AS reviewed_on,
            $1:REVIEWED_BY::BIGINT                        AS reviewed_by,
            $1:STATE::VARCHAR                             AS state,
            $1:REJECTION_MESSAGE::VARCHAR                 AS rejection_message,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/FORM_DATA/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_FORM_GROUP_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO form_group FROM (
        SELECT
            $1:GROUP_ID::BIGINT                           AS group_id,
            $1:NAME::VARCHAR                              AS name,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/FORM_GROUP/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_FORUM_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO forum FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:OBJECT_ID::BIGINT                          AS object_id,
            $1:OBJECT_TYPE::VARCHAR                       AS object_type,
            $1:ETAG::VARCHAR                              AS etag,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/FORUM/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_GRID_CONNECTION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO grid_connection FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:CONNECTION_ID::VARCHAR                     AS connection_id,
            $1:SESSION_ID::VARCHAR                        AS session_id,
            $1:REPLICA_ID::BIGINT                         AS replica_id,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:SOURCE::VARCHAR                            AS source,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/GRID_CONNECTION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_GRID_PATCH_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO grid_patch FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:SESSION_ID::VARCHAR                        AS session_id,
            $1:PATCH_ID_REP::BIGINT                       AS patch_id_rep,
            $1:PATCH_ID_SEQ::BIGINT                       AS patch_id_seq,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:EXPIRES_ON::TIMESTAMP_NTZ(9)               AS expires_on,
            $1:S3_KEY::VARCHAR                            AS s3_key,
            $1:SIZE_BYTES::BIGINT                         AS size_bytes,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/GRID_PATCH/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_GRID_REPLICA_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO grid_replica FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:REPLICA_ID::BIGINT                         AS replica_id,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:SESSION_ID::VARCHAR                        AS session_id,
            ($1:IS_AGENT::NUMBER != 0)                    AS is_agent,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/GRID_REPLICA/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_GRID_SESSION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO grid_session FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:MODIFIED_ON::TIMESTAMP_NTZ(9)              AS modified_on,
            $1:SESSION_ID::VARCHAR                        AS session_id,
            $1:REP_ID_CLIENT::BIGINT                      AS rep_id_client,
            $1:REP_ID_SERVICE::BIGINT                     AS rep_id_service,
            $1:SOURCE_ID::BIGINT                          AS source_id,
            $1:SCHEMA_ID::VARCHAR                         AS schema_id,
            $1:OWNER_ID::BIGINT                           AS owner_id,
            $1:AUTHORIZATION_MODE::VARCHAR                AS authorization_mode,
            $1:BENEFACTOR_IDS::VARCHAR                    AS benefactor_ids,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/GRID_SESSION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_GRID_SNAPSHOT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO grid_snapshot FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:SESSION_ID::VARCHAR                        AS session_id,
            $1:CLOCK_TABLE::VARCHAR                       AS clock_table,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:S3_KEY::VARCHAR                            AS s3_key,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/GRID_SNAPSHOT/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_GROUP_MEMBERS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO group_members FROM (
        SELECT
            $1:GROUP_ID::BIGINT                           AS group_id,
            $1:MEMBER_ID::BIGINT                          AS member_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/GROUP_MEMBERS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_JSON_SCHEMA_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO json_schema FROM (
        SELECT
            $1:SCHEMA_ID::BIGINT                          AS schema_id,
            $1:ORGANIZATION_ID::BIGINT                    AS organization_id,
            $1:SCHEMA_NAME::VARCHAR                       AS schema_name,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/JSON_SCHEMA/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_JSON_SCHEMA_BLOB_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO json_schema_blob FROM (
        SELECT
            $1:BLOB_ID::BIGINT                            AS blob_id,
            $1:JSON_BLOB::VARCHAR                         AS json_blob,
            $1:SHA_256_HEX::VARCHAR                       AS sha_256_hex,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/JSON_SCHEMA_BLOB/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_JSON_SCHEMA_DEPENDENCY_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO json_schema_dependency FROM (
        SELECT
            $1:VERSION_ID::BIGINT                         AS version_id,
            $1:DEPENDS_ON_SCHEMA_ID::BIGINT               AS depends_on_schema_id,
            $1:DEPENDS_ON_VERSION_ID::BIGINT              AS depends_on_version_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/JSON_SCHEMA_DEPENDENCY/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_JSON_SCHEMA_LATEST_VERSION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO json_schema_latest_version FROM (
        SELECT
            $1:SCHEMA_ID::BIGINT                          AS schema_id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:VERSION_ID::BIGINT                         AS version_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/JSON_SCHEMA_LATEST_VERSION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_JSON_SCHEMA_OBJECT_BINDING_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO json_schema_object_binding FROM (
        SELECT
            $1:BIND_ID::BIGINT                            AS bind_id,
            $1:SCHEMA_ID::BIGINT                          AS schema_id,
            $1:VERSION_ID::BIGINT                         AS version_id,
            $1:OBJECT_ID::BIGINT                          AS object_id,
            $1:OBJECT_TYPE::VARCHAR                       AS object_type,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            ($1:ENABLE_DERIVED::NUMBER != 0)              AS enable_derived,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/JSON_SCHEMA_OBJECT_BINDING/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_JSON_SCHEMA_VALIDATION_RESULTS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO json_schema_validation_results FROM (
        SELECT
            $1:OBJECT_ID::BIGINT                          AS object_id,
            $1:OBJECT_TYPE::VARCHAR                       AS object_type,
            $1:OBJECT_ETAG::VARCHAR                       AS object_etag,
            $1:SCHEMA_ID::VARCHAR                         AS schema_id,
            ($1:IS_VALID::NUMBER != 0)                    AS is_valid,
            $1:VALIDATED_ON::TIMESTAMP_NTZ(9)             AS validated_on,
            $1:ERROR_MESSAGE::VARCHAR                     AS error_message,
            $1:ALL_ERROR_MESSAGES::VARCHAR                AS all_error_messages,
            $1:VALIDATION_EXCEPTION::VARCHAR              AS validation_exception,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/JSON_SCHEMA_VALIDATION_RESULTS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_JSON_SCHEMA_VERSION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO json_schema_version FROM (
        SELECT
            $1:VERSION_ID::BIGINT                         AS version_id,
            $1:SCHEMA_ID::BIGINT                          AS schema_id,
            $1:SEMANTIC_VERSION::VARCHAR                  AS semantic_version,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:BLOB_ID::BIGINT                            AS blob_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/JSON_SCHEMA_VERSION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_MATERIALIZED_VIEW_ID_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO materialized_view_id FROM (
        SELECT
            $1:MATERIALIZED_VIEW_ID::BIGINT               AS materialized_view_id,
            $1:ETAG::VARCHAR                              AS etag,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/MATERIALIZED_VIEW_ID/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_MATERIALIZED_VIEW_SOURCE_TABLES_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO materialized_view_source_tables FROM (
        SELECT
            $1:MATERIALIZED_VIEW_ID::BIGINT               AS materialized_view_id,
            $1:MATERIALIZED_VIEW_VERSION::BIGINT          AS materialized_view_version,
            $1:SOURCE_TABLE_ID::BIGINT                    AS source_table_id,
            $1:SOURCE_TABLE_VERSION::BIGINT               AS source_table_version,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/MATERIALIZED_VIEW_SOURCE_TABLES/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_MEMBERSHIP_INVITATION_SUBMISSION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO membership_invitation_submission FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:TEAM_ID::BIGINT                            AS team_id,
            $1:INVITEE_ID::BIGINT                         AS invitee_id,
            $1:INVITEE_EMAIL::VARCHAR                     AS invitee_email,
            $1:CREATED_ON::BIGINT                         AS created_on,
            $1:EXPIRES_ON::BIGINT                         AS expires_on,
            $1:PROPERTIES::BINARY                         AS properties,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/MEMBERSHIP_INVITATION_SUBMISSION/
    )
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_MEMBERSHIP_REQUEST_SUBMISSION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO membership_request_submission FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:TEAM_ID::BIGINT                            AS team_id,
            $1:CREATED_ON::BIGINT                         AS created_on,
            $1:USER_ID::BIGINT                            AS user_id,
            $1:EXPIRES_ON::BIGINT                         AS expires_on,
            $1:PROPERTIES::BINARY                         AS properties,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/MEMBERSHIP_REQUEST_SUBMISSION/
    )
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_MESSAGE_BROADCAST_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO message_broadcast FROM (
        SELECT
            $1:CHANGE_NUMBER::BIGINT                      AS change_number,
            $1:SENT_ON::BIGINT                            AS sent_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/MESSAGE_BROADCAST/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_MESSAGE_CONTENT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO message_content FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:FILE_HANDLE_ID::BIGINT                     AS file_handle_id,
            $1:CREATED_ON::BIGINT                         AS created_on,
            $1:ETAG::VARCHAR                              AS etag,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/MESSAGE_CONTENT/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_MESSAGE_RECIPIENT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO message_recipient FROM (
        SELECT
            $1:MESSAGE_ID::BIGINT                         AS message_id,
            $1:RECIPIENT_ID::BIGINT                       AS recipient_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/MESSAGE_RECIPIENT/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_MESSAGE_STATUS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO message_status FROM (
        SELECT
            $1:MESSAGE_ID::BIGINT                         AS message_id,
            $1:RECIPIENT_ID::BIGINT                       AS recipient_id,
            $1:STATUS::VARCHAR                            AS status,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/MESSAGE_STATUS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_MESSAGE_TO_USER_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO message_to_user FROM (
        SELECT
            $1:MESSAGE_ID::BIGINT                            AS message_id,
            $1:ROOT_MESSAGE_ID::BIGINT                       AS root_message_id,
            $1:IN_REPLY_TO::BIGINT                           AS in_reply_to,
            $1:SUBJECT::BINARY                               AS subject,
            $1:NOTIFICATIONS_ENDPOINT::VARCHAR               AS notifications_endpoint,
            $1:PROFILE_SETTING_ENDPOINT::VARCHAR             AS profile_setting_endpoint,
            ($1:WITH_UNSUBSCRIBE_LINK::NUMBER != 0)          AS with_unsubscribe_link,
            ($1:WITH_PROFILE_SETTING_LINK::NUMBER != 0)      AS with_profile_setting_link,
            ($1:IS_NOTIFICATION_MESSAGE::NUMBER != 0)        AS is_notification_message,
            ($1:OVERRIDE_NOTIFICATION_SETTINGS::NUMBER != 0) AS override_notification_settings,
            $1:PRIMARY_RECIPIENTS::BINARY                    AS primary_recipients,
            $1:CC::BINARY                                    AS cc,
            $1:BCC::BINARY                                   AS bcc,
            ($1:SENT::NUMBER != 0)                           AS sent,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT    AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE      AS snapshot_date,
            METADATA$FILENAME                                AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/MESSAGE_TO_USER/
    )
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_MULTIPART_UPLOAD_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO multipart_upload FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:REQUEST_HASH::VARCHAR                      AS request_hash,
            $1:ETAG::VARCHAR                              AS etag,
            $1:REQUEST_BLOB::BINARY                       AS request_blob,
            $1:STARTED_BY::BIGINT                         AS started_by,
            $1:STARTED_ON::TIMESTAMP_NTZ(9)               AS started_on,
            $1:UPDATED_ON::TIMESTAMP_NTZ(9)               AS updated_on,
            $1:FILE_HANDLE_ID::BIGINT                     AS file_handle_id,
            $1:STATE::VARCHAR                             AS state,
            $1:UPLOAD_TOKEN::VARCHAR                      AS upload_token,
            $1:UPLOAD_TYPE::VARCHAR                       AS upload_type,
            $1:BUCKET::VARCHAR                            AS bucket,
            $1:FILE_KEY::VARCHAR                          AS file_key,
            $1:NUMBER_OF_PARTS::BIGINT                    AS number_of_parts,
            $1:REQUEST_TYPE::VARCHAR                      AS request_type,
            $1:PART_SIZE::BIGINT                          AS part_size,
            $1:SOURCE_FILE_HANDLE_ID::BIGINT              AS source_file_handle_id,
            $1:SOURCE_FILE_ETAG::VARCHAR                  AS source_file_etag,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/MULTIPART_UPLOAD/
    )
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_MULTIPART_UPLOAD_COMPOSER_PART_STATE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO multipart_upload_composer_part_state FROM (
        SELECT
            $1:UPLOAD_ID::BIGINT                          AS upload_id,
            $1:PART_RANGE_LOWER_BOUND::BIGINT             AS part_range_lower_bound,
            $1:PART_RANGE_UPPER_BOUND::BIGINT             AS part_range_upper_bound,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/MULTIPART_UPLOAD_COMPOSER_PART_STATE/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_MULTIPART_UPLOAD_PART_STATE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO multipart_upload_part_state FROM (
        SELECT
            $1:UPLOAD_ID::BIGINT                          AS upload_id,
            $1:PART_NUMBER::BIGINT                        AS part_number,
            $1:PART_MD5_HEX::VARCHAR                      AS part_md5_hex,
            $1:ERROR_DETAILS::BINARY                      AS error_details,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/MULTIPART_UPLOAD_PART_STATE/
    )
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_NODE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO node FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::BIGINT                         AS created_on,
            $1:CURRENT_REV_NUM::BIGINT                    AS current_rev_num,
            $1:MAX_REV_NUM::BIGINT                        AS max_rev_num,
            $1:ETAG::VARCHAR                              AS etag,
            $1:NAME::VARCHAR                              AS name,
            $1:NODE_TYPE::VARCHAR                         AS node_type,
            $1:PARENT_ID::BIGINT                          AS parent_id,
            $1:ALIAS::VARCHAR                             AS alias,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/NODE/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_NODE_ACCESS_REQUIREMENT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO node_access_requirement FROM (
        SELECT
            $1:SUBJECT_ID::BIGINT                         AS subject_id,
            $1:SUBJECT_TYPE::VARCHAR                      AS subject_type,
            $1:REQUIREMENT_ID::BIGINT                     AS requirement_id,
            $1:BINDING_TYPE::VARCHAR                      AS binding_type,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/NODE_ACCESS_REQUIREMENT/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_NODE_REVISION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO node_revision FROM (
        SELECT
            $1:OWNER_NODE_ID::BIGINT                      AS owner_node_id,
            $1:NUMBER::BIGINT                             AS number,
            $1:ACTIVITY_ID::BIGINT                        AS activity_id,
            $1:ENTITY_PROPERTY_ANNOTATIONS::BINARY        AS entity_property_annotations,
            $1:USER_ANNOTATIONS::VARCHAR                  AS user_annotations,
            $1:DESCRIPTION::VARCHAR                       AS description,
            $1:COMMENT::VARCHAR                           AS comment,
            $1:LABEL::VARCHAR                             AS label,
            $1:MODIFIED_BY::BIGINT                        AS modified_by,
            $1:MODIFIED_ON::BIGINT                        AS modified_on,
            $1:FILE_HANDLE_ID::BIGINT                     AS file_handle_id,
            $1:COLUMN_MODEL_IDS::BINARY                   AS column_model_ids,
            $1:SCOPE_IDS::BINARY                          AS scope_ids,
            $1:ITEMS::VARCHAR                             AS items,
            ($1:SEARCH_ENABLED::NUMBER != 0)              AS search_enabled,
            $1:DEFINING_SQL::VARCHAR                      AS defining_sql,
            $1:REFERENCE_JSON::VARCHAR                    AS reference_json,
            $1:UPSERT_KEY::VARCHAR                        AS upsert_key,
            $1:CSV_DESCRIPTOR::VARCHAR                    AS csv_descriptor,
            $1:VALIDATION_RES_FILE_HANDLE_ID::BIGINT      AS validation_res_file_handle_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/NODE_REVISION/
    )
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_NOTIFICATION_EMAIL_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO notification_email FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:PRINCIPAL_ID::BIGINT                       AS principal_id,
            $1:ALIAS_ID::BIGINT                           AS alias_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/NOTIFICATION_EMAIL/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_OAUTH_ACCESS_TOKEN_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO oauth_access_token FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:TOKEN_ID::VARCHAR                          AS token_id,
            $1:REFRESH_TOKEN_ID::BIGINT                   AS refresh_token_id,
            $1:PRINCIPAL_ID::BIGINT                       AS principal_id,
            $1:CLIENT_ID::BIGINT                          AS client_id,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:EXPIRES_ON::TIMESTAMP_NTZ(9)               AS expires_on,
            $1:SESSION_ID::VARCHAR                        AS session_id,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/OAUTH_ACCESS_TOKEN/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_OAUTH_AUTHORIZATION_CODE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO oauth_authorization_code FROM (
        SELECT
            $1:AUTH_CODE::VARCHAR                         AS auth_code,
            $1:AUTHORIZATION_REQUEST::BINARY              AS authorization_request,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/OAUTH_AUTHORIZATION_CODE/
    )
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_OAUTH_CLIENT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO oauth_client FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:NAME::VARCHAR                              AS name,
            $1:SECRET_HASH::VARCHAR                       AS secret_hash,
            $1:OAUTH_SECTOR_IDENTIFIER_URI::VARCHAR       AS oauth_sector_identifier_uri,
            ($1:IS_VERIFIED::NUMBER != 0)                 AS is_verified,
            $1:JSON::VARCHAR                              AS json,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::BIGINT                         AS created_on,
            $1:MODIFIED_ON::BIGINT                        AS modified_on,
            $1:ETAG::VARCHAR                              AS etag,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/OAUTH_CLIENT/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_OAUTH_REFRESH_TOKEN_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO oauth_refresh_token FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:TOKEN_HASH::VARCHAR                        AS token_hash,
            $1:NAME::VARCHAR                              AS name,
            $1:PRINCIPAL_ID::BIGINT                       AS principal_id,
            $1:CLIENT_ID::BIGINT                          AS client_id,
            $1:SCOPES_JSON::VARCHAR                       AS scopes_json,
            $1:CLAIMS_JSON::VARCHAR                       AS claims_json,
            $1:LAST_USED::TIMESTAMP_NTZ(9)                AS last_used,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:MODIFIED_ON::TIMESTAMP_NTZ(9)              AS modified_on,
            $1:ETAG::VARCHAR                              AS etag,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/OAUTH_REFRESH_TOKEN/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_OAUTH_SECTOR_IDENTIFIER_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO oauth_sector_identifier FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:URI::VARCHAR                               AS uri,
            $1:SECRET::VARCHAR                            AS secret,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::BIGINT                         AS created_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/OAUTH_SECTOR_IDENTIFIER/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_ORGANIZATION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO organization FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:NAME::VARCHAR                              AS name,
            $1:CREATED_BY::BIGINT                         AS created_by,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/ORGANIZATION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_OTP_RECOVERY_CODE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO otp_recovery_code FROM (
        SELECT
            $1:SECRET_ID::BIGINT                          AS secret_id,
            $1:CODE_HASH::VARCHAR                         AS code_hash,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/OTP_RECOVERY_CODE/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_OTP_SECRET_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO otp_secret FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:ETAG::VARCHAR                              AS etag,
            $1:PRINCIPAL_ID::BIGINT                       AS principal_id,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            $1:SECRET::VARCHAR                            AS secret,
            ($1:ACTIVE::NUMBER != 0)                      AS active,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/OTP_SECRET/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

CREATE OR REPLACE TASK COPY_PERSONAL_ACCESS_TOKEN_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO personal_access_token FROM (
        SELECT
            $1:ID::BIGINT                                 AS id,
            $1:NAME::VARCHAR                              AS name,
            $1:PRINCIPAL_ID::BIGINT                       AS principal_id,
            $1:SCOPES::BINARY                             AS scopes,
            $1:CLAIMS::BINARY                             AS claims,
            $1:LAST_USED::TIMESTAMP_NTZ(9)                AS last_used,
            $1:CREATED_ON::TIMESTAMP_NTZ(9)               AS created_on,
            SPLIT_PART(METADATA$FILENAME, '/', 3)::BIGINT AS stack,
            SPLIT_PART(METADATA$FILENAME, '/', 4)::DATE   AS snapshot_date,
            METADATA$FILENAME                             AS filename
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/PERSONAL_ACCESS_TOKEN/
    )
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';
