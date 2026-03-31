with

source as (
    select * from synapse_data_warehouse.rds_raw.data_access_submission_submitter
),

staging as (
    select
        id as data_access_submission_submitter_id,
        access_requirement_id,
        submitter_id as principal_id,
        current_submission_id as data_access_submission_id,
        etag
    from
        source
)

select * from staging
