with all_values as (

    select
        access_type as value_field,
        count(*) as n_records

    from synapse_data_warehouse.rds_raw.access_requirement
    group by access_type

)

select *
from all_values
where value_field not in (
    'DOWNLOAD', 'PARTICIPATE'
)
