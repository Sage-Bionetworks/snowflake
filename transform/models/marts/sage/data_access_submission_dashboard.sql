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
        attempt,
        state_reason,
        accessor_changes,
        data_access_submission_raw
    FROM dynamic_table_refresh_boundary({{ ref('int_synapse_data_access_submission_enriched') }})
),
access_requirements AS (
    SELECT DISTINCT
        access_requirement_id,
        access_requirement_name
    FROM dynamic_table_refresh_boundary({{ ref('int_synapse_access_requirement') }})
)
SELECT
    base.data_access_submission_id,
    base.data_access_request_id,
    base.access_requirement_id,
    access_requirements.access_requirement_name,
    base.access_requirement_version,
    base.research_project_id,
    base.created_by as submitted_by,
    created_by_user_name as submitted_by_user_name,
    base.created_on as submitted_on,
    base.attempt,
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
LEFT JOIN access_requirements
    ON base.access_requirement_id = access_requirements.access_requirement_id
