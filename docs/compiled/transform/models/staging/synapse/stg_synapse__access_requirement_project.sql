with

source as (
    select * from synapse_data_warehouse.rds_raw.access_requirement_project
),

staging as (
    select
        ar_id as access_requirement_id,
        project_id as access_requirement_project
    from
        source
)

select * from staging
