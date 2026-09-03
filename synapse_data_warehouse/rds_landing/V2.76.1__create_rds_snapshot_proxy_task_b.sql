USE SCHEMA {{database_name}}.RDS_LANDING; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE TASK PROXY_TASK_B
    COMMENT = 'No-op intermediary task. Snowflake limits a single node to 100 child tasks; this proxy fans out to the remaining COPY INTO tasks that do not fit under PROXY_TASK_A.'
    AFTER REFRESH_RDS_SNAPSHOTS_STAGE_TASK
AS
    SELECT 1;
