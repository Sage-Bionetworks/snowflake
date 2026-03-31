with

source as (
    select * from synapse_data_warehouse.rds_raw.access_requirement
),

staging as (
    select
        id as access_requirement_id,
        name as access_requirement_name,
        created_by,
        current_rev_num as access_requirement_current_version,
        access_type,
        etag,
        case
            when concrete_type = 'org.sagebionetworks.repo.model.LockAccessRequirement' then 'LockAccessRequirement'
            when concrete_type = 'org.sagebionetworks.repo.model.ManagedACTAccessRequirement' then 'ManagedACTAccessRequirement'
            when concrete_type = 'org.sagebionetworks.repo.model.ACTAccessRequirement' then 'ACTAccessRequirement'
            when concrete_type = 'org.sagebionetworks.repo.model.SelfSignAccessRequirement' then 'SelfSignAccessRequirement'
            when concrete_type = 'org.sagebionetworks.repo.model.TermsOfUseAccessRequirement' then 'TermsOfUseAccessRequirement'
            when concrete_type = 'org.sagebionetworks.repo.model.PostMessageContentAccessRequirement' then 'PostMessageContentAccessRequirement'
        end as access_requirement_type,
        to_timestamp(created_on / 1000) as created_on,
        to_boolean(is_two_fa_required) as is_two_fa_required
    from
        source
)

select * from staging
