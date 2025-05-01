USE SCHEMA {{database_name}}.synapse_aggregate; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE DYNAMIC TABLE UNIQUE_USER_UPLOADS
    (
	    CHANGE_TYPE VARCHAR(16777216) COMMENT 'The type of change that occurred to the member of team, e.g., CREATE, UPDATE (Snapshotting does not capture DELETE change).',
	    CHANGE_TIMESTAMP TIMESTAMP_NTZ(9) COMMENT 'The time when any change to the team was made (e.g. update of the team or a change to its members).',
	    CHANGE_USER_ID NUMBER(38,0) COMMENT 'The unique identifier of the user who made the change to the team member.',
	    SNAPSHOT_TIMESTAMP TIMESTAMP_NTZ(9) COMMENT 'The time when the snapshot was taken (It is usually after the change happened).',
	    TEAM_ID NUMBER(38,0) COMMENT 'The unique identifier of the team.',
	    MEMBER_ID NUMBER(38,0) COMMENT 'The unique identifier of the member of the team. The member is a Synapse user.',
	    IS_ADMIN BOOLEAN COMMENT 'If true, then the member is manager of the team.',
	    SNAPSHOT_DATE DATE COMMENT 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.'
    )
    TARGET LAG = '1 day'
    WAREHOUSE = compute_xsmall
    COMMENT = ''
    AS
    WITH unique_users_rollup AS (

        SELECT
            YEAR(record_date)  AS aggregate_year,
            MONTH(record_date) AS aggregate_month,
            DAY(record_date)   AS aggregate_day,
            COUNT(DISTINCT user_id) AS unique_user_count,
            GROUPING(day)   AS g_day,
            GROUPING(month) AS g_month,
            GROUPING(year)  AS g_year
        FROM SYNAPSE_DATA_WAREHOUSE.SYNAPSE.FILEUPLOAD
        WHERE RECORD_DATE <= MAX(RECORD_DATE) - 1
        GROUP BY ROLLUP(year, month, day)

        ),
    unique_users_rollup_with_new_columns AS (

        SELECT

            -- 1. Grab the relevant original columns
            unique_user_count,
            aggregate_year,
            aggregate_month,
            aggregate_day,

            -- 2. Create `granularity` column...
            --    Determine granularity based on which dimensions were rolled up
            CASE
                WHEN g_year  = 0 AND g_month = 1 AND g_day = 1 THEN 'YEARLY'
                WHEN g_year  = 0 AND g_month = 0 AND g_day = 1 THEN 'MONTHLY'
                WHEN g_day   = 0 THEN 'DAILY'
            END AS granularity,

            -- 3. Create `aggregate_period_start` column
            CASE
                WHEN g_day   = 0 THEN DATE_FROM_PARTS(aggregate_year, aggregate_month, aggregate_day)
                WHEN g_month = 0 THEN DATE_FROM_PARTS(aggregate_year, aggregate_month, 1)
                ELSE DATE_FROM_PARTS(aggregate_year, 1, 1)
            END AS aggregate_period_start,

            -- 4. Create `snapshot_date` column...
            --    This is when the table was updated
            CURRENT_DATE AS snapshot_date,

            -- 5. Create `aggregate_period_stop` column (inclusive)
            CASE
                WHEN g_day   = 0 THEN DATE_FROM_PARTS(aggregate_year, aggregate_month, aggregate_day)
                WHEN g_month = 0 THEN LAST_DAY(DATE_FROM_PARTS(aggregate_year, aggregate_month, 1))
                ELSE LAST_DAY(DATE_FROM_PARTS(aggregate_year, 1, 1), 'YEAR')
            END AS aggregate_period_stop,

            -- 6. Create `is_complete` column...
            --    Mark complete once today's date is past the stop
            (CURRENT_DATE > 
                CASE
                WHEN g_day   = 0 THEN DATE_FROM_PARTS(aggregate_year, aggregate_month, aggregate_day)
                WHEN g_month = 0 THEN LAST_DAY(DATE_FROM_PARTS(year, month, 1))
                ELSE                   LAST_DAY(DATE_FROM_PARTS(year, 1, 1), 'YEAR')
                END
            ) AS is_complete

        FROM unique_users_rollup)
    SELECT
        granularity,
        unique_user_count,
        year,
        month,
        day,
        aggregate_period_start,
        aggregate_period_stop,
        snapshot_date,
        is_complete
    FROM unique_users_rollup_with_new_columns
    WHERE year IS NOT NULL -- drop the all-NULL “grand total” row
    ORDER BY day, month, year;
