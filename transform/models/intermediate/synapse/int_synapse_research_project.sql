with

research_project as (
    select * from {{ ref('stg_synapse__research_project') }}
),

access_requirement as (
    select
        access_requirement_id,
        access_requirement_name
    from {{ ref('stg_synapse__access_requirement') }}
),

principal_usernames as (
    select
        principal_id,
        alias_display
    from {{ ref('stg_synapse__principal_alias') }}
    where alias_type = 'USER_NAME'
)

select
    research_project.research_project_id,
    research_project.access_requirement_id,
    access_requirement.access_requirement_name,
    research_project.created_by,
    creator.alias_display as created_by_user_name,
    research_project.created_on,
    research_project.modified_by,
    modifier.alias_display as modified_by_user_name,
    research_project.modified_on,
    research_project.etag,
    research_project.project_lead,
    research_project.institution,
    research_project.intended_data_use
from research_project
left join access_requirement
    on research_project.access_requirement_id = access_requirement.access_requirement_id
left join principal_usernames as creator
    on research_project.created_by = creator.principal_id
left join principal_usernames as modifier
    on research_project.modified_by = modifier.principal_id
