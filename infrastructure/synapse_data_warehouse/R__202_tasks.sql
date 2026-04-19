-- Task DAG for {{ database_name }}.
-- Final state compiled from V1.12.0 through V2.59.0.
-- Pattern: suspend root → CREATE OR ALTER each task → SYSTEM$TASK_DEPENDENTS_ENABLE.
-- Note: backup tasks are created suspended and must be manually resumed in prod.

USE ROLE ACCOUNTADMIN;
USE DATABASE {{ database_name }};

-- ============================================================
-- SYNAPSE_RAW schema tasks
-- ============================================================

USE SCHEMA {{ database_name }}.SYNAPSE_RAW;

-- Suspend root before modifying any task in the DAG
ALTER TASK IF EXISTS refresh_synapse_warehouse_s3_stage_task SUSPEND;

-- Root task: refreshes the S3 stage on a nightly schedule
CREATE OR ALTER TASK refresh_synapse_warehouse_s3_stage_task
    SCHEDULE = 'USING CRON 0 23 * * * America/Los_Angeles'
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
    ALTER STAGE IF EXISTS {{ stage_storage_integration }}_stage REFRESH;

-- ── Snapshot ingestion tasks (AFTER root) ────────────────────

CREATE OR ALTER TASK userprofilesnapshot_task
    AFTER refresh_synapse_warehouse_s3_stage_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
    COPY INTO userprofilesnapshot
    FROM (
        SELECT
            $1:change_type          AS change_type,
            $1:change_timestamp     AS change_timestamp,
            $1:change_user_id       AS change_user_id,
            $1:snapshot_timestamp   AS snapshot_timestamp,
            $1:id                   AS id,
            $1:user_name            AS user_name,
            $1:first_name           AS first_name,
            $1:last_name            AS last_name,
            $1:email                AS email,
            $1:location             AS location,
            $1:company              AS company,
            $1:position             AS position,
            NULLIF(REGEXP_REPLACE(metadata$filename,
                '.*userprofilesnapshots\/snapshot_date\=(.*)\/.*', '\\1'),
                '__HIVE_DEFAULT_PARTITION__') AS snapshot_date,
            $1:created_on           AS created_on,
            $1:is_two_factor_auth_enabled AS is_two_factor_auth_enabled,
            $1:industry             AS industry,
            $1:tos_agreements       AS tos_agreements
        FROM @{{ stage_storage_integration }}_stage/userprofilesnapshots
    )
    PATTERN = '.*userprofilesnapshots/snapshot_date=.*/.*';

CREATE OR ALTER TASK nodesnapshot_task
    AFTER refresh_synapse_warehouse_s3_stage_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
    COPY INTO nodesnapshots
    FROM (
        SELECT
            $1:change_type          AS change_type,
            $1:change_timestamp     AS change_timestamp,
            $1:change_user_id       AS change_user_id,
            $1:snapshot_timestamp   AS snapshot_timestamp,
            $1:id                   AS id,
            $1:benefactor_id        AS benefactor_id,
            $1:project_id           AS project_id,
            $1:parent_id            AS parent_id,
            $1:node_type            AS node_type,
            $1:created_on           AS created_on,
            $1:created_by           AS created_by,
            $1:modified_on          AS modified_on,
            $1:modified_by          AS modified_by,
            $1:version_number       AS version_number,
            $1:file_handle_id       AS file_handle_id,
            $1:name                 AS name,
            $1:is_public            AS is_public,
            $1:is_controlled        AS is_controlled,
            $1:is_restricted        AS is_restricted,
            NULLIF(REGEXP_REPLACE(metadata$filename,
                '.*nodesnapshots\/snapshot_date\=(.*)\/.*', '\\1'),
                '__HIVE_DEFAULT_PARTITION__') AS snapshot_date,
            $1:effective_ars        AS effective_ars,
            PARSE_JSON(REPLACE(REPLACE($1:annotations, '\n', '\\n'), '\r', '\\r'))          AS annotations,
            PARSE_JSON(REPLACE(REPLACE($1:derived_annotations, '\n', '\\n'), '\r', '\\r'))  AS derived_annotations,
            $1:version_comment      AS version_comment,
            $1:version_label        AS version_label,
            $1:alias                AS alias,
            $1:activity_id          AS activity_id,
            PARSE_JSON($1:column_model_ids)  AS column_model_ids,
            PARSE_JSON($1:scope_ids)         AS scope_ids,
            PARSE_JSON($1:items)             AS items,
            PARSE_JSON($1:reference)         AS reference,
            $1:is_search_enabled    AS is_search_enabled,
            $1:defining_sql         AS defining_sql,
            PARSE_JSON(REPLACE(REPLACE($1:internal_annotations, '\n', '\\n'), '\r', '\\r')) AS internal_annotations,
            PARSE_JSON(REPLACE(REPLACE($1:version_history, '\n', '\\n'), '\r', '\\r'))      AS version_history,
            PARSE_JSON(REPLACE(REPLACE($1:project_storage_usage, '\n', '\\n'), '\r', '\\r')) AS project_storage_usage
        FROM @{{ stage_storage_integration }}_stage/nodesnapshots/
    )
    PATTERN = '.*nodesnapshots/snapshot_date=.*/.*';

