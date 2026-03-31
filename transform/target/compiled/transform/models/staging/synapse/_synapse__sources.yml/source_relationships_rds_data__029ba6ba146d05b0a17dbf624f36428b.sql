with child as (
    select current_submission_id as from_field
    from synapse_data_warehouse.rds_raw.data_access_submission_submitter
    where current_submission_id is not null
),

parent as (
    select id as to_field
    from synapse_data_warehouse.rds_raw.data_access_submission
)

select from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null
