with

source as (
    select * from {{ source('rds', 'access_approval') }}
),

staging as (
    select
        id as access_requirement_approval_id,
        requirement_id as access_requirement_id,
        requirement_version as access_requirement_version,
        submitter_id,
        accessor_id,
        expired_on,
        state,
        etag
    from
        source
)

select * from staging