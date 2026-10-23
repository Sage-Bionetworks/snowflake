with

accessor_changes as (
    select
        data_access_submission_id,
        principal_id as accessor_id,
        accessor_change_type
    from {{ ref('stg_synapse__data_access_submission_accessor_changes') }}
),

submissions as (
    select
        data_access_submission_id,
        access_requirement_id,
        access_requirement_version
    from {{ ref('stg_synapse__data_access_submission') }}
),

submission_status as (
    select
        data_access_submission_id,
        state,
        state_modified_on
    from {{ ref('stg_synapse__data_access_submission_status') }}
),

access_requirements as (
    select
        access_requirement_id,
        access_requirement_version,
        modified_on,
        expiration_period
    from {{ ref('int_synapse_access_requirement') }}
),

submission_accessor_changes as (
    select
        accessor_changes.data_access_submission_id,
        accessor_changes.accessor_id,
        accessor_changes.accessor_change_type,
        submissions.access_requirement_id,
        submissions.access_requirement_version as access_requirement_version_submitted_against,
        submission_status.state,
        submission_status.state_modified_on
    from accessor_changes
    inner join submissions
        on accessor_changes.data_access_submission_id = submissions.data_access_submission_id
    inner join submission_status
        on accessor_changes.data_access_submission_id = submission_status.data_access_submission_id
),

accessor_change_expiration as (
    select
        changes.data_access_submission_id,
        changes.accessor_id,
        changes.accessor_change_type,
        access_requirements.access_requirement_version as access_requirement_version_reviewed_against,
        -- Synapse calculates expiration before recording the approval status timestamp.
        case
            when
                changes.state = 'Approved'
                and changes.accessor_change_type in ('GAIN_ACCESS', 'RENEW_ACCESS')
                and access_requirements.expiration_period > 0
            then dateadd(
                millisecond,
                access_requirements.expiration_period,
                changes.state_modified_on
            )
        end as access_expires_on
    from submission_accessor_changes changes
    left join access_requirements
        on changes.state in ('Approved', 'Rejected')
        and changes.access_requirement_id = access_requirements.access_requirement_id
        and access_requirements.modified_on <= changes.state_modified_on
    qualify row_number() over (
        partition by
            changes.data_access_submission_id,
            changes.accessor_id,
            changes.accessor_change_type
        order by
            access_requirements.modified_on desc nulls last,
            access_requirements.access_requirement_version desc nulls last
    ) = 1
)

select
    changes.data_access_submission_id,
    changes.accessor_id,
    changes.accessor_change_type,
    changes.access_requirement_id,
    changes.access_requirement_version_submitted_against,
    expiration.access_requirement_version_reviewed_against,
    changes.state,
    changes.state_modified_on,
    expiration.access_expires_on
from submission_accessor_changes changes
inner join accessor_change_expiration expiration
    on changes.data_access_submission_id = expiration.data_access_submission_id
    and changes.accessor_id = expiration.accessor_id
    and changes.accessor_change_type = expiration.accessor_change_type
