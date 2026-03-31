with

source as (
    select * from synapse_data_warehouse.rds_raw.acl
),

staging as (
    select
        id as acl_id,
        owner_id as object_id,
        owner_type as object_type,
        etag,
        to_timestamp(created_on / 1000) as created_on
    from
        source
)

select * from staging
