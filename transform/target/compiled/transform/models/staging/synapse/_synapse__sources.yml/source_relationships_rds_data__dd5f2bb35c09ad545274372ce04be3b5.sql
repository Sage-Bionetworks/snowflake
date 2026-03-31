with child as (
    select data_access_request_id as from_field
    from synapse_data_warehouse.rds_raw.data_access_submission
    where data_access_request_id is not null
),

parent as (
    select id as to_field
    from synapse_data_warehouse.rds_raw.data_access_request
)

select from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null
