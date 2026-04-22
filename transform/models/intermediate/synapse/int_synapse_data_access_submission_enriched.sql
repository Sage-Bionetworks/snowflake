-- This dynamic table contains all data access submissions and their associated state.
-- It has been enriched with data from other models which are merely associated 
-- with submission data, such as `principal_alias` (user profile) data.
WITH base AS (
    SELECT
        data_access_submission_id,
        data_access_request_id,
        access_requirement_id,
        access_requirement_version,
        research_project_id,
        created_by,
        created_on,
        state_modified_by,
        state_modified_on,
        state,
        state_reason,
        accessor_changes,
        data_access_submission_raw
    FROM {{ ref('int_synapse_data_access_submission') }}
),
submission_types AS (
    SELECT
        data_access_submission_id,
        CASE
            WHEN submission_sequence = 1 THEN 'New'
            WHEN most_recent_previously_approved_state_modified_on IS NULL THEN 'New'
            WHEN DATEDIFF(
                month,
                most_recent_previously_approved_state_modified_on,
                created_on
            ) < 10 THEN 'Update'
            ELSE 'Annual Renewal'
        END AS submission_type
    FROM (
        SELECT
            data_access_submission_id,
            created_on,
            ROW_NUMBER() OVER (
                PARTITION BY data_access_request_id
                ORDER BY created_on, data_access_submission_id
            ) AS submission_sequence,
            MAX(CASE WHEN state = 'Approved' THEN state_modified_on END) OVER (
                PARTITION BY data_access_request_id
                ORDER BY created_on, data_access_submission_id
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ) AS most_recent_previously_approved_state_modified_on
        FROM base
    ) base
),
principal_usernames AS (
    SELECT
        principal_id,
        alias_display
    FROM {{ ref('stg_synapse__principal_alias') }}
    WHERE alias_type = 'USER_NAME'
)
SELECT
    base.data_access_submission_id,
    base.data_access_request_id,
    base.access_requirement_id,
    base.access_requirement_version,
    base.research_project_id,
    base.created_by,
    pa_created.alias_display AS created_by_user_name,
    base.created_on,
    base.state_modified_by,
    pa_modified.alias_display AS state_modified_by_user_name,
    base.state_modified_on,
    base.state,
    submission_types.submission_type,
    base.state_reason,
    base.accessor_changes,
    base.data_access_submission_raw
FROM base
LEFT JOIN submission_types
    ON base.data_access_submission_id = submission_types.data_access_submission_id
LEFT JOIN principal_usernames pa_created
    ON base.created_by = pa_created.principal_id
LEFT JOIN principal_usernames pa_modified
    ON base.state_modified_by = pa_modified.principal_id