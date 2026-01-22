with

source as (
    select * from {{ source('rds', 'data_access_request') }}
),

staging as (
    select
        id as data_access_request_id,
        access_requirement_id,
        research_project_id,
        created_by,
        to_timestamp(created_on/1000) as created_on,
        modified_by,
        to_timestamp(modified_on/1000) as modified_on,
        etag,
        request_serialized as data_access_request_raw
    from
        source
)

select * from staging
