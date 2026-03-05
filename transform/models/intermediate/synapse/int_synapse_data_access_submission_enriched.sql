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
created_by_names AS (
    SELECT
        base.data_access_submission_id,
        principal_alias.alias_display AS created_by_user_name
    FROM base 
    LEFT JOIN {{ ref('stg_synapse__principal_alias') }} principal_alias
        ON base.created_by = principal_alias.principal_id
    where principal_alias.alias_type = 'USER_NAME'
),
state_modified_by_names AS (
    SELECT
        base.data_access_submission_id,
        principal_alias.alias_display AS state_modified_by_user_name
    FROM base 
    LEFT JOIN {{ ref('stg_synapse__principal_alias') }} principal_alias
        ON base.state_modified_by = principal_alias.principal_id
    where principal_alias.alias_type = 'USER_NAME'
)
SELECT
    base.data_access_submission_id,
    base.data_access_request_id,
    base.access_requirement_id,
    base.access_requirement_version,
    base.research_project_id,
    base.created_by,
    created_by_names.created_by_user_name,
    base.created_on,
    base.state_modified_by,
    state_modified_by_names.state_modified_by_user_name,
    base.state_modified_on,
    base.state,
    base.state_reason,
    base.accessor_changes,
    base.data_access_submission_raw
FROM base
LEFT JOIN created_by_names 
    ON base.data_access_submission_id = created_by_names.data_access_submission_id
LEFT JOIN state_modified_by_names 
    ON base.data_access_submission_id = state_modified_by_names.data_access_submission_id