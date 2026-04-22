-- This dynamic table provides a dashboard view of data access submissions
WITH base AS (
    SELECT
        data_access_submission_id,
        data_access_request_id,
        access_requirement_id,
        access_requirement_version,
        research_project_id,
        created_by,
        created_by_user_name,
        created_on,
        state_modified_by,
        state_modified_by_user_name,
        state_modified_on,
        state,
        submission_type,
        state_reason,
        accessor_changes,
        data_access_submission_raw
    FROM {{ ref('int_synapse_data_access_submission_enriched') }}
),
approval_cycles AS (
    SELECT
        data_access_submission_id,
        COALESCE(
            SUM(CASE WHEN state = 'Approved' THEN 1 ELSE 0 END) 
                OVER (PARTITION BY data_access_request_id ORDER BY created_on ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),
            0
        ) AS approval_cycle
    FROM {{ ref('int_synapse_data_access_submission_enriched') }}
),
attempts AS (
    SELECT
        enriched.data_access_submission_id,
        ROW_NUMBER() OVER (
            PARTITION BY enriched.data_access_request_id, approval_cycles.approval_cycle 
            ORDER BY enriched.created_on
        ) AS attempt
    FROM {{ ref('int_synapse_data_access_submission_enriched') }} enriched
    INNER JOIN approval_cycles 
        ON enriched.data_access_submission_id = approval_cycles.data_access_submission_id
)
SELECT
    base.data_access_submission_id,
    base.data_access_request_id,
    base.access_requirement_id,
    base.access_requirement_version,
    base.research_project_id,
    base.created_by as submitted_by,
    created_by_user_name as submitted_by_user_name,
    base.created_on as submitted_on,
    attempts.attempt,
    base.state as submission_status,
    base.submission_type,
    base.state_modified_by as reviewed_by,
    state_modified_by_user_name as reviewed_by_user_name,
    base.state_modified_on as reviewed_on,
    base.state_reason as submission_status_reason,
    base.accessor_changes,
    ARRAY_SIZE(OBJECT_KEYS(base.accessor_changes)) AS accessor_count,
    base.data_access_submission_raw
FROM base
LEFT JOIN attempts 
    ON base.data_access_submission_id = attempts.data_access_submission_id
