use role accountadmin;
use database synapse_data_warehouse;
use schema synapse_raw;

create task if not exists refresh_synapse_prod_stage_task
    schedule = 'USING CRON 0 23 * * * America/Los_Angeles'
    user_task_managed_initial_warehouse_size = 'SMALL'
as
    alter stage if exists synapse_prod_warehouse_s3_stage refresh;
alter task refresh_synapse_prod_stage_task resume;

create task if not exists userprofilesnapshot_task
    schedule = 'USING CRON 0 0 * * * America/Los_Angeles'
    user_task_managed_initial_warehouse_size = 'SMALL'
as
    copy into
    userprofilesnapshot
    from (
        select
            $1:change_type as change_type,
            $1:change_timestamp as change_timestamp,
            $1:change_user_id as change_user_id,
            $1:snapshot_timestamp as snapshot_timestamp,
            $1:id as id,
            $1:user_name as user_name,
            $1:first_name as first_name,
            $1:last_name as last_name,
            $1:email as email,
            $1:location as location,
            $1:company as company,
            $1:position as position,
            NULLIF(
                REGEXP_REPLACE(
                    metadata$filename,
                    '.*userprofilesnapshots\/snapshot_date\=(.*)\/.*', '\\1'
                ),
                '__HIVE_DEFAULT_PARTITION__'
            ) as snapshot_date
        from
            @synapse_prod_warehouse_s3_stage/userprofilesnapshots
    )
    pattern = '.*userprofilesnapshots/snapshot_date=.*/.*';

alter task userprofilesnapshot_task resume;

create task if not exists nodesnapshot_task
    schedule = 'USING CRON 0 0 * * * America/Los_Angeles'
    user_task_managed_initial_warehouse_size = 'SMALL'
as
    copy into
    nodesnapshots
    from (
        select
            $1:change_type as change_type,
            $1:change_timestamp as change_timestamp,
            $1:change_user_id as change_user_id,
            $1:snapshot_timestamp as snapshot_timestamp,
            $1:id as id,
            $1:benefactor_id as benefactor_id,
            $1:project_id as project_id,
            $1:parent_id as parent_id,
            $1:node_type as node_type,
            $1:created_on as created_on,
            $1:created_by as created_by,
            $1:modified_on as modified_on,
            $1:modified_by as modified_by,
            $1:version_number as version_number,
            $1:file_handle_id as file_handle_id,
            case
                when POSITION('.' in $1:name) > 0
                    then
                        CONCAT(MD5($1:name), '.', REGEXP_REPLACE($1:name , '^(.*)[.](.*)', '\\2'))
                    else
                        MD5($1:name)
            end as name,
            $1:is_public as is_public,
            $1:is_controlled as is_controlled,
            $1:is_restricted as is_restricted,
            NULLIF(
                REGEXP_REPLACE(
                    metadata$filename,
                    '.*nodesnapshots\/snapshot_date\=(.*)\/.*', '\\1'
                ),
                '__HIVE_DEFAULT_PARTITION__'
            ) as snapshot_date
        from @synapse_prod_warehouse_s3_stage/nodesnapshots/
    )
    pattern = '.*nodesnapshots/snapshot_date=.*/.*';

alter task nodesnapshot_task resume;

create task if not exists certifiedquiz_task
    schedule = 'USING CRON 0 0 * * * America/Los_Angeles'
    user_task_managed_initial_warehouse_size = 'SMALL'
as
    copy into
    certifiedquiz
    from (
        select
            $1:response_id as response_id,
            $1:user_id as user_id,
            $1:passed as passed,
            $1:passed_on as passed_on,
            $1:stack as stack,
            $1:instance as instance,
            NULLIF(
                REGEXP_REPLACE(
                    metadata$filename,
                    '.*certifiedquizrecords\/record_date\=(.*)\/.*',
                    '\\1'
                ),
                '__HIVE_DEFAULT_PARTITION__'
            ) as record_date
        from
            @synapse_prod_warehouse_s3_stage/certifiedquizrecords
    )
    pattern = '.*certifiedquizrecords/record_date=.*/.*'
