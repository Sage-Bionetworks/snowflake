USE SCHEMA {{database_name}}.RDS_LANDING; --noqa: JJ01,PRS,TMP

-- ============================================================
-- Root task: refreshes stage metadata so COPY INTO tasks see
-- the latest S3 files before any loading begins.
-- ============================================================
CREATE OR REPLACE TASK REFRESH_STAGE_TASK
    -- TEMPORARY: every minute for testing; revert before production rollout.
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
    WAREHOUSE = compute_xsmall
    COMMENT = 'No-op intermediary task. Snowflake limits a single node to 100 child tasks; this proxy fans out to all COPY INTO tasks. Add PROXY_TASK_B when child tasks on this node exceed 100.'
    AFTER REFRESH_STAGE_TASK
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
            $1:id::BIGINT                  AS id,
            $1:requirement_id::BIGINT      AS requirement_id,
            $1:requirement_version::BIGINT AS requirement_version,
            $1:created_by::BIGINT          AS created_by,
            $1:created_on::BIGINT          AS created_on,
            $1:modified_by::BIGINT         AS modified_by,
            $1:modified_on::BIGINT         AS modified_on,
            $1:submitter_id::BIGINT        AS submitter_id,
            $1:accessor_id::BIGINT         AS accessor_id,
            $1:expired_on::BIGINT          AS expired_on,
            $1:state::VARCHAR              AS state,
            $1:etag::VARCHAR               AS etag
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot
    )
    -- TODO: Finalize file naming convention with Platform and update regex pattern as needed.
    PATTERN = '.*ACCESS_APPROVAL/.*\.parquet$';
CREATE OR REPLACE TASK COPY_ACL_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO acl FROM (
        SELECT
            $1:id::BIGINT          AS id,
            $1:owner_id::BIGINT    AS owner_id,
            $1:owner_type::VARCHAR AS owner_type,
            $1:created_on::BIGINT  AS created_on,
            $1:etag::VARCHAR       AS etag
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot
    )
    PATTERN = '.*[^_]ACL/.*\.parquet$';
CREATE OR REPLACE TASK COPY_ACL_RESOURCE_ACCESS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO acl_resource_access FROM (
        SELECT
            $1:id::BIGINT       AS id,
            $1:owner_id::BIGINT AS owner_id,
            $1:group_id::BIGINT AS group_id
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot
    )
    PATTERN = '.*ACL_RESOURCE_ACCESS/.*\.parquet$';
CREATE OR REPLACE TASK COPY_ACL_RESOURCE_ACCESS_TYPE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO acl_resource_access_type FROM (
        SELECT
            $1:id_oid::BIGINT      AS id_oid,
            $1:string_ele::VARCHAR AS string_ele,
            $1:owner_id::BIGINT    AS owner_id
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot
    )
    PATTERN = '.*ACL_RESOURCE_ACCESS_TYPE/.*\.parquet$';
CREATE OR REPLACE TASK COPY_DATA_ACCESS_SUBMISSION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO data_access_submission FROM (
        SELECT
            $1:id::BIGINT                         AS id,
            $1:access_requirement_id::BIGINT      AS access_requirement_id,
            $1:data_access_request_id::BIGINT     AS data_access_request_id,
            $1:research_project_id::BIGINT        AS research_project_id,
            $1:created_by::BIGINT                 AS created_by,
            $1:created_on::BIGINT                 AS created_on,
            $1:access_requirement_version::BIGINT AS access_requirement_version,
            $1:etag::VARCHAR                      AS etag,
            $1:submission_serialized::BINARY      AS submission_serialized
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot
    )
    PATTERN = '.*DATA_ACCESS_SUBMISSION/.*\.parquet$';
CREATE OR REPLACE TASK COPY_DATA_ACCESS_SUBMISSION_ACCESSOR_CHANGES_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO data_access_submission_accessor_changes FROM (
        SELECT
            $1:submission_id::BIGINT AS submission_id,
            $1:accessor_id::BIGINT   AS accessor_id,
            $1:access_type::VARCHAR  AS access_type
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot
    )
    PATTERN = '.*DATA_ACCESS_SUBMISSION_ACCESSOR_CHANGES/.*\.parquet$';
CREATE OR REPLACE TASK COPY_DATA_ACCESS_SUBMISSION_STATUS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO data_access_submission_status FROM (
        SELECT
            $1:submission_id::BIGINT AS submission_id,
            $1:created_by::BIGINT    AS created_by,
            $1:created_on::BIGINT    AS created_on,
            $1:modified_by::BIGINT   AS modified_by,
            $1:modified_on::BIGINT   AS modified_on,
            $1:state::VARCHAR        AS state,
            $1:reason::BINARY        AS reason
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot
    )
    PATTERN = '.*DATA_ACCESS_SUBMISSION_STATUS/.*\.parquet$';
