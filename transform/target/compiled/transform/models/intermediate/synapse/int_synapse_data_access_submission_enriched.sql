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
    FROM synapse_data_warehouse.synapse.int_synapse_data_access_submission
),

principal_usernames AS (
    SELECT
        principal_id,
        alias_display
    FROM synapse_data_warehouse.synapse.stg_synapse__principal_alias
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
    base.state_reason,
    base.accessor_changes,
    base.data_access_submission_raw
FROM base
LEFT JOIN principal_usernames AS pa_created
    ON base.created_by = pa_created.principal_id
LEFT JOIN principal_usernames AS pa_modified
    ON base.state_modified_by = pa_modified.principal_id
