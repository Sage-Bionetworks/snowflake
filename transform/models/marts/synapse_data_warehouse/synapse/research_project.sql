select
    research_project_id,
    access_requirement_id,
    access_requirement_name,
    created_by,
    created_by_user_name,
    created_on,
    modified_by,
    modified_by_user_name,
    modified_on,
    etag,
    project_lead,
    institution,
    intended_data_use
from
    dynamic_table_refresh_boundary({{ ref('int_synapse_research_project') }})
