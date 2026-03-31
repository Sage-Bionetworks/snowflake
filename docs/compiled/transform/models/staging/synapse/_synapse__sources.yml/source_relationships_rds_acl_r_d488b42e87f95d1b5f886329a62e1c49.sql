with child as (
    select owner_id as from_field
    from synapse_data_warehouse.rds_raw.acl_resource_access_type
    where owner_id is not null
),

parent as (
    select id as to_field
    from synapse_data_warehouse.rds_raw.acl
)

select from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null