;
alter task certifiedquiz_task resume;

create task if not exists certifiedquizquestion_task
    schedule = 'USING CRON 0 0 * * * America/Los_Angeles'
    user_task_managed_initial_warehouse_size = 'SMALL'
as
    copy into
    certifiedquizquestion
    from (
        select
            $1:response_id as response_id,
            $1:question_index as question_index,
            $1:is_correct as is_correct,
            $1:stack as stack,
            $1:instance as instance,
            NULLIF(
                REGEXP_REPLACE(
                    metadata$filename,
                    '.*certifiedquizquestionrecords\/record_date\=(.*)\/.*',
                    '\\1'
                ),
                '__HIVE_DEFAULT_PARTITION__'
            ) as record_date
        from
            @synapse_prod_warehouse_s3_stage/certifiedquizquestionrecords
    )
    pattern = '.*certifiedquizquestionrecords/record_date=.*/.*'
;
alter task certifiedquizquestion_task resume;

create task if not exists filedownload_task
    schedule = 'USING CRON 0 0 * * * America/Los_Angeles'
    user_task_managed_initial_warehouse_size = 'SMALL'
as
    copy into
    filedownload
    from (
        select
            $1:timestamp as timestamp,
            $1:user_id as user_id,
            $1:project_id as project_id,
            $1:file_handle_id as file_handle_id,
            $1:downloaded_file_handle_id as downloaded_file_handle_id,
            $1:association_object_id as association_object_id,
            $1:association_object_type as association_object_type,
            $1:stack as stack,
            $1:instance as instance,
            NULLIF(
                REGEXP_REPLACE(
                    metadata$filename,
                    '.*filedownloadrecords\/record_date\=(.*)\/.*',
                    '\\1'
                ),
                '__HIVE_DEFAULT_PARTITION__'
            ) as record_date
        from
            @synapse_prod_warehouse_s3_stage/filedownloadrecords
    )
    pattern = '.*filedownloadrecords/record_date=.*/.*'
;
alter task filedownload_task resume;

create task if not exists aclsnapshots_task
    schedule = 'USING CRON 0 0 * * * America/Los_Angeles'
    user_task_managed_initial_warehouse_size = 'SMALL'
as
    copy into
    aclsnapshots
    from (
        select
            $1:change_timestamp as change_timestamp,
            $1:change_type as change_type,
            $1:snapshot_timestamp as snapshot_timestamp,
            $1:owner_id as owner_id,
            $1:owner_type as owner_type,
            $1:created_on as created_on,
            $1:resource_access as resource_access,
            NULLIF(
                REGEXP_REPLACE(
                    metadata$filename,
                    '.*aclsnapshots\/snapshot_date\=(.*)\/.*',
                    '\\1'
                ),
                '__HIVE_DEFAULT_PARTITION__'
            ) as snapshot_date
        from
            @synapse_prod_warehouse_s3_stage/aclsnapshots
    )
    pattern = '.*aclsnapshots/snapshot_date=.*/.*'
;
alter task aclsnapshots_task resume;

create task if not exists teamsnapshots_task
    schedule = 'USING CRON 0 0 * * * America/Los_Angeles'
    user_task_managed_initial_warehouse_size = 'SMALL'
as
    copy into
    teamsnapshots
    from (
        select
            $1:change_type as change_type,
            $1:change_timestamp as change_timestamp,
            $1:change_user_id as change_user_id,
            $1:snapshot_timestamp as snapshot_timestamp,
            $1:id as id,
            $1:name as name,
            $1:can_public_join as can_public_join,
            $1:created_on as created_on,
            $1:created_by as created_by,
            $1:modified_on as modified_on,
            $1:modified_by as modified_by,
            NULLIF(
                REGEXP_REPLACE(
                    metadata$filename,
                    '.*teamsnapshots\/snapshot_date\=(.*)\/.*',
                    '\\1'
                ),
                '__HIVE_DEFAULT_PARTITION__'
            ) as snapshot_date
        from
            @synapse_prod_warehouse_s3_stage/teamsnapshots
    )
    pattern = '.*teamsnapshots/snapshot_date=.*/.*'
