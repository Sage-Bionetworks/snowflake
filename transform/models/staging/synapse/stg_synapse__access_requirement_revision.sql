with

source as (
    select
        owner_id,
        number,
        modified_by,
        modified_on,
        serialized_entity
    from {{ source('rds', 'access_requirement_revision') }}
),

decoded as (
    select
        owner_id,
        number,
        modified_by,
        modified_on,
        parse_xml(
            {{ target.database }}.rds_raw.gzip_decompress_string(serialized_entity),
            true
        ) as access_requirement_xml
    from source
),

staging as (
    select
        owner_id as access_requirement_id,
        number as access_requirement_version,
        modified_by,
        to_timestamp(modified_on / 1000) as modified_on,
        nullif(
            xmlget(access_requirement_xml, 'name'):"$"::varchar, ''
        ) as access_requirement_name,
        -- XStream also records the concrete requirement class in the root tag.
        split_part(
            coalesce(
                xmlget(access_requirement_xml, 'concreteType'):"$"::varchar,
                access_requirement_xml:"@"::varchar
            ), '.', -1
        ) as access_requirement_type,
        xmlget(access_requirement_xml, 'accessType'):"$"::varchar as access_requirement_access_type,
        try_to_boolean(
            xmlget(access_requirement_xml, 'isTwoFaRequired'):"$"::varchar
        ) as is_two_fa_required,
        try_to_boolean(
            xmlget(access_requirement_xml, 'isCertifiedUserRequired'):"$"::varchar
        ) as is_certified_user_required,
        try_to_boolean(
            xmlget(access_requirement_xml, 'isValidatedProfileRequired'):"$"::varchar
        ) as is_validated_profile_required,
        try_to_boolean(
            xmlget(access_requirement_xml, 'isDUCRequired'):"$"::varchar
        ) as is_duc_required,
        try_to_boolean(
            xmlget(access_requirement_xml, 'isIRBApprovalRequired'):"$"::varchar
        ) as is_irb_approval_required,
        try_to_boolean(
            xmlget(access_requirement_xml, 'areOtherAttachmentsRequired'):"$"::varchar
        ) as are_other_attachments_required,
        try_to_boolean(
            xmlget(access_requirement_xml, 'isIDURequired'):"$"::varchar
        ) as is_idu_required,
        try_to_boolean(
            xmlget(access_requirement_xml, 'isIDUPublic'):"$"::varchar
        ) as is_idu_public,
        try_to_number(
            xmlget(access_requirement_xml, 'expirationPeriod'):"$"::varchar
        ) as expiration_period,
        xmlget(access_requirement_xml, 'description'):"$"::varchar as description,
        xmlget(access_requirement_xml, 'etag'):"$"::varchar as etag,
        xmlget(access_requirement_xml, 'url'):"$"::varchar as url,
        xmlget(access_requirement_xml, 'termsOfUse'):"$"::varchar as terms_of_use,
        try_to_number(
            xmlget(access_requirement_xml, 'ducTemplateFileHandleId'):"$"::varchar
        ) as duc_template_file_handle_id,
        xmlget(access_requirement_xml, 'eDucTemplateId'):"$"::varchar as e_duc_template_id,
        xmlget(access_requirement_xml, 'jiraKey'):"$"::varchar as jira_key,
        xmlget(access_requirement_xml, 'actContactInfo'):"$"::varchar as act_contact_info,
        try_to_boolean(
            xmlget(access_requirement_xml, 'openJiraIssue'):"$"::varchar
        ) as open_jira_issue,
        try_to_boolean(
            xmlget(access_requirement_xml, 'subjectsDefinedByAnnotations'):"$"::varchar
        ) as subjects_defined_by_annotations,
        try_to_number(
            xmlget(xmlget(access_requirement_xml, 'formTemplateRef'), 'templateId'):"$"::varchar
        ) as form_template_id,
        try_to_number(
            xmlget(xmlget(access_requirement_xml, 'formTemplateRef'), 'templateVersionNumber'):"$"::varchar
        ) as form_template_version,
        case
            when xmlget(access_requirement_xml, 'subjectIds') is not null
            then transform(
                filter(
                    coalesce(to_array(xmlget(access_requirement_xml, 'subjectIds'):"$"), array_construct()),
                    subject -> is_object(subject)
                ),
                subject -> object_construct(
                    'id', xmlget(subject, 'id'):"$"::varchar,
                    'type', xmlget(subject, 'type'):"$"::varchar
                )
            )
        end as subject_ids
    from decoded
)

select
    access_requirement_id,
    access_requirement_version,
    modified_by,
    modified_on,
    access_requirement_name,
    access_requirement_type,
    access_requirement_access_type,
    is_two_fa_required,
    is_certified_user_required,
    is_validated_profile_required,
    is_duc_required,
    is_irb_approval_required,
    are_other_attachments_required,
    is_idu_required,
    is_idu_public,
    expiration_period,
    description,
    etag,
    url,
    terms_of_use,
    duc_template_file_handle_id,
    e_duc_template_id,
    jira_key,
    act_contact_info,
    open_jira_issue,
    subjects_defined_by_annotations,
    form_template_id,
    form_template_version,
    subject_ids
from staging
