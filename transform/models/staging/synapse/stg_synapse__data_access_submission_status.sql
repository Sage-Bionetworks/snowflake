with

source as (
    select * from {{ source('rds', 'data_access_submission_status') }}
),

-- Since `reason` is normally a utf-8 encoded binary blob,
-- but some values before 2019 contain invalid utf-8 characters
-- and Snowflake does not have a try_to_varchar equivalent method,
-- we nullify `reason` values before 2019.
staging as (
    select
        submission_id as data_access_submission_id,
        created_by,
        to_timestamp(created_on/1000) as created_on,
        modified_by as state_modified_by,
        to_timestamp(modified_on/1000) as state_modified_on,
        state,
        case
            when to_timestamp(created_on/1000) >= '2019-01-01' then to_varchar(reason, 'utf-8')
            -- any records not matching condition are implicitly null
        end as state_reason
    from
        source
)

select * from staging