CREATE OR ALTER TASK filedownload_task
    AFTER refresh_synapse_warehouse_s3_stage_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
    COPY INTO filedownload
    FROM (
        SELECT
            $1:timestamp                    AS timestamp,
            $1:user_id                      AS user_id,
            $1:project_id                   AS project_id,
            $1:file_handle_id               AS file_handle_id,
            $1:downloaded_file_handle_id    AS downloaded_file_handle_id,
            $1:association_object_id        AS association_object_id,
            $1:association_object_type      AS association_object_type,
            $1:stack                        AS stack,
            $1:instance                     AS instance,
            NULLIF(REGEXP_REPLACE(metadata$filename,
                '.*filedownloadrecords\/record_date\=(.*)\/.*', '\\1'),
                '__HIVE_DEFAULT_PARTITION__') AS record_date,
            $1:session_id                   AS session_id
        FROM @{{ stage_storage_integration }}_stage/filedownloadrecords
    )
    PATTERN = '.*filedownloadrecords/record_date=.*/.*';

CREATE OR ALTER TASK aclsnapshots_task
    AFTER refresh_synapse_warehouse_s3_stage_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
    COPY INTO aclsnapshots
    FROM (
        SELECT
            $1:change_timestamp     AS change_timestamp,
            $1:change_type          AS change_type,
            $1:snapshot_timestamp   AS snapshot_timestamp,
            $1:owner_id             AS owner_id,
            $1:owner_type           AS owner_type,
            $1:created_on           AS created_on,
            $1:resource_access      AS resource_access,
            NULLIF(REGEXP_REPLACE(metadata$filename,
                '.*aclsnapshots\/snapshot_date\=(.*)\/.*', '\\1'),
                '__HIVE_DEFAULT_PARTITION__') AS snapshot_date
        FROM @{{ stage_storage_integration }}_stage/aclsnapshots
    )
    PATTERN = '.*aclsnapshots/snapshot_date=.*/.*';

CREATE OR ALTER TASK teamsnapshots_task
    AFTER refresh_synapse_warehouse_s3_stage_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
    COPY INTO teamsnapshots
    FROM (
        SELECT
            $1:change_type          AS change_type,
            $1:change_timestamp     AS change_timestamp,
            $1:change_user_id       AS change_user_id,
            $1:snapshot_timestamp   AS snapshot_timestamp,
            $1:id                   AS id,
            $1:name                 AS name,
            $1:can_public_join      AS can_public_join,
            $1:created_on           AS created_on,
            $1:created_by           AS created_by,
            $1:modified_on          AS modified_on,
            $1:modified_by          AS modified_by,
            NULLIF(REGEXP_REPLACE(metadata$filename,
                '.*teamsnapshots\/snapshot_date\=(.*)\/.*', '\\1'),
                '__HIVE_DEFAULT_PARTITION__') AS snapshot_date
        FROM @{{ stage_storage_integration }}_stage/teamsnapshots
    )
    PATTERN = '.*teamsnapshots/snapshot_date=.*/.*';

CREATE OR ALTER TASK usergroupsnapshots_task
    AFTER refresh_synapse_warehouse_s3_stage_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
    COPY INTO usergroupsnapshots
    FROM (
        SELECT
            $1:change_type          AS change_type,
            $1:change_timestamp     AS change_timestamp,
            $1:change_user_id       AS change_user_id,
            $1:snapshot_timestamp   AS snapshot_timestamp,
            $1:id                   AS id,
            $1:is_individual        AS is_individual,
            $1:created_on           AS created_on,
            NULLIF(REGEXP_REPLACE(metadata$filename,
                '.*usergroupsnapshots\/snapshot_date\=(.*)\/.*', '\\1'),
                '__HIVE_DEFAULT_PARTITION__') AS snapshot_date
        FROM @{{ stage_storage_integration }}_stage/usergroupsnapshots
    )
    PATTERN = '.*usergroupsnapshots/snapshot_date=.*/.*';

