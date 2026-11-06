with requirements as (
    select *
    from dynamic_table_refresh_boundary({{ ref('int_synapse_access_requirement') }})
),

current_requirements as (
    select
        access_requirement_id,
        access_requirement_current_version
    from dynamic_table_refresh_boundary({{ ref('stg_synapse__access_requirement') }})
)

select
    requirements.access_requirement_id as id,
    requirements.access_requirement_version as version_number,
    requirements.access_requirement_name as name,
    requirements.description,
    requirements.created_by,
    requirements.modified_by,
    requirements.created_on,
    requirements.modified_on,
    requirements.access_requirement_access_type as access_type,
    'org.sagebionetworks.repo.model.' || requirements.access_requirement_type as concrete_type,
    requirements.subjects_defined_by_annotations,
    requirements.subject_ids as subjects_ids,
    requirements.is_certified_user_required,
    requirements.is_validated_profile_required,
    requirements.is_duc_required,
    requirements.is_irb_approval_required,
    requirements.are_other_attachments_required,
    requirements.is_idu_public,
    requirements.is_idu_required,
    requirements.is_two_fa_required,
    requirements.duc_template_file_handle_id,
    requirements.expiration_period,
    requirements.terms_of_use as terms_of_user,
    requirements.act_contact_info,
    requirements.open_jira_issue,
    requirements.jira_key
from requirements
inner join current_requirements
    on requirements.access_requirement_id = current_requirements.access_requirement_id
    and requirements.access_requirement_version = current_requirements.access_requirement_current_version
