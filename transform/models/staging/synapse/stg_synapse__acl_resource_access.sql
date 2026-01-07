with

source as (
    select * from {{ source('rds', 'acl_resource_access') }}
),

staging as (
    select
        id as acl_resource_access_id,
        owner_id as acl_id,
        group_id as principal_id
    from
        source
)

select * from staging