select
    data_access_submission_id,
    accessor_id,
    accessor_change_type,
    access_requirement_id,
    access_requirement_version_reviewed_against as access_requirement_version,
    state_modified_on as change_established_on,
    access_expires_on
from
    dynamic_table_refresh_boundary({{ ref('int_synapse_accessor_changes') }})
where
    state = 'Approved'
