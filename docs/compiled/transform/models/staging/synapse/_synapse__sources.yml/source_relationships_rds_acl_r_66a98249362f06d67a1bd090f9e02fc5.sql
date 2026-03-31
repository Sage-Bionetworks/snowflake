with child as (
    select id_oid as from_field
    from synapse_data_warehouse.rds_raw.acl_resource_access_type
    where id_oid is not null
),

parent as (
    select id as to_field
    from synapse_data_warehouse.rds_raw.acl_resource_access
)

select from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null
