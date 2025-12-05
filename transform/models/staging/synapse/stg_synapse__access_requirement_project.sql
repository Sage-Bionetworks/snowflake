with

source as (
    select * from {{ source('rds', 'access_requirement_project') }}
),

staging as (
    select
        project_id,
        ar_id
    from
        source
)

select * from staging