CREATE OR REPLACE TASK COPY_DATA_ACCESS_SUBMISSION_SUBMITTER_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO data_access_submission_submitter FROM (
        SELECT
            $1:id::BIGINT                    AS id,
            $1:access_requirement_id::BIGINT AS access_requirement_id,
            $1:submitter_id::BIGINT          AS submitter_id,
            $1:current_submission_id::BIGINT AS current_submission_id,
            $1:etag::VARCHAR                 AS etag
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot
    )
    PATTERN = '.*DATA_ACCESS_SUBMISSION_SUBMITTER/.*\.parquet$';
CREATE OR REPLACE TASK COPY_DATA_ACCESS_REQUEST_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO data_access_request FROM (
        SELECT
            $1:id::BIGINT                    AS id,
            $1:access_requirement_id::BIGINT AS access_requirement_id,
            $1:research_project_id::BIGINT   AS research_project_id,
            $1:created_by::BIGINT            AS created_by,
            $1:created_on::BIGINT            AS created_on,
            $1:modified_by::BIGINT           AS modified_by,
            $1:modified_on::BIGINT           AS modified_on,
            $1:etag::VARCHAR                 AS etag,
            $1:request_serialized::BINARY    AS request_serialized
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot
    )
    PATTERN = '.*DATA_ACCESS_REQUEST/.*\.parquet$';
CREATE OR REPLACE TASK COPY_ACCESS_REQUIREMENT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO access_requirement FROM (
        SELECT
            $1:id::BIGINT                  AS id,
            $1:name::VARCHAR               AS name,
            $1:concrete_type::VARCHAR      AS concrete_type,
            $1:created_by::BIGINT          AS created_by,
            $1:created_on::BIGINT          AS created_on,
            $1:current_rev_num::BIGINT     AS current_rev_num,
            $1:is_two_fa_required::BOOLEAN AS is_two_fa_required,
            $1:access_type::VARCHAR        AS access_type,
            $1:etag::VARCHAR               AS etag
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot
    )
    PATTERN = '.*ACCESS_REQUIREMENT/.*\.parquet$';
CREATE OR REPLACE TASK COPY_ACCESS_REQUIREMENT_PROJECT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO access_requirement_project FROM (
        SELECT
            $1:ar_id::BIGINT      AS ar_id,
            $1:project_id::BIGINT AS project_id
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot
    )
    PATTERN = '.*ACCESS_REQUIREMENT_PROJECT/.*\.parquet$';
CREATE OR REPLACE TASK COPY_ACCESS_REQUIREMENT_REVISION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO access_requirement_revision FROM (
        SELECT
            $1:owner_id::BIGINT          AS owner_id,
            $1:number::BIGINT            AS number,
            $1:modified_by::BIGINT       AS modified_by,
            $1:modified_on::BIGINT       AS modified_on,
            $1:serialized_entity::BINARY AS serialized_entity
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot
    )
    PATTERN = '.*ACCESS_REQUIREMENT_REVISION/.*\.parquet$';
CREATE OR REPLACE TASK COPY_DATA_ACCESS_NOTIFICATION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO data_access_notification FROM (
        SELECT
            $1:id::BIGINT                 AS id,
            $1:notification_type::VARCHAR AS notification_type,
            $1:requirement_id::BIGINT     AS requirement_id,
            $1:recipient_id::BIGINT       AS recipient_id,
            $1:access_approval_id::BIGINT AS access_approval_id,
            $1:sent_on::TIMESTAMP_NTZ(9)  AS sent_on,
            $1:message_id::BIGINT         AS message_id,
            $1:etag::VARCHAR              AS etag
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot
    )
    PATTERN = '.*DATA_ACCESS_NOTIFICATION/.*\.parquet$';
CREATE OR REPLACE TASK COPY_PRINCIPAL_ALIAS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO principal_alias FROM (
        SELECT
            $1:id::BIGINT             AS id,
            $1:principal_id::BIGINT   AS principal_id,
            $1:alias_unique::VARCHAR  AS alias_unique,
            $1:alias_display::VARCHAR AS alias_display,
            $1:type::VARCHAR          AS type,
            $1:etag::VARCHAR          AS etag
        FROM @RDS_SNAPSHOTS_STAGE/rds-snapshot
    )
    PATTERN = '.*PRINCIPAL_ALIAS/.*\.parquet$';

-- ============================================================
-- Resume tasks: children must be resumed before the root task.
-- Root task is resumed last to activate the schedule.
-- ============================================================
ALTER TASK PROXY_TASK_A RESUME;
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
ALTER TASK REFRESH_STAGE_TASK RESUME;
