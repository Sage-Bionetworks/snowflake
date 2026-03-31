with all_values as (

    select
        type as value_field,
        count(*) as n_records

    from synapse_data_warehouse.rds_raw.principal_alias
    group by type

)

select *
from all_values
where value_field not in (
    'USER_NAME', 'TEAM_NAME', 'USER_EMAIL', 'USER_OPEN_ID', 'USER_ORCID'
)
