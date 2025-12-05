with

source as (
    select * from {{ source('rds', 'access_requirement') }}
),

staging as (
    select
        id as ar_id,
        name as ar_name,
        case 
            when concrete_type='org.sagebionetworks.repo.model.LockAccessRequirement' then 'LockAccessRequirement'
            when concrete_type='org.sagebionetworks.repo.model.ManagedACTAccessRequirement' then 'ManagedACTAccessRequirement'
            when concrete_type='org.sagebionetworks.repo.model.SelfSignAccessRequirement' then 'SelfSignAccessRequirement'
            when concrete_type='org.sagebionetworks.repo.model.ACTAccessRequirement' then 'ACTAccessRequirement'
        end as ar_type,
        to_timestamp(created_on / 1000) as created_on,
        current_rev_num as ar_current_version,
        is_two_fa_required as ar_is_two_fa_required,
        created_by,
        concrete_type,
        access_type,
        etag
    from
        source
)

select * from staging