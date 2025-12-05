with

source as (
    select * from {{ source('rds', 'acl') }}
),

staging as (
    select
        id as acl_id,
        owner_id as object_id,
        owner_type as object_type,
        to_timestamp(created_on / 1000) as created_on,
        etag
    from
        source
)

select * from staging