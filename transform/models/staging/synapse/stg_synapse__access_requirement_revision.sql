with

source as (
    select * from {{ source('rds', 'access_requirement_revision') }}
),

staging as (
    select
        owner_id as access_requirement_id,
        number as access_requirement_version,
        modified_by,
        to_timestamp(modified_on / 1000) as modified_on,
        serialized_entity as access_requirement_raw
    from
        source
)

select * from staging