CREATE OR ALTER TASK verificationsubmissionsnapshots_task
    AFTER refresh_synapse_warehouse_s3_stage_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
    COPY INTO verificationsubmissionsnapshots
    FROM (
        SELECT
            $1:change_timestamp     AS change_timestamp,
            $1:change_type          AS change_type,
            $1:snapshot_timestamp   AS snapshot_timestamp,
            $1:id                   AS id,
            $1:created_on           AS created_on,
            $1:created_by           AS created_by,
            $1:state_history        AS state_history,
            NULLIF(REGEXP_REPLACE(metadata$filename,
                '.*verificationsubmissionsnapshots\/snapshot_date\=(.*)\/.*', '\\1'),
                '__HIVE_DEFAULT_PARTITION__') AS snapshot_date
        FROM @{{ stage_storage_integration }}_stage/verificationsubmissionsnapshots
    )
    PATTERN = '.*verificationsubmissionsnapshots/snapshot_date=.*/.*';

CREATE OR ALTER TASK teammembersnapshots_task
    AFTER refresh_synapse_warehouse_s3_stage_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
    COPY INTO teammembersnapshots
    FROM (
        SELECT
            $1:change_type          AS change_type,
            $1:change_timestamp     AS change_timestamp,
            $1:change_user_id       AS change_user_id,
            $1:snapshot_timestamp   AS snapshot_timestamp,
            $1:team_id              AS team_id,
            $1:member_id            AS member_id,
            $1:is_admin             AS is_admin,
            NULLIF(REGEXP_REPLACE(metadata$filename,
                '.*teammembersnapshots\/snapshot_date\=(.*)\/.*', '\\1'),
                '__HIVE_DEFAULT_PARTITION__') AS snapshot_date
        FROM @{{ stage_storage_integration }}_stage/teammembersnapshots
    )
    PATTERN = '.*teammembersnapshots/snapshot_date=.*/.*';

CREATE OR ALTER TASK fileupload_task
    AFTER refresh_synapse_warehouse_s3_stage_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
    COPY INTO fileupload
    FROM (
        SELECT
            $1:timestamp                AS timestamp,
            $1:user_id                  AS user_id,
            $1:project_id               AS project_id,
            $1:file_handle_id           AS file_handle_id,
            $1:association_object_id    AS association_object_id,
            $1:association_object_type  AS association_object_type,
            $1:stack                    AS stack,
            $1:instance                 AS instance,
            NULLIF(REGEXP_REPLACE(metadata$filename,
                '.*fileuploadrecords\/record_date\=(.*)\/.*', '\\1'),
                '__HIVE_DEFAULT_PARTITION__') AS record_date
        FROM @{{ stage_storage_integration }}_stage/fileuploadrecords
    )
    PATTERN = '.*fileuploadrecords/record_date=.*/.*';

CREATE OR ALTER TASK filesnapshots_task
    AFTER refresh_synapse_warehouse_s3_stage_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
    COPY INTO filesnapshots
    FROM (
        SELECT
            $1:change_type          AS change_type,
            $1:change_timestamp     AS change_timestamp,
            $1:change_user_id       AS change_user_id,
            $1:snapshot_timestamp   AS snapshot_timestamp,
            $1:id                   AS id,
            $1:created_by           AS created_by,
            $1:created_on           AS created_on,
            $1:modified_on          AS modified_on,
            $1:concrete_type        AS concrete_type,
            $1:content_md5          AS content_md5,
            $1:content_type         AS content_type,
            $1:file_name            AS file_name,
            $1:storage_location_id  AS storage_location_id,
            $1:content_size         AS content_size,
            $1:bucket               AS bucket,
            $1:key                  AS key,
            $1:preview_id           AS preview_id,
            $1:is_preview           AS is_preview,
            $1:status               AS status,
            NULLIF(REGEXP_REPLACE(metadata$filename,
                '.*filesnapshots\/snapshot_date\=(.*)\/.*', '\\1'),
                '__HIVE_DEFAULT_PARTITION__') AS snapshot_date
        FROM @{{ stage_storage_integration }}_stage/filesnapshots
    )
    PATTERN = '.*filesnapshots/snapshot_date=.*/.*';

