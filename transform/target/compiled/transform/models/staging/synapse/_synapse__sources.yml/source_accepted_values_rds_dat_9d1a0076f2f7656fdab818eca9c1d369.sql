with all_values as (

    select
        state as value_field,
        count(*) as n_records

    from synapse_data_warehouse.rds_raw.data_access_submission_status
    group by state

)

select *
from all_values
where value_field not in (
    'SUBMITTED', 'APPROVED', 'REJECTED', 'CANCELLED'
)
