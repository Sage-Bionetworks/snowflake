USE SCHEMA {{database_name}}.synapse_aggregate; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE DYNAMIC TABLE USER_UPLOADS
    (
	    AGG_PERIOD VARCHAR(16777216) COMMENT 'The dimension of the aggregate (e.g., YEARLY, MONTHLY, DAILY). Part of composite PK.',
	    USER_COUNT INT COMMENT 'The number of distinct unique users uploading during the aggregation period.',
	    AGG_YEAR NUMBER(38,0) COMMENT 'Year of the aggregation period.',
        AGG_QUARTER NUMBER(38,0) COMMENT 'Quarter of the aggregation period.',
        AGG_MONTH NUMBER(38,0) COMMENT 'Month of the aggregation period.',
        AGG_DAY NUMBER(38,0) COMMENT 'Day of the aggregation period.',
        AGG_PERIOD_START DATE COMMENT 'The start date of the aggregation period. Part of composite PK.',
        AGG_PERIOD_END DATE COMMENT 'The stop date of the aggregation period. Part of composite PK.',
        AGG_PERIOD_IS_COMPLETE BOOLEAN COMMENT 'If true, then the aggregation period is complete.'
    )
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    COMMENT = 'This table shows the total number of unique users uploading to Synapse across yearly, quarterly, monthly, and daily aggregate periods.'
    AS
    -- Step 1: Compute the aggregate user count and extract the aggregate dimensions
    WITH user_count_rollup AS (

        SELECT
            -- Extracting our aggregate dimensions from ``record_date`` column
            YEAR(record_date)  AS agg_year,
            CEIL(MONTH(record_date) / 3) AS agg_quarter,
            MONTH(record_date) AS agg_month,
            DAY(record_date)   AS agg_day,

            -- Computing our aggregate
            COUNT(DISTINCT user_id) AS user_count,

            -- Use GROUPING to determine which dimensions were rolled up for each row 
            GROUPING(agg_day)   AS g_day,
            GROUPING(agg_month) AS g_month,
            GROUPING(agg_quarter) AS g_quarter,
            GROUPING(agg_year)  AS g_year
        FROM {{database_name}}.SYNAPSE.FILEUPLOAD --noqa: JJ01,PRS,TMP
        -- exclude today’s partial data to avoid confusion in the final table
        WHERE RECORD_DATE < (SELECT MAX(RECORD_DATE) FROM {{database_name}}.SYNAPSE.FILEUPLOAD) --noqa: JJ01,PRS,TMP
        GROUP BY ROLLUP(agg_year, agg_quarter, agg_month, agg_day)

        ),
    -- Step 2: Determine the aggregate period (grain) and start and end dates
    agg_period_calculations AS (

        SELECT

            -- 1. Grab the relevant original columns
            user_count,
            agg_year,
            agg_quarter,
            agg_month,
            agg_day,

            -- 2. Create `agg_period` column...
            --    Determine granularity based on which dimensions were rolled up
            CASE
                WHEN g_year = 0 AND g_quarter = 1 AND g_month = 1 AND g_day = 1 THEN 'YEARLY'
                WHEN g_year = 0 AND g_quarter = 0 AND g_month = 1 AND g_day = 1 THEN 'QUARTERLY'
                WHEN g_year = 0 AND g_quarter = 0 AND g_month = 0 AND g_day = 1 THEN 'MONTHLY'
                WHEN g_day = 0 THEN 'DAILY'
            END AS agg_period,

            -- 3. Create `agg_period_start` column
            CASE
                -- First day of the year
                WHEN g_year = 0 AND g_quarter = 1 AND g_month = 1 AND g_day = 1 THEN DATE_FROM_PARTS(agg_year, 1, 1)
                -- First day of the quarter
                WHEN g_year = 0 AND g_quarter = 0 AND g_month = 1 AND g_day = 1 THEN DATE_FROM_PARTS(agg_year, (agg_quarter * 3) - 2, 1)
                -- First day of the month
                WHEN g_year = 0 AND g_quarter = 0 AND g_month = 0 AND g_day = 1 THEN DATE_FROM_PARTS(agg_year, agg_month, 1)
                -- Date
                WHEN g_day = 0 THEN DATE_FROM_PARTS(agg_year, agg_month, agg_day)
            END AS agg_period_start,

            -- 4. Create `agg_period_end` column (inclusive)
            CASE
                -- Last day of the year
                WHEN g_year = 0 AND g_quarter = 1 AND g_month = 1 AND g_day = 1 THEN LAST_DAY(DATE_FROM_PARTS(agg_year, 1, 1), 'YEAR')
                -- Last day of the quarter
                WHEN g_year = 0 AND g_quarter = 0 AND g_month = 1 AND g_day = 1 THEN LAST_DAY(DATE_FROM_PARTS(agg_year, agg_quarter * 3, 1))
                -- Last day of the month
                WHEN g_year = 0 AND g_quarter = 0 AND g_month = 0 AND g_day = 1 THEN LAST_DAY(DATE_FROM_PARTS(agg_year, agg_month, 1))
                -- Date
                WHEN g_day = 0 THEN DATE_FROM_PARTS(agg_year, agg_month, agg_day)
            END AS agg_period_end

        FROM user_count_rollup)
    -- Step 3: Compose the final table by ordering the columns for easier reading and adding the completion column
    SELECT
        agg_period,
        user_count,
        agg_year,
        agg_quarter,
        agg_month,
        agg_day,
        agg_period_start,
        agg_period_end,
    
        -- 5. Mark the period as complete once today's date is past the stop
        (CURRENT_DATE > agg_period_end) AS agg_period_is_complete

    FROM agg_period_calculations
    WHERE agg_year is NOT NULL -- drop the all-NULL “grand total” row
    ORDER BY
        -- 1) current year first, then past years
        agg_year DESC,

        -- 2) display year, then quarter, then month, then day.
        --    conveniently, the grain names for agg_period are in alphabetical order
        agg_period DESC,

        -- 3) within each grain, sort by the natural dimension
        COALESCE(agg_quarter, 0),
        COALESCE(agg_month, 0),
        COALESCE(agg_day, 0);