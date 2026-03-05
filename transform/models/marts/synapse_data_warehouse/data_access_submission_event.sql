select
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
    state_reason,
    accessor_changes,
    data_access_submission_raw
from
    {{ ref('int_synapse_data_access_submission_enriched') }}