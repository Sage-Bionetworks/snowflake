with

source as (
    select * from {{ source('rds', 'principal_alias') }}
),

staging as (
    select
        id as principal_alias_id,
        principal_id,
        alias_unique,
        alias_display,
        type as alias_type,
        etag
    from
        source
)

select * from staging
