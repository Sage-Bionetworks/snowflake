with

source as (
    select * from {{ source('rds', 'access_approval') }}
),

staging as (
    select
        id as ar_approval_id,
        requirement_id as ar_id,
        requirement_version as ar_version,
        submitter_id as ar_submitter_user_id,
        accessor_id as ar_accessor_user_id,
        expired_on as ar_expired_on,
        state as ar_state,
        etag
    from
        source
)

select * from staging