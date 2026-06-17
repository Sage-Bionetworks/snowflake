USE SCHEMA {{database_name}}.RDS_LANDING; --noqa: JJ01,PRS,TMP

-- ============================================================
-- Root task: refreshes stage metadata so COPY INTO tasks see
-- the latest S3 files before any loading begins.
-- ============================================================
CREATE OR REPLACE TASK REFRESH_RDS_SNAPSHOTS_STAGE_TASK
    -- TODO: every minute for testing; revert before production rollout.
    SCHEDULE = 'USING CRON * * * * * America/Los_Angeles'
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE='SMALL'
    AS ALTER STAGE IF EXISTS RDS_SNAPSHOTS_STAGE REFRESH;


-- ============================================================
-- Proxy task: no-op fan-out node between the root and the
-- COPY INTO tasks. Exists to work around Snowflake's 100-child-
-- task limit per node; add PROXY_TASK_B when child tasks on this
-- node exceed 100.
-- ============================================================
CREATE OR REPLACE TASK PROXY_TASK_A
    COMMENT = 'No-op intermediary task. Snowflake limits a single node to 100 child tasks; this proxy fans out to all COPY INTO tasks. Add PROXY_TASK_B when child tasks on this node exceed 100.'
    AFTER REFRESH_RDS_SNAPSHOTS_STAGE_TASK
AS
    SELECT 1;


