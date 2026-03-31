with all_values as (

    select
        string_ele as value_field,
        count(*) as n_records

    from synapse_data_warehouse.rds_raw.acl_resource_access_type
    group by string_ele

)

select *
from all_values
where value_field not in (
    'CHANGE_PERMISSIONS', 'TEAM_MEMBERSHIP_UPDATE', 'MODERATE', 'SEND_MESSAGE', 'READ_PRIVATE_SUBMISSION', 'SUBMIT', 'CHANGE_SETTINGS', 'EXEMPTION_ELIGIBLE', 'PARTICIPATE', 'CREATE', 'DELETE', 'UPDATE', 'DELETE_SUBMISSION', 'DOWNLOAD', 'READ', 'UPDATE_SUBMISSION', 'REVIEW_SUBMISSIONS', 'UPLOAD'
)
