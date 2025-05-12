USE SCHEMA {{database_name}}.synapse_aggregate; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE DYNAMIC TABLE UNIQUE_USER_UPLOADS
    (
	    GRANULARITY VARCHAR(16777216) COMMENT 'The dimension of the aggregate (e.g., YEARLY, MONTHLY, DAILY).',
	    UNIQUE_USER_COUNT INT COMMENT 'The number of distinct unique users uploading during the aggregation period.',
	    YEAR NUMBER(38,0) COMMENT 'Year of the aggregation period.',
        MONTH NUMBER(38,0) COMMENT 'Month of the aggregation period.',
        DAY NUMBER(38,0) COMMENT 'Day of the aggregation period.',
        AGGREGATE_PERIOD_START DATE PRIMARY KEY COMMENT 'The time when any change to the team was made (e.g. update of the team or a change to its members).',
        AGGREGATE_PERIOD_STOP DATE PRIMARY KEY COMMENT 'The time when any change to the team was made (e.g. update of the team or a change to its members).',
	    SNAPSHOT_DATE DATE COMMENT 'Date the aggregation was calculated and stored in the table.',
        IS_COMPLETE BOOLEAN COMMENT 'If true, then the aggregation period is complete.',
        CONSTRAINT UNIQUE_USER_UPLOADS_PK PRIMARY KEY (GRANULARITY, AGGREGATE_PERIOD_START, AGGREGATE_PERIOD_STOP)
    )
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    COMMENT = 'This table shows the total number of unique users uploading to Synapse across yearly, monthly, and daily aggregate periods.'
    AS
    WITH unique_users_rollup AS (

        SELECT
            YEAR(record_date)  AS year,
            MONTH(record_date) AS month,
            DAY(record_date)   AS day,
            COUNT(DISTINCT user_id) AS unique_user_count,
            GROUPING(day)   AS g_day,
            GROUPING(month) AS g_month,
            GROUPING(year)  AS g_year
        FROM {{database_name}}.SYNAPSE.FILEUPLOAD --noqa: JJ01,PRS,TMP
        -- exclude today’s partial data to avoid confusion in the final table
        WHERE RECORD_DATE < (SELECT MAX(RECORD_DATE) FROM {{database_name}}.SYNAPSE.FILEUPLOAD) --noqa: JJ01,PRS,TMP
        GROUP BY ROLLUP(year, month, day)

        ),
    unique_users_rollup_with_new_columns AS (

        SELECT

            -- 1. Grab the relevant original columns
            unique_user_count,
            year,
            month,
            day,

            -- 2. Create `granularity` column...
            --    Determine granularity based on which dimensions were rolled up
            CASE
                WHEN g_year  = 0 AND g_month = 1 AND g_day = 1 THEN 'YEARLY'
                WHEN g_year  = 0 AND g_month = 0 AND g_day = 1 THEN 'MONTHLY'
                WHEN g_day   = 0 THEN 'DAILY'
            END AS granularity,

            -- 3. Create `aggregate_period_start` column
            CASE
                WHEN g_day   = 0 THEN DATE_FROM_PARTS(year, month, day)
                WHEN g_month = 0 THEN DATE_FROM_PARTS(year, month, 1)
                ELSE DATE_FROM_PARTS(year, 1, 1)
            END AS aggregate_period_start,

            -- 4. Create `snapshot_date` column...
            --    This is when the table was updated
            CURRENT_DATE AS snapshot_date,

            -- 5. Create `aggregate_period_stop` column (inclusive)
            CASE
                WHEN g_day   = 0 THEN DATE_FROM_PARTS(year, month, day)
                WHEN g_month = 0 THEN LAST_DAY(DATE_FROM_PARTS(year, month, 1))
                ELSE LAST_DAY(DATE_FROM_PARTS(year, 1, 1), 'YEAR')
            END AS aggregate_period_stop,

            -- 6. Create `is_complete` column...
            --    Mark complete once today's date is past the stop
            (CURRENT_DATE > 
                CASE
                WHEN g_day   = 0 THEN DATE_FROM_PARTS(year, month, day)
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
