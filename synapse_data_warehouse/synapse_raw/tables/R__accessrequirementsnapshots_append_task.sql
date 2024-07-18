use role accountadmin;
use schema {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

alter task refresh_synapse_warehouse_s3_stage_task suspend;
create task if not exists append_to_accessrequirementsnapshot_task
    user_task_managed_initial_warehouse_size = 'SMALL'
    AFTER refresh_synapse_warehouse_s3_stage_task
as
    copy into
        accessrequirementsnapshots
    from (
        select
            $1:change_timestamp as change_timestamp,
            $1:change_type as change_type,
            $1:change_user_id as change_user_id,
            $1:snapshot_timestamp as snapshot_timestamp,
            $1:id as id,
            $1:version_number as version_number,
            $1:name as name,
            $1:description as description,
            $1:created_by as created_by,
            $1:modified_by as modified_by,
            $1:created_on as created_on,
            $1:modified_on as modified_on,
            $1:access_type as access_type,
            $1:concrete_type as concrete_type,
            $1:subjects_defined_by_annotation as subjects_defined_by_annotation,
            $1:subjects_ids as subjects_ids,
            $1:is_certified_user_required as is_certified_user_required,
            $1:is_validated_profile_required as is_validated_profile_required,
            $1:is_duc_required as is_duc_required,
            $1:is_irb_approval_required as is_irb_approval_required,
            $1:are_other_attachments_required as are_other_attachments_required,
            $1:is_idu_public as is_idu_public,
            $1:is_idu_required as is_idu_required,
            $1:is_two_fa_required as is_two_fa_required,
            $1:duc_template_file_handle_id as duc_template_file_handle_id,
            $1:expiration_period as expiration_period,
            $1:terms_of_user as terms_of_user,
            $1:act_contact_info as act_contact_info,
            $1:open_jira_issue as open_jira_issue,
            $1:jira_key as jira_key,
            NULLIF(
                regexp_replace(
                    METADATA$FILENAME,
                    '.*accessrequirementsnapshots\/snapshot_date\=(.*)\/.*',
                    '\\1'),
                '__HIVE_DEFAULT_PARTITION__'
            ) as snapshot_date
        from
            @{{stage_storage_integration}}_stage/accessrequirementsnapshots --noqa: TMP
        )
    pattern='.*accessrequirementsnapshots/snapshot_date=.*/.*';
alter task append_to_accessrequirementsnapshot_task resume;
alter task refresh_synapse_warehouse_s3_stage_task resume;
