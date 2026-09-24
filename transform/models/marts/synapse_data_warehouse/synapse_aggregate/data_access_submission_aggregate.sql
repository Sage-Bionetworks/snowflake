-- This dynamic table provides period- and access-requirement-scoped rollups of data access
-- submission volume, review outcomes, and review latency. All metrics are grain-additive
-- (raw counts/sums, never percentages or averages) so any downstream ratio can be correctly
-- recomputed across any combination of periods an analyst chooses.
--
-- Every metric is dated by the event that produced it rather than by the submission's
-- creation date. A submission received in March and approved in June increments March's
-- `received_count` and June's `approved_count`. This is what makes a closed period's row
-- immutable: nothing that happens later can change a metric attributed to an earlier date.
-- The tradeoff is that a single row no longer describes one population — see the model's
-- YAML description before computing ratios across columns.
WITH submissions AS (
    SELECT
        access_requirement_id,
        created_on,
        state,
        attempt,
        state_modified_on
    FROM dynamic_table_refresh_boundary({{ ref('int_synapse_data_access_submission_enriched') }})
),

-- Unpivot each submission into its lifecycle events: one RECEIVED event for every
-- submission, plus one terminal event for those that have reached a terminal state.
-- Submissions still in 'Submitted' emit RECEIVED only, and pick up their terminal event
-- on a later refresh once they are reviewed or withdrawn.
lifecycle_event AS (
    SELECT
        access_requirement_id,
        'RECEIVED' AS event_type,
        created_on AS event_on,
        CAST(NULL AS NUMBER) AS attempt,
        CAST(NULL AS NUMBER) AS days_to_review,
        CAST(NULL AS NUMBER) AS attempts_to_approval
    FROM submissions

    UNION ALL

    SELECT
        access_requirement_id,
        UPPER(state) AS event_type,
        state_modified_on AS event_on,
        attempt,
        -- Latency is only meaningful for a review decision; a cancellation is not a review
        CASE
            WHEN state IN ('Approved', 'Rejected')
                THEN DATEDIFF(day, created_on, state_modified_on)
        END AS days_to_review,
        -- `attempt` is the submission's ordinal within its approval cycle, and an approved
        -- submission is always the last of its cycle, so for an approval this is the total
        -- number of attempts that cycle took to succeed
        CASE WHEN state = 'Approved' THEN attempt END AS attempts_to_approval
    FROM submissions
    WHERE state IN ('Approved', 'Rejected', 'Cancelled')
),

event_rollup AS (
    SELECT
        YEAR(event_on)    AS agg_year,
        QUARTER(event_on) AS agg_quarter,
        MONTH(event_on)   AS agg_month,
        DAY(event_on)     AS agg_day,

        -- Use GROUPING to determine which time dimensions were rolled up for each row
        GROUPING(agg_day)     AS g_day,
        GROUPING(agg_month)   AS g_month,
        GROUPING(agg_quarter) AS g_quarter,
        GROUPING(agg_year)    AS g_year,

        access_requirement_id,

        COUNT(CASE WHEN event_type = 'RECEIVED' THEN 1 END) AS received_count,
        COUNT(CASE WHEN event_type = 'CANCELLED' THEN 1 END) AS cancelled_count,
        COUNT(CASE WHEN event_type = 'APPROVED' THEN 1 END) AS approved_count,
        COUNT(CASE WHEN event_type = 'REJECTED' THEN 1 END) AS rejected_count,

        -- "Reviewed" means a review decision was reached (Approved/Rejected);
        -- Cancelled was withdrawn before a decision, so it is neither a review nor an attempt (by convention)
        COUNT(CASE WHEN event_type IN ('APPROVED', 'REJECTED') THEN 1 END) AS reviewed_count,
        SUM(days_to_review) AS sum_days_to_review,
        SUM(attempts_to_approval) AS sum_attempts_to_approval,
        MAX(attempt) AS max_attempt
    FROM lifecycle_event
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

        received_count,
        cancelled_count,
        approved_count,
        rejected_count,
        reviewed_count,
        sum_days_to_review,
        sum_attempts_to_approval,
        max_attempt
    FROM event_rollup
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
    -- accumulating new events, so it's always incomplete rather than unknown
    COALESCE(CURRENT_DATE > agg_period_end, FALSE) AS agg_period_is_complete,

    -- Surrogate PK covering the full grain; the natural key columns above are
    -- legitimately NULL for rolled-up time grains, so they can't serve as a PK directly
    MD5(CONCAT_WS('~',
        agg_period,
        COALESCE(TO_VARCHAR(agg_year), '_'), COALESCE(TO_VARCHAR(agg_quarter), '_'),
        COALESCE(TO_VARCHAR(agg_month), '_'), COALESCE(TO_VARCHAR(agg_day), '_'),
        TO_VARCHAR(access_requirement_id)
    )) AS agg_row_id,

    received_count,
    cancelled_count,
    approved_count,
    rejected_count,
    reviewed_count,
    sum_days_to_review,
    sum_attempts_to_approval,
    max_attempt
FROM agg_period_calculations
ORDER BY agg_year, agg_month, agg_day, agg_access_requirement_id