CREATE OR ALTER TASK processedaccess_task
    AFTER refresh_synapse_warehouse_s3_stage_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
    COPY INTO processedaccess
    FROM (
        SELECT
            $1:session_id                   AS session_id,
            $1:timestamp                    AS timestamp,
            $1:user_id                      AS user_id,
            $1:method                       AS method,
            $1:request_url                  AS request_url,
            $1:user_agent                   AS user_agent,
            $1:host                         AS host,
            $1:origin                       AS origin,
            $1:x_forwarded_for              AS x_forwarded_for,
            $1:via                          AS via,
            $1:thread_id                    AS thread_id,
            $1:elapse_ms                    AS elapse_ms,
            $1:success                      AS success,
            $1:stack                        AS stack,
            $1:instance                     AS instance,
            $1:vm_id                        AS vm_id,
            $1:return_object_id             AS return_object_id,
            $1:query_string                 AS query_string,
            $1:response_status              AS response_status,
            $1:oauth_client_id              AS oauth_client_id,
            $1:basic_auth_username          AS basic_auth_username,
            $1:auth_method                  AS auth_method,
            $1:normalized_method_signature  AS normalized_method_signature,
            $1:client                       AS client,
            $1:client_version               AS client_version,
            $1:entity_id                    AS entity_id,
            NULLIF(REGEXP_REPLACE(metadata$filename,
                '.*processedaccessrecord\/record_date\=(.*)\/.*', '\\1'),
                '__HIVE_DEFAULT_PARTITION__') AS record_date
        FROM @{{ stage_storage_integration }}_stage/processedaccessrecord
    )
    PATTERN = '.*processedaccessrecord/record_date=.*/.*';

-- File handle associations use a dedicated stage (not the main warehouse stage)
CREATE OR ALTER TASK append_to_filehandleassociationsnapshots_task
    AFTER refresh_synapse_warehouse_s3_stage_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
    COPY INTO filehandleassociationsnapshots
    FROM (
        SELECT
            $1:associateid      AS associateid,
            $1:associatetype    AS associatetype,
            $1:filehandleid     AS filehandleid,
            $1:instance         AS instance,
            $1:stack            AS stack,
            $1:timestamp        AS timestamp
        FROM @synapse_filehandles_stage
    );

CREATE OR ALTER TASK append_to_certifiedquizsnapshot_task
    AFTER refresh_synapse_warehouse_s3_stage_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
    COPY INTO certifiedquizsnapshots
    FROM (
        SELECT
            $1:change_type          AS change_type,
            $1:change_timestamp     AS change_timestamp,
            $1:snapshot_timestamp   AS snapshot_timestamp,
            $1:response_id          AS response_id,
            $1:user_id              AS user_id,
            $1:passed               AS passed,
            $1:passed_on            AS passed_on,
            $1:stack                AS stack,
            $1:instance             AS instance,
            NULLIF(REGEXP_REPLACE(metadata$filename,
                '.*certifiedquizsnapshots\/snapshot_date\=(.*)\/.*', '\\1'),
                '__HIVE_DEFAULT_PARTITION__') AS snapshot_date,
            $1:revoked              AS revoked,
            $1:revoked_on           AS revoked_on,
            $1:certified            AS certified
        FROM @{{ stage_storage_integration }}_stage/certifiedquizsnapshots
    )
    PATTERN = '.*certifiedquizsnapshots/snapshot_date=.*/.*';

CREATE OR ALTER TASK append_to_certifiedquizquestionsnapshots_task
    AFTER refresh_synapse_warehouse_s3_stage_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
    COPY INTO certifiedquizquestionsnapshots
    FROM (
        SELECT
            $1:change_type          AS change_type,
            $1:change_timestamp     AS change_timestamp,
            $1:change_user_id       AS change_user_id,
            $1:snapshot_timestamp   AS snapshot_timestamp,
            $1:response_id          AS response_id,
            $1:question_index       AS question_index,
            $1:is_correct           AS is_correct,
            $1:stack                AS stack,
            $1:instance             AS instance,
            NULLIF(REGEXP_REPLACE(metadata$filename,
                '.*certifiedquizquestionsnapshots\/snapshot_date\=(.*)\/.*', '\\1'),
                '__HIVE_DEFAULT_PARTITION__') AS snapshot_date
        FROM @{{ stage_storage_integration }}_stage/certifiedquizquestionsnapshots
    )
    PATTERN = '.*certifiedquizquestionsnapshots/snapshot_date=.*/.*';

