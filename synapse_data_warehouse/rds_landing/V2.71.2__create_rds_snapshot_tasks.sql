USE SCHEMA {{database_name}}.RDS_LANDING; --noqa: JJ01,PRS,TMP

-- ============================================================
-- Root task: refreshes stage metadata so COPY INTO tasks see
-- the latest S3 files before any loading begins.
-- ============================================================
CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK
    WAREHOUSE = compute_xsmall
    -- TODO: Finalize schedule with Platform. Current cron runs at 8am daily, PT.
    SCHEDULE = 'USING CRON 0 8 * * * America/Los_Angeles'
AS
    ALTER STAGE IF EXISTS {{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE REFRESH;


-- ============================================================
-- Proxy task: no-op fan-out node between the root and the
-- COPY INTO tasks. Exists to work around Snowflake's 100-child-
-- task limit per node; add PROXY_TASK_B when child tasks on this
-- node exceed 100.
-- ============================================================
CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.PROXY_TASK_A
    WAREHOUSE = compute_xsmall
    COMMENT = 'No-op intermediary task. Snowflake limits a single node to 100 child tasks; this proxy fans out to all COPY INTO tasks. Add PROXY_TASK_B when child tasks on this node exceed 100.'
    AFTER {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK
AS
    SELECT 1;


-- ============================================================
-- COPY INTO tasks — one per record type, all triggered in
-- parallel after PROXY_TASK_A completes.
-- ============================================================
CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_ACCESS_APPROVAL_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.PROXY_TASK_A
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_access_approval
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    -- TODO: Finalize file naming convention with Platform and update regex pattern as needed.
    PATTERN = '.*ACCESS_APPROVAL/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_ACL_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.PROXY_TASK_A
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_acl
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*[^_]ACL/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_ACL_RESOURCE_ACCESS_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.PROXY_TASK_A
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_acl_resource_access
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*ACL_RESOURCE_ACCESS/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_ACL_RESOURCE_ACCESS_TYPE_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.PROXY_TASK_A
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_acl_resource_access_type
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*ACL_RESOURCE_ACCESS_TYPE/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_DATA_ACCESS_SUBMISSION_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.PROXY_TASK_A
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_data_access_submission
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*DATA_ACCESS_SUBMISSION/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_DATA_ACCESS_SUBMISSION_ACCESSOR_CHANGES_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.PROXY_TASK_A
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_data_access_submission_accessor_changes
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*DATA_ACCESS_SUBMISSION_ACCESSOR_CHANGES/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_DATA_ACCESS_SUBMISSION_STATUS_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.PROXY_TASK_A
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_data_access_submission_status
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*DATA_ACCESS_SUBMISSION_STATUS/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_DATA_ACCESS_SUBMISSION_SUBMITTER_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.PROXY_TASK_A
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_data_access_submission_submitter
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*DATA_ACCESS_SUBMISSION_SUBMITTER/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_DATA_ACCESS_REQUEST_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.PROXY_TASK_A
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_data_access_request
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*DATA_ACCESS_REQUEST/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_ACCESS_REQUIREMENT_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.PROXY_TASK_A
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_access_requirement
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*ACCESS_REQUIREMENT/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_ACCESS_REQUIREMENT_PROJECT_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.PROXY_TASK_A
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_access_requirement_project
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*ACCESS_REQUIREMENT_PROJECT/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_ACCESS_REQUIREMENT_REVISION_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.PROXY_TASK_A
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_access_requirement_revision
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*ACCESS_REQUIREMENT_REVISION/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_DATA_ACCESS_NOTIFICATION_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.PROXY_TASK_A
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_data_access_notification
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*DATA_ACCESS_NOTIFICATION/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_PRINCIPAL_ALIAS_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.PROXY_TASK_A
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_principal_alias
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*PRINCIPAL_ALIAS/.*\.parquet$'
    ON_ERROR = CONTINUE;


-- ============================================================
-- Resume tasks: children must be resumed before the root task.
-- Root task is resumed last to activate the schedule.
-- ============================================================
ALTER TASK {{database_name}}.RDS_LANDING.PROXY_TASK_A RESUME;
ALTER TASK {{database_name}}.RDS_LANDING.COPY_ACCESS_APPROVAL_TASK RESUME;
ALTER TASK {{database_name}}.RDS_LANDING.COPY_ACL_TASK RESUME;
ALTER TASK {{database_name}}.RDS_LANDING.COPY_ACL_RESOURCE_ACCESS_TASK RESUME;
ALTER TASK {{database_name}}.RDS_LANDING.COPY_ACL_RESOURCE_ACCESS_TYPE_TASK RESUME;
ALTER TASK {{database_name}}.RDS_LANDING.COPY_DATA_ACCESS_SUBMISSION_TASK RESUME;
ALTER TASK {{database_name}}.RDS_LANDING.COPY_DATA_ACCESS_SUBMISSION_ACCESSOR_CHANGES_TASK RESUME;
ALTER TASK {{database_name}}.RDS_LANDING.COPY_DATA_ACCESS_SUBMISSION_STATUS_TASK RESUME;
ALTER TASK {{database_name}}.RDS_LANDING.COPY_DATA_ACCESS_SUBMISSION_SUBMITTER_TASK RESUME;
ALTER TASK {{database_name}}.RDS_LANDING.COPY_DATA_ACCESS_REQUEST_TASK RESUME;
ALTER TASK {{database_name}}.RDS_LANDING.COPY_ACCESS_REQUIREMENT_TASK RESUME;
ALTER TASK {{database_name}}.RDS_LANDING.COPY_ACCESS_REQUIREMENT_PROJECT_TASK RESUME;
ALTER TASK {{database_name}}.RDS_LANDING.COPY_ACCESS_REQUIREMENT_REVISION_TASK RESUME;
ALTER TASK {{database_name}}.RDS_LANDING.COPY_DATA_ACCESS_NOTIFICATION_TASK RESUME;
ALTER TASK {{database_name}}.RDS_LANDING.COPY_PRINCIPAL_ALIAS_TASK RESUME;
ALTER TASK {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK RESUME;
