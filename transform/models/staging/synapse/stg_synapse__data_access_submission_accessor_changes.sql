with

source as (
    select * from {{ source('rds', 'data_access_submission_accessor_changes') }}
),

staging as (
    select
        submission_id as data_access_submission_id,
        accessor_id as principal_id,
        access_type
    from
        source
)

select * from staging
