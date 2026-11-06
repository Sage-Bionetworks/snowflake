{{ config(enabled=var('enable_accessrequirement_rds_prototype', target.name == 'clone')) }}

select
    base.access_requirement_id,
    base.access_requirement_current_version
from {{ ref('stg_synapse__access_requirement') }} as base
left join {{ ref('int_synapse_access_requirement') }} as revision
    on base.access_requirement_id = revision.access_requirement_id
    and base.access_requirement_current_version = revision.access_requirement_version
where revision.access_requirement_id is null
