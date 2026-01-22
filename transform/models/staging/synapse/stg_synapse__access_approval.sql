with

source as (
    select * from {{ source('rds', 'access_approval') }}
),

staging as (
    select
        id as access_requirement_approval_id,
        requirement_id as access_requirement_id,
        requirement_version as access_requirement_version,
        created_by,
        to_timestamp(created_on / 1000) as created_on,
        modified_by,
        to_timestamp(modified_on / 1000) as modified_on,
        submitter_id,
        accessor_id,
        to_timestamp(expired_on / 1000) as expired_on,
        state,
        etag
    from
        source
)

select * from staging