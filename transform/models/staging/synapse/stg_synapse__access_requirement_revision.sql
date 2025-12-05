with

source as (
    select * from {{ source('rds', 'access_requirement_revision') }}
),

staging as (
    select
        owner_id as ar_id,
        number as ar_version,
        to_timestamp(modified_on / 1000) as modified_on,
        serialized_entity as ar_raw,
        modified_by
    from
        source
)

select * from staging