;
alter task teamsnapshots_task resume;

create task if not exists usergroupsnapshots_task
    schedule = 'USING CRON 0 0 * * * America/Los_Angeles'
    user_task_managed_initial_warehouse_size = 'SMALL'
as
    copy into
    usergroupsnapshots
    from (
        select
            $1:change_type as change_type,
            $1:change_timestamp as change_timestamp,
            $1:change_user_id as change_user_id,
            $1:snapshot_timestamp as snapshot_timestamp,
            $1:id as id,
            $1:is_individual as is_individual,
            $1:created_on as created_on,
            NULLIF(
                REGEXP_REPLACE(
                    metadata$filename,
                    '.*usergroupsnapshots\/snapshot_date\=(.*)\/.*',
                    '\\1'
                ),
                '__HIVE_DEFAULT_PARTITION__'
            ) as snapshot_date
        from
            @synapse_prod_warehouse_s3_stage/usergroupsnapshots
    )
    pattern = '.*usergroupsnapshots/snapshot_date=.*/.*'
;
alter task usergroupsnapshots_task resume;

create task if not exists verificationsubmissionsnapshots_task
    schedule = 'USING CRON 0 0 * * * America/Los_Angeles'
    user_task_managed_initial_warehouse_size = 'SMALL'
as
    copy into verificationsubmissionsnapshots from (
        select
            $1:change_timestamp as change_timestamp,
            $1:change_type as change_type,
            $1:snapshot_timestamp as snapshot_timestamp,
            $1:id as id,
            $1:created_on as created_on,
            $1:created_by as created_by,
            $1:state_history as state_history,
            NULLIF(
                REGEXP_REPLACE(
                    metadata$filename,
                    '.*verificationsubmissionsnapshots\/snapshot_date\=(.*)\/.*',
                    '\\1'
                ),
                '__HIVE_DEFAULT_PARTITION__'
            ) as snapshot_date
        from
            @synapse_prod_warehouse_s3_stage/verificationsubmissionsnapshots
    )
    pattern = '.*verificationsubmissionsnapshots/snapshot_date=.*/.*'
;
alter task verificationsubmissionsnapshots_task resume;

create task if not exists teammembersnapshots_task
    schedule = 'USING CRON 0 0 * * * America/Los_Angeles'
    user_task_managed_initial_warehouse_size = 'SMALL'
as
    copy into teammembersnapshots from (
        select
            $1:change_type as change_type,
            $1:change_timestamp as change_timestamp,
            $1:change_user_id as change_user_id,
            $1:snapshot_timestamp as snapshot_timestamp,
            $1:team_id as team_id,
            $1:member_id as member_id,
            $1:is_admin as is_admin,
            NULLIF(
                REGEXP_REPLACE(
                    metadata$filename,
                    '.*teammembersnapshots\/snapshot_date\=(.*)\/.*',
                    '\\1'
                ),
                '__HIVE_DEFAULT_PARTITION__'
            ) as snapshot_date
        from
            @synapse_prod_warehouse_s3_stage/teammembersnapshots
    )
    pattern = '.*teammembersnapshots/snapshot_date=.*/.*'
;
alter task teammembersnapshots_task resume;

create task if not exists fileupload_task
    schedule = 'USING CRON 0 0 * * * America/Los_Angeles'
    user_task_managed_initial_warehouse_size = 'SMALL'
