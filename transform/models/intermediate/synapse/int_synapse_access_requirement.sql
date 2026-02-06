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

access_requirement_created as (
    select
        access_requirement_id,
        modified_by as created_by,
        modified_on as created_on
    from
        access_requirement_revision
    where
        access_requirement_version = 0
)

select
    base.access_requirement_id,
    revision.access_requirement_version,
    base.access_requirement_name,
    base.access_requirement_type,
    created.created_by,
    created.created_on,
    revision.modified_by,
    revision.modified_on,
    -- This property can be modified between revisions
    case 
        when base.access_requirement_current_version = revision.access_requirement_version 
        then base.is_two_fa_required 
        else null 
    end as is_two_fa_required,
    base.access_type,
    revision.access_requirement_raw
from
    access_requirement_base base
inner join
    access_requirement_created created
on
    base.access_requirement_id = created.access_requirement_id
inner join
    access_requirement_revision revision
on 
    base.access_requirement_id = revision.access_requirement_id