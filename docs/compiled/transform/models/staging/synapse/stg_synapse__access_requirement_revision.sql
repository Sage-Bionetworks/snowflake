with

source as (
    select * from synapse_data_warehouse.rds_raw.access_requirement_revision
),

staging as (
    select
        owner_id as access_requirement_id,
        number as access_requirement_version,
        modified_by,
        serialized_entity as access_requirement_raw,
        to_timestamp(modified_on / 1000) as modified_on
    from
        source
)

select * from staging
