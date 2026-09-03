-- This dynamic table provides period- and access-requirement-scoped rollups of data access
-- submission volume, approval outcomes, attempt distribution, and review latency. All metrics
-- are grain-additive (raw counts/sums, never percentages or averages) so any downstream ratio
-- can be correctly recomputed across any combination of periods an analyst chooses.
WITH base AS (
    SELECT
        access_requirement_id,
        created_on,
        state,
        attempt,
        state_modified_on
    FROM dynamic_table_refresh_boundary({{ ref('int_synapse_data_access_submission_enriched') }})
),

submission_rollup AS (
    SELECT
        YEAR(created_on)    AS agg_year,
        QUARTER(created_on) AS agg_quarter,
        MONTH(created_on)   AS agg_month,
        DAY(created_on)     AS agg_day,

        -- Use GROUPING to determine which time dimensions were rolled up for each row
        GROUPING(agg_day)     AS g_day,
        GROUPING(agg_month)   AS g_month,
        GROUPING(agg_quarter) AS g_quarter,
        GROUPING(agg_year)    AS g_year,

        access_requirement_id,

        -- Cancelled submissions are excluded from "received" so this lines up with
        -- the attempt buckets below (attempt is NULL for Cancelled per SNOW-526)
        COUNT(CASE WHEN state != 'Cancelled' THEN 1 END) AS total_received_count,
        COUNT(CASE WHEN state = 'Cancelled' THEN 1 END) AS total_cancelled_count,
        COUNT(CASE WHEN state = 'Approved' THEN 1 END) AS total_approved_count,
        COUNT(CASE WHEN state = 'Rejected' THEN 1 END) AS total_rejected_count,

        COUNT(CASE WHEN attempt = 1 THEN 1 END) AS attempt_1_count,
        COUNT(CASE WHEN attempt = 2 THEN 1 END) AS attempt_2_count,
        COUNT(CASE WHEN attempt >= 3 THEN 1 END) AS attempt_3_plus_count,
        MAX(attempt) AS highest_attempt,

        -- "Reviewed" means a terminal review decision was reached (Approved/Rejected);
        -- Submitted has no outcome yet, Cancelled was withdrawn before a decision
        COUNT(CASE WHEN state IN ('Approved', 'Rejected') THEN 1 END) AS reviewed_count,
        SUM(CASE
            WHEN state IN ('Approved', 'Rejected')
                THEN DATEDIFF(day, created_on, state_modified_on)
        END) AS sum_days_to_review
    FROM base
    GROUP BY
        ROLLUP(agg_year, agg_quarter, agg_month, agg_day),
        access_requirement_id
),

agg_period_calculations AS (
    SELECT
        access_requirement_id,
        agg_year,
        agg_quarter,
        agg_month,
        agg_day,

        -- Determine granularity based on which time dimensions were rolled up
        CASE
            WHEN g_year = 1 AND g_quarter = 1 AND g_month = 1 AND g_day = 1 THEN 'ALL TIME'
            WHEN g_year = 0 AND g_quarter = 1 AND g_month = 1 AND g_day = 1 THEN 'YEARLY'
            WHEN g_year = 0 AND g_quarter = 0 AND g_month = 1 AND g_day = 1 THEN 'QUARTERLY'
            WHEN g_year = 0 AND g_quarter = 0 AND g_month = 0 AND g_day = 1 THEN 'MONTHLY'
            WHEN g_day = 0 THEN 'DAILY'
        END AS agg_period,

        CASE
            WHEN g_year = 0 AND g_quarter = 1 AND g_month = 1 AND g_day = 1 THEN DATE_FROM_PARTS(agg_year, 1, 1)
            WHEN g_year = 0 AND g_quarter = 0 AND g_month = 1 AND g_day = 1 THEN DATE_FROM_PARTS(agg_year, (agg_quarter * 3) - 2, 1)
            WHEN g_year = 0 AND g_quarter = 0 AND g_month = 0 AND g_day = 1 THEN DATE_FROM_PARTS(agg_year, agg_month, 1)
            WHEN g_day = 0 THEN DATE_FROM_PARTS(agg_year, agg_month, agg_day)
        END AS agg_period_start,

        CASE
            WHEN g_year = 0 AND g_quarter = 1 AND g_month = 1 AND g_day = 1 THEN LAST_DAY(DATE_FROM_PARTS(agg_year, 1, 1), 'YEAR')
            WHEN g_year = 0 AND g_quarter = 0 AND g_month = 1 AND g_day = 1 THEN LAST_DAY(DATE_FROM_PARTS(agg_year, agg_quarter * 3, 1))
            WHEN g_year = 0 AND g_quarter = 0 AND g_month = 0 AND g_day = 1 THEN LAST_DAY(DATE_FROM_PARTS(agg_year, agg_month, 1))
            WHEN g_day = 0 THEN DATE_FROM_PARTS(agg_year, agg_month, agg_day)
        END AS agg_period_end,

        total_received_count,
        total_cancelled_count,
        total_approved_count,
        total_rejected_count,
        attempt_1_count,
        attempt_2_count,
        attempt_3_plus_count,
        highest_attempt,
        reviewed_count,
        sum_days_to_review
    FROM submission_rollup
)

SELECT
    agg_period,
    agg_year,
    agg_quarter,
    agg_month,
    agg_day,
    access_requirement_id AS agg_access_requirement_id,
    agg_period_start,
    agg_period_end,
    -- ALL TIME has no fixed end (agg_period_end is NULL), and by definition never stops
    -- accumulating new submissions, so it's always incomplete rather than unknown
    COALESCE(CURRENT_DATE > agg_period_end, FALSE) AS agg_period_is_complete,

    -- Surrogate PK covering the full grain; the natural key columns above are
    -- legitimately NULL for rolled-up time grains, so they can't serve as a PK directly
    MD5(CONCAT_WS('~',
        agg_period,
        COALESCE(TO_VARCHAR(agg_year), '_'), COALESCE(TO_VARCHAR(agg_quarter), '_'),
        COALESCE(TO_VARCHAR(agg_month), '_'), COALESCE(TO_VARCHAR(agg_day), '_'),
        TO_VARCHAR(access_requirement_id)
    )) AS agg_row_id,

    total_received_count,
    total_cancelled_count,
    total_approved_count,
    total_rejected_count,
    attempt_1_count,
    attempt_2_count,
    attempt_3_plus_count,
    highest_attempt,
    reviewed_count,
    sum_days_to_review
FROM agg_period_calculations
ORDER BY agg_year, agg_month, agg_day, agg_access_requirement_id
