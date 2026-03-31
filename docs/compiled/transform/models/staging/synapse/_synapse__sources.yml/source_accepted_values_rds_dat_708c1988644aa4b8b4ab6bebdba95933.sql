with all_values as (

    select
        notification_type as value_field,
        count(*) as n_records

    from synapse_data_warehouse.rds_raw.data_access_notification
    group by notification_type

)

select *
from all_values
where value_field not in (
    'FIRST_RENEWAL_REMINDER', 'SECOND_RENEWAL_REMINDER', 'REVOCATION'
)