as
    copy into fileupload from (
        select
            $1:timestamp as timestamp,
            $1:user_id as user_id,
            $1:project_id as project_id,
            $1:file_handle_id as file_handle_id,
            $1:association_object_id as association_object_id,
            $1:association_object_type as association_object_type,
            $1:stack as stack,
            $1:instance as instance,
            NULLIF(
                REGEXP_REPLACE(
                    metadata$filename,
                    '.*fileuploadrecords\/record_date\=(.*)\/.*',
                    '\\1'
                ),
                '__HIVE_DEFAULT_PARTITION__'
            ) as record_date
        from
            @synapse_prod_warehouse_s3_stage/fileuploadrecords
    )
    pattern = '.*fileuploadrecords/record_date=.*/.*'
;
alter task fileupload_task resume;

create task if not exists filesnapshots_task
    schedule = 'USING CRON 0 0 * * * America/Los_Angeles'
    user_task_managed_initial_warehouse_size = 'SMALL'
as
    copy into filesnapshots from (
        select
            $1:change_type as change_type,
            $1:change_timestamp as change_timestamp,
            $1:change_user_id as change_user_id,
            $1:snapshot_timestamp as snapshot_timestamp,
            $1:id as id,
            $1:created_by as created_by,
            $1:created_on as created_on,
            $1:modified_on as modified_on,
            $1:concrete_type as concrete_type,
            $1:content_md5 as content_md5,
            $1:content_type as content_type,
            $1:file_name as file_name,
            $1:storage_location_id as storage_location_id,
            $1:content_size as content_size,
            $1:bucket as bucket,
            $1:key as key,
            $1:preview_id as preview_id,
            $1:is_preview as is_preview,
            $1:status as status,
            NULLIF(
                REGEXP_REPLACE(
                    metadata$filename,
                    '.*filesnapshots\/snapshot_date\=(.*)\/.*',
                    '\\1'
                ),
                '__HIVE_DEFAULT_PARTITION__'
            ) as snapshot_date
        from
            @synapse_prod_warehouse_s3_stage/filesnapshots
    )
    pattern = '.*filesnapshots/snapshot_date=.*/.*'
;
alter task filesnapshots_task resume;

create task if not exists processedaccess_task
    schedule = 'USING CRON 0 0 * * * America/Los_Angeles'
    user_task_managed_initial_warehouse_size = 'SMALL'
as
    copy into processedaccess from (
        select
            $1:session_id as session_id,
            $1:timestamp as timestamp,
            $1:user_id as user_id,
            $1:method as method,
            $1:request_url as request_url,
            $1:user_agent as user_agent,
            $1:host as host,
            $1:origin as origin,
            $1:x_forwarded_for as x_forwarded_for,
            $1:via as via,
            $1:thread_id as thread_id,
            $1:elapse_ms as elapse_ms,
            $1:success as success,
            $1:stack as stack,
            $1:instance as instance,
            $1:vm_id as vm_id,
            $1:return_object_id as return_object_id,
            $1:query_string as query_string,
            $1:response_status as response_status,
            $1:oauth_client_id as oauth_client_id,
            $1:basic_auth_username as basic_auth_username,
            $1:auth_method as auth_method,
            $1:normalized_method_signature as normalized_method_signature,
            $1:client as client,
            $1:client_version as client_version,
            $1:entity_id as entity_id,
            NULLIF(
                REGEXP_REPLACE(
                    metadata$filename,
                    '.*processedaccessrecord\/record_date\=(.*)\/.*',
                    '\\1'
                ),
                '__HIVE_DEFAULT_PARTITION__'
            ) as record_date
        from @synapse_prod_warehouse_s3_stage/processedaccessrecord
    )
    pattern = '.*processedaccessrecord/record_date=.*/.*'
;
alter task processedaccess_task resume;

-- ! Task tracking
show tasks;

select *
from TABLE(information_schema.task_history())
order by scheduled_time;

// Get results from a query id
select *
from TABLE(RESULT_SCAN('01af2764-0001-5c4a-0004-7c7a0006d10a'))
limit 10;
