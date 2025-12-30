with

source as (
    select * from {{ source('rds', 'access_requirement') }}
),

staging as (
    select
        id as access_requirement_id,
        name as access_requirement_name,
        case 
            when concrete_type='org.sagebionetworks.repo.model.LockAccessRequirement' then 'LockAccessRequirement'
            when concrete_type='org.sagebionetworks.repo.model.ManagedACTAccessRequirement' then 'ManagedACTAccessRequirement'
            when concrete_type='org.sagebionetworks.repo.model.SelfSignAccessRequirement' then 'SelfSignAccessRequirement'
            when concrete_type='org.sagebionetworks.repo.model.ACTAccessRequirement' then 'ACTAccessRequirement'
        end as access_requirement_type,
        created_by,
        to_timestamp(created_on / 1000) as created_on,
        current_rev_num as access_requirement_current_version,
        to_boolean(is_two_fa_required) as is_two_fa_required,
        access_type,
        etag
    from
        source
)

select * from staging