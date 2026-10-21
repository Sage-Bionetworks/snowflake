with

access_requirement_base as (
    select
        access_requirement_id,
        access_requirement_current_version,
        created_by,
        created_on,
        is_two_fa_required
    from
        {{ ref('stg_synapse__access_requirement') }}
),

access_requirement_revision as (
    select
        access_requirement_id,
        access_requirement_version,
        modified_by,
        modified_on,
        access_requirement_name,
        access_requirement_type,
        access_type,
        is_two_fa_required,
        is_certified_user_required,
        is_validated_profile_required,
        is_duc_required,
        is_irb_approval_required,
        are_other_attachments_required,
        is_idu_required,
        is_idu_public,
        expiration_period,
        access_requirement_raw
    from
        {{ ref('stg_synapse__access_requirement_revision') }}
)

select
    base.access_requirement_id,
    revision.access_requirement_version,
    revision.access_requirement_name,
    revision.access_requirement_type,
    base.created_by,
    base.created_on,
    revision.modified_by,
    revision.modified_on,
    coalesce(
        revision.is_two_fa_required,
        case
            when base.access_requirement_current_version = revision.access_requirement_version
            then base.is_two_fa_required
        end
    ) as is_two_fa_required,
    revision.is_certified_user_required,
    revision.is_validated_profile_required,
    revision.is_duc_required,
    revision.is_irb_approval_required,
    revision.are_other_attachments_required,
    revision.is_idu_required,
    revision.is_idu_public,
    revision.access_type,
    revision.expiration_period,
    revision.access_requirement_raw
from
    access_requirement_base base
inner join
    access_requirement_revision revision
on
    base.access_requirement_id = revision.access_requirement_id
