with child as (
    select access_requirement_id as from_field
    from synapse_data_warehouse.rds_raw.data_access_submission
    where access_requirement_id is not null
),

parent as (
    select id as to_field
    from synapse_data_warehouse.rds_raw.access_requirement
)

select from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null
