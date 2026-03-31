with

source as (
    select * from synapse_data_warehouse.rds_raw.data_access_submission
),

staging as (
    select
        id as data_access_submission_id,
        access_requirement_id,
        data_access_request_id,
        research_project_id,
        created_by,
        access_requirement_version,
        etag,
        submission_serialized as data_access_submission_raw,
        to_timestamp(created_on / 1000) as created_on
    from
        source
)

select * from staging
