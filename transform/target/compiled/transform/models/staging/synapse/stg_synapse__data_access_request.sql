with

source as (
    select * from synapse_data_warehouse.rds_raw.data_access_request
),

staging as (
    select
        id as data_access_request_id,
        access_requirement_id,
        research_project_id,
        created_by,
        modified_by,
        etag,
        request_serialized as data_access_request_raw,
        to_timestamp(created_on / 1000) as created_on,
        to_timestamp(modified_on / 1000) as modified_on
    from
        source
)

select * from staging