-- ============================================================
-- COPY INTO tasks — one per record type, all triggered in
-- parallel after PROXY_TASK_A completes.
-- ============================================================
CREATE OR REPLACE TASK COPY_ACCESS_APPROVAL_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO access_approval FROM (
        SELECT
            $1:ID::BIGINT                  AS id,
            $1:REQUIREMENT_ID::BIGINT      AS requirement_id,
            $1:REQUIREMENT_VERSION::BIGINT AS requirement_version,
            $1:CREATED_BY::BIGINT          AS created_by,
            $1:CREATED_ON::BIGINT          AS created_on,
            $1:MODIFIED_BY::BIGINT         AS modified_by,
            $1:MODIFIED_ON::BIGINT         AS modified_on,
            $1:SUBMITTER_ID::BIGINT        AS submitter_id,
            $1:ACCESSOR_ID::BIGINT         AS accessor_id,
            $1:EXPIRED_ON::BIGINT          AS expired_on,
            $1:STATE::VARCHAR              AS state,
            $1:ETAG::VARCHAR               AS etag
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/ACCESS_APPROVAL/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';
CREATE OR REPLACE TASK COPY_ACL_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO acl FROM (
        SELECT
            $1:ID::BIGINT          AS id,
            $1:OWNER_ID::BIGINT    AS owner_id,
            $1:OWNER_TYPE::VARCHAR AS owner_type,
            $1:CREATED_ON::BIGINT  AS created_on,
            $1:ETAG::VARCHAR       AS etag
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/ACL/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';
CREATE OR REPLACE TASK COPY_ACL_RESOURCE_ACCESS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO acl_resource_access FROM (
        SELECT
            $1:ID::BIGINT       AS id,
            $1:OWNER_ID::BIGINT AS owner_id,
            $1:GROUP_ID::BIGINT AS group_id
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/ACL_RESOURCE_ACCESS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';
CREATE OR REPLACE TASK COPY_ACL_RESOURCE_ACCESS_TYPE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO acl_resource_access_type FROM (
        SELECT
            $1:ID_OID::BIGINT      AS id_oid,
            $1:STRING_ELE::VARCHAR AS string_ele,
            $1:OWNER_ID::BIGINT    AS owner_id
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/ACL_RESOURCE_ACCESS_TYPE/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';
CREATE OR REPLACE TASK COPY_DATA_ACCESS_SUBMISSION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO data_access_submission FROM (
        SELECT
            $1:ID::BIGINT                         AS id,
            $1:ACCESS_REQUIREMENT_ID::BIGINT      AS access_requirement_id,
            $1:DATA_ACCESS_REQUEST_ID::BIGINT     AS data_access_request_id,
            $1:RESEARCH_PROJECT_ID::BIGINT        AS research_project_id,
            $1:CREATED_BY::BIGINT                 AS created_by,
            $1:CREATED_ON::BIGINT                 AS created_on,
            $1:ACCESS_REQUIREMENT_VERSION::BIGINT AS access_requirement_version,
            $1:ETAG::VARCHAR                      AS etag,
            $1:SUBMISSION_SERIALIZED::BINARY      AS submission_serialized
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DATA_ACCESS_SUBMISSION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';
CREATE OR REPLACE TASK COPY_DATA_ACCESS_SUBMISSION_ACCESSOR_CHANGES_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO data_access_submission_accessor_changes FROM (
        SELECT
            $1:SUBMISSION_ID::BIGINT AS submission_id,
            $1:ACCESSOR_ID::BIGINT   AS accessor_id,
            $1:ACCESS_TYPE::VARCHAR  AS access_type
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DATA_ACCESS_SUBMISSION_ACCESSOR_CHANGES/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';
CREATE OR REPLACE TASK COPY_DATA_ACCESS_SUBMISSION_STATUS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO data_access_submission_status FROM (
        SELECT
            $1:SUBMISSION_ID::BIGINT AS submission_id,
            $1:CREATED_BY::BIGINT    AS created_by,
            $1:CREATED_ON::BIGINT    AS created_on,
            $1:MODIFIED_BY::BIGINT   AS modified_by,
            $1:MODIFIED_ON::BIGINT   AS modified_on,
            $1:STATE::VARCHAR        AS state,
            $1:REASON::BINARY        AS reason
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DATA_ACCESS_SUBMISSION_STATUS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';
CREATE OR REPLACE TASK COPY_DATA_ACCESS_SUBMISSION_SUBMITTER_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO data_access_submission_submitter FROM (
        SELECT
            $1:ID::BIGINT                    AS id,
            $1:ACCESS_REQUIREMENT_ID::BIGINT AS access_requirement_id,
            $1:SUBMITTER_ID::BIGINT          AS submitter_id,
            $1:CURRENT_SUBMISSION_ID::BIGINT AS current_submission_id,
            $1:ETAG::VARCHAR                 AS etag
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DATA_ACCESS_SUBMISSION_SUBMITTER/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';
CREATE OR REPLACE TASK COPY_DATA_ACCESS_REQUEST_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO data_access_request FROM (
        SELECT
            $1:ID::BIGINT                    AS id,
            $1:ACCESS_REQUIREMENT_ID::BIGINT AS access_requirement_id,
            $1:RESEARCH_PROJECT_ID::BIGINT   AS research_project_id,
            $1:CREATED_BY::BIGINT            AS created_by,
            $1:CREATED_ON::BIGINT            AS created_on,
            $1:MODIFIED_BY::BIGINT           AS modified_by,
            $1:MODIFIED_ON::BIGINT           AS modified_on,
            $1:ETAG::VARCHAR                 AS etag,
            $1:REQUEST_SERIALIZED::BINARY    AS request_serialized
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DATA_ACCESS_REQUEST/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';
CREATE OR REPLACE TASK COPY_ACCESS_REQUIREMENT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO access_requirement FROM (
        SELECT
            $1:ID::BIGINT                  AS id,
            $1:NAME::VARCHAR               AS name,
            $1:CONCRETE_TYPE::VARCHAR      AS concrete_type,
            $1:CREATED_BY::BIGINT          AS created_by,
            $1:CREATED_ON::BIGINT          AS created_on,
            $1:CURRENT_REV_NUM::BIGINT     AS current_rev_num,
            $1:IS_TWO_FA_REQUIRED::BIGINT AS is_two_fa_required,
            $1:ACCESS_TYPE::VARCHAR        AS access_type,
            $1:ETAG::VARCHAR               AS etag
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/ACCESS_REQUIREMENT/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';
CREATE OR REPLACE TASK COPY_ACCESS_REQUIREMENT_PROJECT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO access_requirement_project FROM (
        SELECT
            $1:AR_ID::BIGINT      AS ar_id,
            $1:PROJECT_ID::BIGINT AS project_id
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/ACCESS_REQUIREMENT_PROJECT/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';
CREATE OR REPLACE TASK COPY_ACCESS_REQUIREMENT_REVISION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO access_requirement_revision FROM (
        SELECT
            $1:OWNER_ID::BIGINT          AS owner_id,
            $1:NUMBER::BIGINT            AS number,
            $1:MODIFIED_BY::BIGINT       AS modified_by,
            $1:MODIFIED_ON::BIGINT       AS modified_on,
            $1:SERIALIZED_ENTITY::BINARY AS serialized_entity
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/ACCESS_REQUIREMENT_REVISION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';
CREATE OR REPLACE TASK COPY_DATA_ACCESS_NOTIFICATION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO data_access_notification FROM (
        SELECT
            $1:ID::BIGINT                 AS id,
            $1:NOTIFICATION_TYPE::VARCHAR AS notification_type,
            $1:REQUIREMENT_ID::BIGINT     AS requirement_id,
            $1:RECIPIENT_ID::BIGINT       AS recipient_id,
            $1:ACCESS_APPROVAL_ID::BIGINT AS access_approval_id,
            $1:SENT_ON::TIMESTAMP_NTZ(9)  AS sent_on,
            $1:MESSAGE_ID::BIGINT         AS message_id,
            $1:ETAG::VARCHAR              AS etag
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/DATA_ACCESS_NOTIFICATION/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';
CREATE OR REPLACE TASK COPY_PRINCIPAL_ALIAS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO principal_alias FROM (
        SELECT
            $1:ID::BIGINT             AS id,
            $1:PRINCIPAL_ID::BIGINT   AS principal_id,
            $1:ALIAS_UNIQUE::VARCHAR  AS alias_unique,
            $1:ALIAS_DISPLAY::VARCHAR AS alias_display,
            $1:TYPE::VARCHAR          AS type,
            $1:ETAG::VARCHAR          AS etag
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot/PRINCIPAL_ALIAS/
    )
    PATTERN = '.*\/[0-9]+\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*\.gz\.parquet';

-- ============================================================
-- Resume tasks: children must be resumed before the root task.
-- Root task is resumed last to activate the schedule.
-- ============================================================
ALTER TASK COPY_ACCESS_APPROVAL_TASK RESUME;
ALTER TASK COPY_ACL_TASK RESUME;
ALTER TASK COPY_ACL_RESOURCE_ACCESS_TASK RESUME;
ALTER TASK COPY_ACL_RESOURCE_ACCESS_TYPE_TASK RESUME;
ALTER TASK COPY_DATA_ACCESS_SUBMISSION_TASK RESUME;
ALTER TASK COPY_DATA_ACCESS_SUBMISSION_ACCESSOR_CHANGES_TASK RESUME;
ALTER TASK COPY_DATA_ACCESS_SUBMISSION_STATUS_TASK RESUME;
ALTER TASK COPY_DATA_ACCESS_SUBMISSION_SUBMITTER_TASK RESUME;
ALTER TASK COPY_DATA_ACCESS_REQUEST_TASK RESUME;
ALTER TASK COPY_ACCESS_REQUIREMENT_TASK RESUME;
ALTER TASK COPY_ACCESS_REQUIREMENT_PROJECT_TASK RESUME;
ALTER TASK COPY_ACCESS_REQUIREMENT_REVISION_TASK RESUME;
ALTER TASK COPY_DATA_ACCESS_NOTIFICATION_TASK RESUME;
ALTER TASK COPY_PRINCIPAL_ALIAS_TASK RESUME;
ALTER TASK PROXY_TASK_A RESUME;
ALTER TASK REFRESH_RDS_SNAPSHOTS_STAGE_TASK RESUME;
