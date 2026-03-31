with all_values as (

    select
        owner_type as value_field,
        count(*) as n_records

    from synapse_data_warehouse.rds_raw.acl
    group by owner_type

)

select *
from all_values
where value_field not in (
    'ENTITY', 'EVALUATION', 'TEAM', 'FORM_GROUP', 'ORGANIZATION', 'ACCESS_REQUIREMENT', 'PORTAL', 'OAUTH_CLIENT'
)
