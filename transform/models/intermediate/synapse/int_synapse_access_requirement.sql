with 

access_requirement_base as (
    select
        *
    from
        {{ ref('stg_synapse__access_requirement') }}
),

access_requirement_revision as (
    select
        *
    from
        {{ ref('stg_synapse__access_requirement_revision') }}
),

access_requirement_project as (
    select
        *
    from
        {{ ref('stg_synapse__access_requirement_project') }}
)

select
    base.access_requirement_id,
    base.access_requirement_name,
    base.access_requirement_type,
    base.created_by,
    base.created_on,
    revision.modified_by,
    revision.modified_on,
    base.access_requirement_current_version,
    base.is_two_fa_required,
    project.project_id,
    base.access_type,
    base.etag,
    revision.access_requirement_raw
from
    access_requirement_base base
left join
    access_requirement_revision revision 
on 
    base.access_requirement_id = revision.access_requirement_id
    AND base.access_requirement_current_version = revision.access_requirement_version
left join
    access_requirement_project project
on
    base.access_requirement_id = project.access_requirement_id
