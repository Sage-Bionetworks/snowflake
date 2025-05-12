USE SCHEMA {{database_name}}.synapse_aggregate; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE DYNAMIC TABLE USER_UPLOADS
    (
	    AGG_PERIOD VARCHAR(16777216) COMMENT 'The dimension of the aggregate (e.g., YEARLY, MONTHLY, DAILY). Part of composite PK.',
	    USER_COUNT INT COMMENT 'The number of distinct unique users uploading during the aggregation period.',
	    AGG_YEAR NUMBER(38,0) COMMENT 'Year of the aggregation period.',
        AGG_MONTH NUMBER(38,0) COMMENT 'Month of the aggregation period.',
        AGG_DAY NUMBER(38,0) COMMENT 'Day of the aggregation period.',
        AGG_PERIOD_START DATE COMMENT 'The start date of the aggregation period. Part of composite PK.',
        AGG_PERIOD_END DATE COMMENT 'The stop date of the aggregation period. Part of composite PK.',
        AGG_PERIOD_IS_COMPLETE BOOLEAN COMMENT 'If true, then the aggregation period is complete.'
    )
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    COMMENT = 'This table shows the total number of unique users uploading to Synapse across yearly, monthly, and daily aggregate periods.'
    AS
    WITH unique_users_rollup AS (

        SELECT
            YEAR(record_date)  AS agg_year,
            MONTH(record_date) AS agg_month,
            DAY(record_date)   AS agg_day,
            COUNT(DISTINCT user_id) AS user_count,
            GROUPING(agg_day)   AS g_day,
            GROUPING(agg_month) AS g_month,
            GROUPING(agg_year)  AS g_year
        FROM {{database_name}}.SYNAPSE.FILEUPLOAD --noqa: JJ01,PRS,TMP
        -- exclude today’s partial data to avoid confusion in the final table
        WHERE RECORD_DATE < (SELECT MAX(RECORD_DATE) FROM {{database_name}}.SYNAPSE.FILEUPLOAD) --noqa: JJ01,PRS,TMP
        GROUP BY ROLLUP(agg_year, agg_month, agg_day)

        ),
    unique_users_rollup_with_new_columns AS (

        SELECT

            -- 1. Grab the relevant original columns
            user_count,
            agg_year,
            agg_month,
            agg_day,

            -- 2. Create `granularity` column...
            --    Determine granularity based on which dimensions were rolled up
            CASE
                WHEN g_year  = 0 AND g_month = 1 AND g_day = 1 THEN 'YEARLY'
                WHEN g_year  = 0 AND g_month = 0 AND g_day = 1 THEN 'MONTHLY'
                WHEN g_day   = 0 THEN 'DAILY'
            END AS agg_period,

            -- 3. Create `aggregate_period_start` column
            CASE
                WHEN g_day   = 0 THEN DATE_FROM_PARTS(agg_year, agg_month, agg_day)
                WHEN g_month = 0 THEN DATE_FROM_PARTS(agg_year, agg_month, 1)
                ELSE DATE_FROM_PARTS(agg_year, 1, 1)
            END AS agg_period_start,

            -- 4. Create `aggregate_period_stop` column (inclusive)
            CASE
                WHEN g_day   = 0 THEN DATE_FROM_PARTS(agg_year, agg_month, agg_day)
                WHEN g_month = 0 THEN LAST_DAY(DATE_FROM_PARTS(agg_year, agg_month, 1))
                ELSE LAST_DAY(DATE_FROM_PARTS(agg_year, 1, 1), 'YEAR')
            END AS agg_period_end,

            -- 5 Create `is_complete` column...
            --    Mark complete once today's date is past the stop
            (CURRENT_DATE > 
                CASE
                WHEN g_day   = 0 THEN DATE_FROM_PARTS(agg_year, agg_month, agg_day)
                WHEN g_month = 0 THEN LAST_DAY(DATE_FROM_PARTS(agg_year, agg_month, 1))
                ELSE LAST_DAY(DATE_FROM_PARTS(agg_year, 1, 1), 'YEAR')
                END
            ) AS agg_period_is_complete

        FROM unique_users_rollup)
    SELECT
        agg_period,
        user_count,
        agg_year,
        agg_month,
        agg_day,
        agg_period_start,
        agg_period_end,
        agg_period_is_complete
    FROM unique_users_rollup_with_new_columns
    WHERE agg_year IS NOT NULL -- drop the all-NULL “grand total” row
    ORDER BY agg_day, agg_month, agg_year;
