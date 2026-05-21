USE SCHEMA {{database_name}}.RDS_LANDING; --noqa: JJ01,PRS,TMP

-- ============================================================
-- Stored procedure called by FINALIZER_TASK.
-- Queries LOAD_HISTORY for copy stats and sends a Slack
-- notification regardless of whether the graph succeeded or failed.
-- ============================================================
CREATE OR REPLACE PROCEDURE {{database_name}}.RDS_LANDING.FINALIZE_RDS_SNAPSHOT_INGESTION()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    loaded_count   INTEGER DEFAULT 0;
    failed_count   INTEGER DEFAULT 0;
    total_rows     INTEGER DEFAULT 0;
    failed_tables  STRING  DEFAULT '';
    run_date       STRING;
    notification_msg STRING;
BEGIN
    run_date := TO_VARCHAR(CURRENT_DATE(), 'MM/DD/YYYY');

    SELECT
        COUNT_IF(STATUS = 'Loaded'),
        COUNT_IF(STATUS != 'Loaded'),
        COALESCE(SUM(ROW_COUNT), 0),
        LISTAGG(IFF(STATUS != 'Loaded', TABLE_NAME, NULL), ', ')
            WITHIN GROUP (ORDER BY TABLE_NAME)
    INTO :loaded_count, :failed_count, :total_rows, :failed_tables
    FROM {{database_name}}.INFORMATION_SCHEMA.LOAD_HISTORY
    WHERE TABLE_SCHEMA_NAME = 'RDS_LANDING'
      AND LAST_LOAD_TIME >= DATEADD('hours', -24, CURRENT_TIMESTAMP());

    IF (:failed_count = 0) THEN
        notification_msg := '✅ RDS snapshot ingestion complete — '
            || :loaded_count || '/' || (:loaded_count + :failed_count)
            || ' record types loaded · ' || :total_rows
            || ' rows total · Run date: ' || :run_date;
    ELSE
        notification_msg := '⚠️ RDS snapshot ingestion completed with errors — '
            || :loaded_count || '/' || (:loaded_count + :failed_count)
            || ' loaded · ' || :failed_count
            || ' failed: ' || :failed_tables
            || ' — @team-dpe';
    END IF;

    CALL SYSTEM$SEND_SNOWFLAKE_NOTIFICATION(
        SNOWFLAKE.NOTIFICATION.TEXT_PLAIN(:notification_msg),
        SNOWFLAKE.NOTIFICATION.INTEGRATION('RDS_SNAPSHOT_NOTIFICATION_INTEGRATION')
    );

    RETURN :notification_msg;
END;
$$;


-- ============================================================
-- Root task: refreshes stage metadata so COPY INTO tasks see
-- the latest S3 files before any loading begins.
-- Schedule TBD — confirm with Xa when S3 export finishes.
-- ============================================================
CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK
    WAREHOUSE = compute_xsmall
    SCHEDULE = 'USING CRON 0 8 * * * UTC'
AS
    ALTER STAGE IF EXISTS {{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE REFRESH;


-- ============================================================
-- COPY INTO tasks — one per record type, all triggered in
-- parallel after REFRESH_STAGE_TASK completes.
-- ============================================================
CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_ACCESS_APPROVAL_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_access_approval
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*ACCESS_APPROVAL/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_ACL_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_acl
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*[^_]ACL/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_ACL_RESOURCE_ACCESS_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_acl_resource_access
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*ACL_RESOURCE_ACCESS/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_ACL_RESOURCE_ACCESS_TYPE_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_acl_resource_access_type
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*ACL_RESOURCE_ACCESS_TYPE/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_DATA_ACCESS_SUBMISSION_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_data_access_submission
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*DATA_ACCESS_SUBMISSION/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_DATA_ACCESS_SUBMISSION_ACCESSOR_CHANGES_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_data_access_submission_accessor_changes
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*DATA_ACCESS_SUBMISSION_ACCESSOR_CHANGES/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_DATA_ACCESS_SUBMISSION_STATUS_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_data_access_submission_status
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*DATA_ACCESS_SUBMISSION_STATUS/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_DATA_ACCESS_SUBMISSION_SUBMITTER_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_data_access_submission_submitter
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*DATA_ACCESS_SUBMISSION_SUBMITTER/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_DATA_ACCESS_REQUEST_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_data_access_request
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*DATA_ACCESS_REQUEST/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_ACCESS_REQUIREMENT_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_access_requirement
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*ACCESS_REQUIREMENT/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_ACCESS_REQUIREMENT_PROJECT_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_access_requirement_project
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*ACCESS_REQUIREMENT_PROJECT/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_ACCESS_REQUIREMENT_REVISION_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_access_requirement_revision
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*ACCESS_REQUIREMENT_REVISION/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_DATA_ACCESS_NOTIFICATION_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_data_access_notification
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*DATA_ACCESS_NOTIFICATION/.*\.parquet$'
    ON_ERROR = CONTINUE;

CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.COPY_PRINCIPAL_ALIAS_TASK
    WAREHOUSE = compute_xsmall
    AFTER {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK
AS
    COPY INTO {{database_name}}.RDS_LANDING.lan_synapse_principal_alias
    FROM @{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE
    FILE_FORMAT = (TYPE = PARQUET BINARY_AS_TEXT = FALSE)
    PATTERN = '.*PRINCIPAL_ALIAS/.*\.parquet$'
    ON_ERROR = CONTINUE;


-- ============================================================
-- Finalizer task: guaranteed to run whether the graph succeeded
-- or failed. Sends a Slack notification with load stats.
-- ============================================================
CREATE OR REPLACE TASK {{database_name}}.RDS_LANDING.FINALIZER_TASK
    WAREHOUSE = compute_xsmall
    FINALIZE = {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK
AS
    CALL {{database_name}}.RDS_LANDING.FINALIZE_RDS_SNAPSHOT_INGESTION();


-- ============================================================
-- Resume tasks: children must be resumed before the root task.
-- Root task is resumed last to activate the schedule.
-- ============================================================
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
ALTER TASK {{database_name}}.RDS_LANDING.FINALIZER_TASK RESUME;
ALTER TASK {{database_name}}.RDS_LANDING.REFRESH_STAGE_TASK RESUME;
