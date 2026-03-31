with child as (
    select access_approval_id as from_field
    from synapse_data_warehouse.rds_raw.data_access_notification
    where access_approval_id is not null
),

parent as (
    select id as to_field
    from synapse_data_warehouse.rds_raw.access_approval
)

select from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null
