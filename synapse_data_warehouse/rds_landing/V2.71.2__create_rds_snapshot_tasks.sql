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
    COPY INTO access_approval
    FROM @RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    -- TODO: Finalize file naming convention with Platform and update regex pattern as needed.
    PATTERN = '.*ACCESS_APPROVAL/.*\.parquet$';
CREATE OR REPLACE TASK COPY_ACL_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO acl
    FROM @RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*[^_]ACL/.*\.parquet$';
CREATE OR REPLACE TASK COPY_ACL_RESOURCE_ACCESS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO acl_resource_access
    FROM @RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*ACL_RESOURCE_ACCESS/.*\.parquet$';
CREATE OR REPLACE TASK COPY_ACL_RESOURCE_ACCESS_TYPE_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO acl_resource_access_type
    FROM @RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*ACL_RESOURCE_ACCESS_TYPE/.*\.parquet$';
CREATE OR REPLACE TASK COPY_DATA_ACCESS_SUBMISSION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO data_access_submission
    FROM @RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*DATA_ACCESS_SUBMISSION/.*\.parquet$';
CREATE OR REPLACE TASK COPY_DATA_ACCESS_SUBMISSION_ACCESSOR_CHANGES_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO data_access_submission_accessor_changes
    FROM @RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*DATA_ACCESS_SUBMISSION_ACCESSOR_CHANGES/.*\.parquet$';
CREATE OR REPLACE TASK COPY_DATA_ACCESS_SUBMISSION_STATUS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO data_access_submission_status
    FROM @RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*DATA_ACCESS_SUBMISSION_STATUS/.*\.parquet$';
CREATE OR REPLACE TASK COPY_DATA_ACCESS_SUBMISSION_SUBMITTER_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO data_access_submission_submitter
    FROM @RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*DATA_ACCESS_SUBMISSION_SUBMITTER/.*\.parquet$';
CREATE OR REPLACE TASK COPY_DATA_ACCESS_REQUEST_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO data_access_request
    FROM @RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*DATA_ACCESS_REQUEST/.*\.parquet$';
CREATE OR REPLACE TASK COPY_ACCESS_REQUIREMENT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO access_requirement
    FROM @RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*ACCESS_REQUIREMENT/.*\.parquet$';
CREATE OR REPLACE TASK COPY_ACCESS_REQUIREMENT_PROJECT_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO access_requirement_project
    FROM @RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*ACCESS_REQUIREMENT_PROJECT/.*\.parquet$';
CREATE OR REPLACE TASK COPY_ACCESS_REQUIREMENT_REVISION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO access_requirement_revision
    FROM @RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*ACCESS_REQUIREMENT_REVISION/.*\.parquet$';
CREATE OR REPLACE TASK COPY_DATA_ACCESS_NOTIFICATION_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO data_access_notification
    FROM @RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*DATA_ACCESS_NOTIFICATION/.*\.parquet$';
CREATE OR REPLACE TASK COPY_PRINCIPAL_ALIAS_TASK
    WAREHOUSE = compute_xsmall
    AFTER PROXY_TASK_A
AS
    COPY INTO principal_alias
    FROM @RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
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
