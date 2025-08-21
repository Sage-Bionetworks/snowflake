USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

create or replace dynamic table VERIFICATIONSUBMISSION_LATEST(
	CHANGE_TIMESTAMP COMMENT 'The time when the change (created/updated) on a submission is pushed to the queue for snapshotting.',
	CHANGE_TYPE COMMENT 'The type of change that occurred on the submission, e.g., CREATE, UPDATE.',
	SNAPSHOT_TIMESTAMP COMMENT 'The time when the snapshot was taken (It is usually after the change happened).',
	ID COMMENT 'The unique identifier of the submission.',
	CREATED_ON COMMENT 'The creation time of the submission.',
	CREATED_BY COMMENT 'The unique identifier of the user who created the submission.',
	STATE_HISTORY COMMENT 'The sequence of submission states (SUBMITTED, REJECTED, APPROVED) for the submission.',
	SNAPSHOT_DATE COMMENT 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.'
) target_lag = '1 day' refresh_mode = AUTO initialize = ON_CREATE warehouse = COMPUTE_XSMALL
 COMMENT='This dynamic table, indexed by ID, contains the latest snapshot of user verification submissions by ACT. It is derived from VERIFICATIONSUBMISSIONSNAPSHOTS raw data and provides deduplicated verification submission information. The table is refreshed daily and contains only the most recent submission entries for each ID from the past 14 days. Each row represents a specific verification submission with its current state and history.'
 as
    -- We deduplicate simply by selecting the latest record for each
    -- verification submission ID...
    WITH latest_unique_rows AS (
        SELECT
            verificationsubmissionsnapshots.*,
        FROM
            {{database_name}}.synapse_raw.verificationsubmissionsnapshots --noqa: TMP
        WHERE
            SNAPSHOT_DATE >= CURRENT_DATE - INTERVAL '14 DAYS'
        QUALIFY ROW_NUMBER() OVER (
                PARTITION BY id
                ORDER BY change_timestamp DESC, snapshot_timestamp DESC
            ) = 1
    )
    SELECT
        *
    FROM
        latest_unique_rows
    ORDER BY
        latest_unique_rows.id ASC;