with

source as (
    select * from {{ source('rds', 'acl_resource_access_type') }}
),

staging as (
    select
        id_oid as acl_resource_access_id,
        string_ele as access_type,
        owner_id as acl_id
    from
        source
)

select * from staging