CREATE OR ALTER TASK append_to_accessrequirementsnapshot_task
    AFTER refresh_synapse_warehouse_s3_stage_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
    COPY INTO accessrequirementsnapshots
    FROM (
        SELECT
            $1:change_timestamp                 AS change_timestamp,
            $1:change_type                      AS change_type,
            $1:change_user_id                   AS change_user_id,
            $1:snapshot_timestamp               AS snapshot_timestamp,
            $1:id                               AS id,
            $1:version_number                   AS version_number,
            $1:name                             AS name,
            $1:description                      AS description,
            $1:created_by                       AS created_by,
            $1:modified_by                      AS modified_by,
            $1:created_on                       AS created_on,
            $1:modified_on                      AS modified_on,
            $1:access_type                      AS access_type,
            $1:concrete_type                    AS concrete_type,
            $1:subjects_defined_by_annotation   AS subjects_defined_by_annotation,
            $1:subjects_ids                     AS subjects_ids,
            $1:is_certified_user_required       AS is_certified_user_required,
            $1:is_validated_profile_required    AS is_validated_profile_required,
            $1:is_duc_required                  AS is_duc_required,
            $1:is_irb_approval_required         AS is_irb_approval_required,
            $1:are_other_attachments_required   AS are_other_attachments_required,
            $1:is_idu_public                    AS is_idu_public,
            $1:is_idu_required                  AS is_idu_required,
            $1:is_two_fa_required               AS is_two_fa_required,
            $1:duc_template_file_handle_id      AS duc_template_file_handle_id,
            $1:expiration_period                AS expiration_period,
            $1:terms_of_user                    AS terms_of_user,
            $1:act_contact_info                 AS act_contact_info,
            $1:open_jira_issue                  AS open_jira_issue,
            $1:jira_key                         AS jira_key,
            NULLIF(REGEXP_REPLACE(metadata$filename,
                '.*accessrequirementsnapshots\/snapshot_date\=(.*)\/.*', '\\1'),
                '__HIVE_DEFAULT_PARTITION__') AS snapshot_date
        FROM @{{ stage_storage_integration }}_stage/accessrequirementsnapshots
    )
    PATTERN = '.*accessrequirementsnapshots/snapshot_date=.*/.*';

CREATE OR ALTER TASK append_to_projectsettingsnapshots_task
    AFTER refresh_synapse_warehouse_s3_stage_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
    COPY INTO projectsettingsnapshots
    FROM (
        SELECT
            $1:change_timestamp     AS change_timestamp,
            $1:change_type          AS change_type,
            $1:change_user_id       AS change_user_id,
            $1:snapshot_timestamp   AS snapshot_timestamp,
            $1:id                   AS id,
            $1:concrete_type        AS concrete_type,
            $1:project_id           AS project_id,
            $1:settings_type        AS settings_type,
            $1:etag                 AS etag,
            $1:locations            AS locations,
            NULLIF(REGEXP_REPLACE(metadata$filename,
                '.*projectsettingsnapshots\/snapshot_date\=(.*)\/.*', '\\1'),
                '__HIVE_DEFAULT_PARTITION__') AS snapshot_date
        FROM @{{ stage_storage_integration }}_stage/projectsettingsnapshots
    )
    PATTERN = '.*projectsettingsnapshots/snapshot_date=.*/.*';

-- ── Downstream event clone tasks ─────────────────────────────

CREATE OR ALTER TASK create_fileupload_event_task
    AFTER fileupload_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
AS
    CREATE OR REPLACE TABLE {{ database_name }}.SYNAPSE_EVENT.fileupload_event
    CLONE {{ database_name }}.SYNAPSE_RAW.fileupload;

CREATE OR ALTER TASK create_access_event_task
    AFTER processedaccess_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
AS
    CREATE OR REPLACE TABLE {{ database_name }}.SYNAPSE_EVENT.access_event
    CLONE {{ database_name }}.SYNAPSE_RAW.processedaccess;

-- Resume the entire DAG
SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('refresh_synapse_warehouse_s3_stage_task');

-- ============================================================
-- SYNAPSE schema tasks (backup — manually resumed in prod only)
-- ============================================================

USE SCHEMA {{ database_name }}.SYNAPSE;

ALTER TASK IF EXISTS backup_synapse_data_warehouse_task SUSPEND;

CREATE OR ALTER TASK backup_synapse_data_warehouse_task
    SCHEDULE = 'USING CRON 0 3 * * 0 America/Los_Angeles'
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
AS
    CREATE OR REPLACE DATABASE backup_{{ database_name }}
    CLONE {{ database_name }};

CREATE OR ALTER TASK revoke_backup_synapse_access
    AFTER backup_synapse_data_warehouse_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
AS
    REVOKE USAGE
        ON DATABASE backup_{{ database_name }}
        FROM ROLE {{ database_name }}_analyst;

-- Backup tasks are left SUSPENDED; resume manually in prod after verifying clone works.
