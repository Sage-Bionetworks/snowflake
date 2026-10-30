with

source as (
    select * from {{ source('rds', 'research_project') }}
),

staging as (
    select
        id as research_project_id,
        access_requirement_id,
        created_by,
        modified_by,
        etag,
        project_lead,
        institution,
        to_timestamp(created_on / 1000) as created_on,
        to_timestamp(modified_on / 1000) as modified_on,
        to_varchar(idu, 'UTF-8') as intended_data_use
    from
        source
)

select * from staging
