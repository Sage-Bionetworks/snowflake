with

source as (
    select * from synapse_data_warehouse.rds_raw.access_approval
),

staging as (
    select
        id as access_requirement_approval_id,
        requirement_id as access_requirement_id,
        requirement_version as access_requirement_version,
        created_by,
        modified_by,
        submitter_id,
        accessor_id,
        state,
        etag,
        to_timestamp(created_on / 1000) as created_on,
        to_timestamp(modified_on / 1000) as modified_on,
        to_timestamp(expired_on / 1000) as expired_on
    from
        source
)

select * from staging
