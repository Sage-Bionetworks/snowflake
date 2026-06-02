USE SCHEMA {{database_name}}.RDS_LANDING; --noqa: JJ01,PRS,TMP

-- activity
CREATE TABLE IF NOT EXISTS activity (
    id                BIGINT  COMMENT 'Unique identifier for the activity record',
    etag              VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    created_by        BIGINT  COMMENT 'Identifier of the user who created this activity',
    created_on        BIGINT  COMMENT 'Epoch milliseconds when the activity was created',
    modified_by       BIGINT  COMMENT 'Identifier of the user who last modified this activity',
    modified_on       BIGINT  COMMENT 'Epoch milliseconds when the activity was last modified',
    serialized_object BINARY  COMMENT 'Serialized representation of the complete activity object'
);

-- agent_registration
CREATE TABLE IF NOT EXISTS agent_registration (
    registration_id BIGINT           COMMENT 'Unique identifier for the agent registration',
    aws_agent_id    VARCHAR          COMMENT 'AWS Bedrock agent identifier (10-character string)',
    aws_alias_id    VARCHAR          COMMENT 'AWS Bedrock agent alias identifier (10-character string)',
    created_on      TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the agent registration was created',
    agent_type      VARCHAR          COMMENT 'Type of agent. Valid values are CUSTOM or BASELINE'
);

-- agent_session
CREATE TABLE IF NOT EXISTS agent_session (
    id              BIGINT           COMMENT 'Unique identifier for the agent session',
    etag            VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    created_by      BIGINT           COMMENT 'Identifier of the user who created this session',
    created_on      TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the session was created',
    modified_on     TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the session was last modified',
    session_id      VARCHAR          COMMENT 'Unique session identifier (36-character UUID)',
    registration_id BIGINT           COMMENT 'The agent registration associated with this session',
    access_level    VARCHAR          COMMENT 'Access level granted to the agent. Valid values are PUBLICLY_ACCESSIBLE, READ_YOUR_PRIVATE_DATA, WRITE_YOUR_PRIVATE_DATA',
    context         VARCHAR          COMMENT 'JSON context data for the session'
);

-- agent_trace
CREATE TABLE IF NOT EXISTS agent_trace (
    job_id     BIGINT  COMMENT 'The asynchronous job identifier associated with this trace',
    time_stamp BIGINT  COMMENT 'Epoch milliseconds timestamp for this trace entry',
    message    VARCHAR COMMENT 'Trace message content from the agent'
);

-- asynch_job_status
CREATE TABLE IF NOT EXISTS asynch_job_status (
    job_id           BIGINT           COMMENT 'Unique identifier for the asynchronous job',
    etag             VARCHAR          COMMENT 'Entity tag for optimistic concurrency control',
    job_state        VARCHAR          COMMENT 'Current state of the job. Valid values are PROCESSING, FAILED, COMPLETE',
    job_type         VARCHAR          COMMENT 'Type of asynchronous job being executed',
    canceling        BOOLEAN          COMMENT 'Whether the job is in the process of being cancelled',
    exception        VARCHAR          COMMENT 'Exception class name if the job failed',
    error_message    VARCHAR          COMMENT 'Human-readable error message if the job failed',
    error_details    VARCHAR          COMMENT 'Detailed error information if the job failed',
    progress_current BIGINT           COMMENT 'Current progress count',
    progress_total   BIGINT           COMMENT 'Total progress count',
    progress_message VARCHAR          COMMENT 'Human-readable progress message',
    started_on       TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the job started',
    started_by       BIGINT           COMMENT 'Identifier of the user who started the job',
    changed_on       TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the job status was last changed',
    request_body     VARCHAR          COMMENT 'JSON body of the original request',
    response_body    VARCHAR          COMMENT 'JSON body of the job response when complete',
    runtime_ms       BIGINT           COMMENT 'Total runtime of the job in milliseconds',
    request_hash     VARCHAR          COMMENT 'Hash of the request body used for deduplication',
    context          VARCHAR          COMMENT 'JSON context data associated with the job'
);

-- authenticated_on
CREATE TABLE IF NOT EXISTS authenticated_on (
    principal_id     BIGINT           COMMENT 'The user principal identifier',
    authenticated_on TIMESTAMP_NTZ(9) COMMENT 'Timestamp of the last successful authentication',
    etag             VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);

-- authorization_consent
CREATE TABLE IF NOT EXISTS authorization_consent (
    id         BIGINT  COMMENT 'Unique identifier for the authorization consent record',
    etag       VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    user_id    BIGINT  COMMENT 'Identifier of the user granting consent',
    client_id  BIGINT  COMMENT 'Identifier of the OAuth client receiving consent',
    scope_hash VARCHAR COMMENT 'SHA-256 hash of the authorized OAuth scopes',
    granted_on BIGINT  COMMENT 'Epoch milliseconds when consent was granted'
);

-- bound_column_ordinal
CREATE TABLE IF NOT EXISTS bound_column_ordinal (
    column_id      BIGINT COMMENT 'The column model identifier',
    object_id      BIGINT COMMENT 'The entity or object this column is bound to',
    object_version BIGINT COMMENT 'The version of the object this column is bound to',
    ordinal        BIGINT COMMENT 'The ordinal position of this column within the object'
);

-- bound_column_owner
CREATE TABLE IF NOT EXISTS bound_column_owner (
    object_id BIGINT  COMMENT 'Unique identifier of the entity or object that owns bound columns',
    etag      VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);

-- certified_users
CREATE TABLE IF NOT EXISTS certified_users (
    user_id BIGINT COMMENT 'Identifier of the user who has passed the certification quiz'
);

-- challenge
CREATE TABLE IF NOT EXISTS challenge (
    id                BIGINT  COMMENT 'Unique identifier for the challenge',
    etag              VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    team_id           BIGINT  COMMENT 'Identifier of the team associated with this challenge',
    project_id        BIGINT  COMMENT 'Identifier of the Synapse project hosting this challenge',
    serialized_entity BINARY  COMMENT 'Serialized representation of the complete challenge object'
);

-- challenge_team
CREATE TABLE IF NOT EXISTS challenge_team (
    id                BIGINT  COMMENT 'Unique identifier for the challenge team registration',
    etag              VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    team_id           BIGINT  COMMENT 'Identifier of the team registered for the challenge',
    challenge_id      BIGINT  COMMENT 'Identifier of the challenge this team is registered for',
    serialized_entity BINARY  COMMENT 'Serialized representation of the complete challenge team object'
);

-- changes
CREATE TABLE IF NOT EXISTS changes (
    change_num     BIGINT           COMMENT 'Monotonically increasing change number',
    time_stamp     TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the change was recorded',
    object_id      BIGINT           COMMENT 'Identifier of the object that changed',
    object_version BIGINT           COMMENT 'Version of the object at the time of change',
    user_id        BIGINT           COMMENT 'Identifier of the user who caused the change',
    object_type    VARCHAR          COMMENT 'Type of object that changed (e.g., ENTITY, PRINCIPAL, TEAM)',
    change_type    VARCHAR          COMMENT 'Type of change. One of: CREATE, UPDATE, DELETE'
);

-- column_analyzer_override
CREATE TABLE IF NOT EXISTS column_analyzer_override (
    id                BIGINT           COMMENT 'Unique identifier for the column analyzer override',
    etag              VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    organization_name VARCHAR          COMMENT 'The organization that owns this override',
    name              VARCHAR          COMMENT 'Name of the column analyzer override within the organization',
    description       VARCHAR          COMMENT 'Optional description of this override',
    overrides         VARCHAR          COMMENT 'JSON configuration defining the column analyzer overrides',
    created_by        BIGINT           COMMENT 'Identifier of the user who created this override',
    created_on        TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the override was created',
    modified_by       BIGINT           COMMENT 'Identifier of the user who last modified this override',
    modified_on       TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the override was last modified'
);

-- column_model
CREATE TABLE IF NOT EXISTS column_model (
    id   BIGINT  COMMENT 'Unique identifier for the column model',
    name VARCHAR COMMENT 'Name of the column as it appears in Synapse tables',
    hash VARCHAR COMMENT 'Hash of the column definition used for deduplication',
    json VARCHAR COMMENT 'JSON definition of the column model including type, constraints, and defaults'
);

-- comment
CREATE TABLE IF NOT EXISTS comment (
    message_id  BIGINT  COMMENT 'Identifier of the message content for this comment',
    object_type VARCHAR COMMENT 'Type of Synapse object being commented on (e.g., ENTITY, EVALUATION)',
    object_id   BIGINT  COMMENT 'Identifier of the object being commented on'
);

-- credential
CREATE TABLE IF NOT EXISTS credential (
    principal_id BIGINT           COMMENT 'The user principal identifier',
    pass_hash    VARCHAR          COMMENT 'Hashed password for the user',
    modified_on  TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the credential was last modified',
    expires_on   TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the credential expires',
    etag         VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);

-- curation_task
CREATE TABLE IF NOT EXISTS curation_task (
    id                BIGINT           COMMENT 'Unique identifier for the curation task',
    data_type         VARCHAR          COMMENT 'Data type associated with this curation task',
    project_id        BIGINT           COMMENT 'Identifier of the project this curation task belongs to',
    instructions      VARCHAR          COMMENT 'Optional instructions for completing this task',
    etag              VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    created_by        BIGINT           COMMENT 'Identifier of the user who created this task',
    created_on        TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the task was created',
    modified_by       BIGINT           COMMENT 'Identifier of the user who last modified this task',
    modified_on       TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the task was last modified',
    task_properties   VARCHAR          COMMENT 'JSON properties specific to this task type',
    assignee          BIGINT           COMMENT 'Identifier of the user assigned to this task',
    state             VARCHAR          COMMENT 'Current state. One of: NOT_STARTED, IN_PROGRESS, COMPLETED, CANCELED',
    execution_details VARCHAR          COMMENT 'JSON details about task execution',
    state_updated_by  BIGINT           COMMENT 'Identifier of the user who last updated the task state',
    state_updated_on  TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the task state was last updated'
);

-- data_type
CREATE TABLE IF NOT EXISTS data_type (
    id          BIGINT  COMMENT 'Unique identifier for the data type assignment record',
    object_id   BIGINT  COMMENT 'Identifier of the object being assigned a data type',
    object_type VARCHAR COMMENT 'Type of object being assigned a data type (e.g., ENTITY)',
    data_type   VARCHAR COMMENT 'The data type classification. One of: SENSITIVE_DATA, OPEN_DATA',
    updated_by  BIGINT  COMMENT 'Identifier of the user who last updated this assignment',
    updated_on  BIGINT  COMMENT 'Epoch milliseconds when this assignment was last updated'
);

-- derived_annotations
CREATE TABLE IF NOT EXISTS derived_annotations (
    object_id   BIGINT  COMMENT 'Identifier of the Synapse object these annotations are derived for',
    anno_keys   VARCHAR COMMENT 'JSON array of annotation keys present on this object',
    annotations VARCHAR COMMENT 'JSON object containing the derived annotation key-value pairs'
);

-- discussion_reply
CREATE TABLE IF NOT EXISTS discussion_reply (
    id          BIGINT           COMMENT 'Unique identifier for the discussion reply',
    thread_id   BIGINT           COMMENT 'Identifier of the discussion thread this reply belongs to',
    etag        VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    created_on  TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the reply was created',
    created_by  BIGINT           COMMENT 'Identifier of the user who created this reply',
    modified_on TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the reply was last modified',
    message_key VARCHAR          COMMENT 'S3 key for the message content of this reply',
    is_edited   BOOLEAN          COMMENT 'Whether this reply has been edited after creation',
    is_deleted  BOOLEAN          COMMENT 'Whether this reply has been soft-deleted'
);

-- discussion_search_index
CREATE TABLE IF NOT EXISTS discussion_search_index (
    forum_id       BIGINT  COMMENT 'Identifier of the forum containing this indexed content',
    thread_id      BIGINT  COMMENT 'Identifier of the discussion thread',
    thread_deleted BOOLEAN COMMENT 'Whether the thread has been soft-deleted',
    reply_id       BIGINT  COMMENT 'Identifier of the discussion reply',
    reply_deleted  BOOLEAN COMMENT 'Whether the reply has been soft-deleted',
    search_content VARCHAR COMMENT 'Text content indexed for full-text search'
);

-- discussion_thread
CREATE TABLE IF NOT EXISTS discussion_thread (
    id          BIGINT           COMMENT 'Unique identifier for the discussion thread',
    forum_id    BIGINT           COMMENT 'Identifier of the forum this thread belongs to',
    title       BINARY           COMMENT 'Title of the discussion thread',
    etag        VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    created_on  TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the thread was created',
    created_by  BIGINT           COMMENT 'Identifier of the user who created this thread',
    modified_on TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the thread was last modified',
    message_key VARCHAR          COMMENT 'S3 key for the message content of this thread',
    is_edited   BOOLEAN          COMMENT 'Whether this thread has been edited after creation',
    is_deleted  BOOLEAN          COMMENT 'Whether this thread has been soft-deleted',
    is_pinned   BOOLEAN          COMMENT 'Whether this thread is pinned at the top of the forum'
);

-- discussion_thread_entity_reference
CREATE TABLE IF NOT EXISTS discussion_thread_entity_reference (
    thread_id BIGINT COMMENT 'Identifier of the discussion thread that references this entity',
    entity_id BIGINT COMMENT 'Identifier of the Synapse entity being referenced'
);

-- discussion_thread_stats
CREATE TABLE IF NOT EXISTS discussion_thread_stats (
    thread_id         BIGINT           COMMENT 'Identifier of the discussion thread these stats belong to',
    number_of_views   BIGINT           COMMENT 'Total number of views for this thread',
    number_of_replies BIGINT           COMMENT 'Total number of replies in this thread',
    last_activity     TIMESTAMP_NTZ(9) COMMENT 'Timestamp of the most recent activity in this thread',
    active_authors    VARCHAR          COMMENT 'Comma-separated list of user IDs who recently posted in this thread'
);

-- discussion_thread_submission_reference
CREATE TABLE IF NOT EXISTS discussion_thread_submission_reference (
    thread_id     BIGINT COMMENT 'Identifier of the discussion thread linked to a submission',
    submission_id BIGINT COMMENT 'Identifier of the evaluation submission this thread references'
);

-- discussion_thread_view
CREATE TABLE IF NOT EXISTS discussion_thread_view (
    thread_id BIGINT COMMENT 'Identifier of the discussion thread that was viewed',
    user_id   BIGINT COMMENT 'Identifier of the user who viewed the thread'
);

-- docker_commit
CREATE TABLE IF NOT EXISTS docker_commit (
    id         BIGINT  COMMENT 'Unique identifier for the Docker commit record',
    owner_id   BIGINT  COMMENT 'Identifier of the Docker repository node this commit belongs to',
    tag        VARCHAR COMMENT 'Docker image tag associated with this commit',
    digest     VARCHAR COMMENT 'Docker image digest (SHA256 hash) for this commit',
    created_on BIGINT  COMMENT 'Epoch milliseconds when this Docker commit was recorded'
);

-- docker_repository_name
CREATE TABLE IF NOT EXISTS docker_repository_name (
    owner_id        BIGINT  COMMENT 'Identifier of the Synapse node owning this Docker repository',
    repository_name VARCHAR COMMENT 'Full Docker repository name (e.g., docker.synapse.org/syn123/myrepo)'
);

-- doi
CREATE TABLE IF NOT EXISTS doi (
    id             BIGINT           COMMENT 'Unique identifier for the DOI record',
    etag           VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    doi_status     VARCHAR          COMMENT 'Current status of the DOI. One of: IN_PROCESS, CREATED, READY, ERROR',
    portal_id      BIGINT           COMMENT 'Identifier of the portal associated with this DOI',
    object_id      VARCHAR          COMMENT 'Identifier of the Synapse object this DOI refers to',
    object_type    VARCHAR          COMMENT 'Type of object this DOI refers to. One of: ENTITY, PORTAL_RESOURCE',
    object_version BIGINT           COMMENT 'Version of the object this DOI refers to',
    created_by     BIGINT           COMMENT 'Identifier of the user who created this DOI',
    created_on     TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the DOI was created',
    updated_by     BIGINT           COMMENT 'Identifier of the user who last updated this DOI',
    updated_on     TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the DOI was last updated'
);

-- download_list
CREATE TABLE IF NOT EXISTS download_list (
    principal_id BIGINT  COMMENT 'Identifier of the user who owns this download list',
    updated_on   BIGINT  COMMENT 'Epoch milliseconds when this download list was last updated',
    etag         VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);

-- download_list_item
CREATE TABLE IF NOT EXISTS download_list_item (
    principal_id           BIGINT  COMMENT 'Identifier of the user who owns this download list',
    associated_object_id   BIGINT  COMMENT 'Identifier of the entity in this download list item',
    associated_object_type VARCHAR COMMENT 'Type of associated object (e.g., FileEntity)',
    file_handle_id         BIGINT  COMMENT 'Identifier of the file handle to download'
);

-- download_list_item_v2
CREATE TABLE IF NOT EXISTS download_list_item_v2 (
    principal_id   BIGINT           COMMENT 'Identifier of the user who owns this download list',
    entity_id      BIGINT           COMMENT 'Identifier of the Synapse entity in this download list item',
    version_number BIGINT           COMMENT 'Version number of the entity to download. -1 indicates the latest version.',
    added_on       TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this item was added to the download list'
);

-- download_list_v2
CREATE TABLE IF NOT EXISTS download_list_v2 (
    principal_id BIGINT           COMMENT 'Identifier of the user who owns this download list',
    updated_on   TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this download list was last updated',
    etag         VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);

-- download_order
CREATE TABLE IF NOT EXISTS download_order (
    order_id         BIGINT  COMMENT 'Unique identifier for the download order',
    created_by       BIGINT  COMMENT 'Identifier of the user who created this order',
    created_on       BIGINT  COMMENT 'Epoch milliseconds when this order was created',
    file_name        VARCHAR COMMENT 'Name of the zip file for this download order',
    total_size_bytes BIGINT  COMMENT 'Total size in bytes of all files in this order',
    total_num_files  BIGINT  COMMENT 'Total number of files in this download order',
    files_blob       BINARY  COMMENT 'Serialized list of file references in this order'
);

-- evaluation
CREATE TABLE IF NOT EXISTS evaluation (
    id                              BIGINT  COMMENT 'Unique identifier for the evaluation',
    etag                            VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    name                            VARCHAR COMMENT 'Human-readable name of the evaluation',
    description                     BINARY  COMMENT 'Description of the evaluation',
    owner_id                        BIGINT  COMMENT 'Identifier of the user who owns this evaluation',
    created_on                      BIGINT  COMMENT 'Epoch milliseconds when the evaluation was created',
    content_source                  BIGINT  COMMENT 'Identifier of the Synapse project associated with this evaluation',
    status                          BIGINT  COMMENT 'Deprecated status field',
    submission_instructions_message BINARY  COMMENT 'Instructions message shown to submitters',
    submission_receipt_message      BINARY  COMMENT 'Receipt message shown after successful submission',
    quota_json                      VARCHAR COMMENT 'JSON object defining submission quotas',
    start_timestamp                 BIGINT  COMMENT 'Epoch milliseconds when submissions open',
    end_timestamp                   BIGINT  COMMENT 'Epoch milliseconds when submissions close'
);

-- evaluation_rounds
CREATE TABLE IF NOT EXISTS evaluation_rounds (
    id            BIGINT           COMMENT 'Unique identifier for the evaluation round',
    etag          VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    evaluation_id BIGINT           COMMENT 'Identifier of the evaluation this round belongs to',
    round_start   TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this evaluation round starts',
    round_end     TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this evaluation round ends',
    limits        VARCHAR          COMMENT 'JSON object defining submission limits for this round'
);

-- evaluation_submission
CREATE TABLE IF NOT EXISTS evaluation_submission (
    id                  BIGINT  COMMENT 'Unique identifier for the evaluation submission',
    name                VARCHAR COMMENT 'Name of the submission',
    evaluation_id       BIGINT  COMMENT 'Identifier of the evaluation this submission belongs to',
    evaluation_round_id BIGINT  COMMENT 'Identifier of the evaluation round this submission belongs to',
    user_id             BIGINT  COMMENT 'Identifier of the user who made this submission',
    submitter_alias     VARCHAR COMMENT 'Display alias of the submitter',
    entity_id           BIGINT  COMMENT 'Identifier of the Synapse entity being submitted',
    entity_bundle       BINARY  COMMENT 'Serialized snapshot of the entity bundle at submission time',
    entity_version      BIGINT  COMMENT 'Version of the submitted entity',
    created_on          BIGINT  COMMENT 'Epoch milliseconds when the submission was created',
    team_id             BIGINT  COMMENT 'Identifier of the team making this submission',
    docker_repo_name    VARCHAR COMMENT 'Docker repository name for Docker-based submissions',
    docker_digest       VARCHAR COMMENT 'Docker image digest for Docker-based submissions'
);

-- evaluation_submissions
CREATE TABLE IF NOT EXISTS evaluation_submissions (
    id      BIGINT  COMMENT 'Unique identifier for the evaluation submissions aggregate record',
    etag    VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    eval_id BIGINT  COMMENT 'Identifier of the evaluation this record tracks'
);

-- evaluation_submission_file
CREATE TABLE IF NOT EXISTS evaluation_submission_file (
    submission_id  BIGINT COMMENT 'Identifier of the evaluation submission',
    file_handle_id BIGINT COMMENT 'Identifier of the file handle associated with this submission'
);

-- evaluation_submission_status
CREATE TABLE IF NOT EXISTS evaluation_submission_status (
    id                BIGINT  COMMENT 'Identifier of the evaluation submission this status is for',
    etag              VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    substatus_version BIGINT  COMMENT 'Version number of this submission status',
    modified_on       BIGINT  COMMENT 'Epoch milliseconds when the status was last modified',
    status            BIGINT  COMMENT 'Integer status code for this submission',
    annotations       VARCHAR COMMENT 'JSON annotations associated with this status',
    score             FLOAT   COMMENT 'Numeric score assigned to this submission',
    entity_json       VARCHAR COMMENT 'JSON snapshot of the submitted entity'
);

-- favorite
CREATE TABLE IF NOT EXISTS favorite (
    favorite_id  BIGINT COMMENT 'Unique identifier for the favorite record',
    principal_id BIGINT COMMENT 'Identifier of the user who added this favorite',
    node_id      BIGINT COMMENT 'Identifier of the favorited Synapse entity',
    created_on   BIGINT COMMENT 'Epoch milliseconds when this favorite was added'
);

-- feature_status
CREATE TABLE IF NOT EXISTS feature_status (
    id           BIGINT  COMMENT 'Unique identifier for the feature status record',
    etag         VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    feature_type VARCHAR COMMENT 'Feature flag identifier (e.g., DATA_ACCESS_AUTO_REVOCATION, ENFORCE_PROJECT_STORAGE_LIMITS)',
    enabled      BOOLEAN COMMENT 'Whether the feature is currently enabled'
);

-- files
CREATE TABLE IF NOT EXISTS files (
    id                  BIGINT           COMMENT 'Unique identifier for the file handle',
    etag                VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    preview_id          BIGINT           COMMENT 'Identifier of the preview file handle for this file',
    created_on          TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the file handle was created',
    created_by          BIGINT           COMMENT 'Identifier of the user who created this file handle',
    updated_on          TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the file handle was last updated',
    metadata_type       VARCHAR          COMMENT 'Storage backend type. One of: S3, EXTERNAL, GOOGLE_CLOUD, PROXY, EXTERNAL_OBJ_STORE',
    content_type        VARCHAR          COMMENT 'MIME content type of the file',
    content_size        BIGINT           COMMENT 'Size of the file in bytes',
    content_md5         VARCHAR          COMMENT 'MD5 checksum of the file content',
    bucket_name         VARCHAR          COMMENT 'Storage bucket name where the file is stored',
    name                VARCHAR          COMMENT 'Original file name',
    key                 VARCHAR          COMMENT 'Storage key or path to the file within its bucket',
    storage_location_id BIGINT           COMMENT 'Identifier of the storage location for this file',
    endpoint            VARCHAR          COMMENT 'Endpoint URL for external storage locations',
    is_preview          BOOLEAN          COMMENT 'Whether this file handle is a preview of another file',
    status              VARCHAR          COMMENT 'Current status. One of: AVAILABLE, UNLINKED, ARCHIVED'
);

-- files_scanner_status
CREATE TABLE IF NOT EXISTS files_scanner_status (
    id                         BIGINT           COMMENT 'Unique identifier for the file scanner run',
    started_on                 TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the file scanner job started',
    updated_on                 TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the file scanner status was last updated',
    jobs_started_count         BIGINT           COMMENT 'Number of scan jobs started in this run',
    jobs_completed_count       BIGINT           COMMENT 'Number of scan jobs completed in this run',
    scanned_associations_count BIGINT           COMMENT 'Number of file associations scanned',
    relinked_files_count       BIGINT           COMMENT 'Number of files that were relinked during this scan'
);

-- form_data
CREATE TABLE IF NOT EXISTS form_data (
    id                BIGINT           COMMENT 'Unique identifier for the form data submission',
    etag              VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    name              VARCHAR          COMMENT 'Name of this form data submission',
    created_by        BIGINT           COMMENT 'Identifier of the user who created this form submission',
    created_on        TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the form submission was created',
    modified_on       TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the form submission was last modified',
    group_id          BIGINT           COMMENT 'Identifier of the form group this submission belongs to',
    file_handle_id    BIGINT           COMMENT 'Identifier of the file handle containing the form data',
    submitted_on      TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the form was submitted for review',
    reviewed_on       TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the form was reviewed',
    reviewed_by       BIGINT           COMMENT 'Identifier of the user who reviewed this form submission',
    state             VARCHAR          COMMENT 'Current state. One of: WAITING_FOR_SUBMISSION, SUBMITTED_WAITING_FOR_REVIEW, ACCEPTED, REJECTED',
    rejection_message VARCHAR          COMMENT 'Message explaining why the form was rejected'
);

-- form_group
CREATE TABLE IF NOT EXISTS form_group (
    group_id   BIGINT           COMMENT 'Unique identifier for the form group',
    name       VARCHAR          COMMENT 'Unique name of the form group',
    created_by BIGINT           COMMENT 'Identifier of the user who created this form group',
    created_on TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the form group was created'
);

-- forum
CREATE TABLE IF NOT EXISTS forum (
    id          BIGINT  COMMENT 'Unique identifier for the forum',
    object_id   BIGINT  COMMENT 'Identifier of the Synapse object this forum is associated with',
    object_type VARCHAR COMMENT 'Type of object this forum belongs to. One of: ENTITY, ACCESS_REQUIREMENT',
    etag        VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);

-- grid_connection
CREATE TABLE IF NOT EXISTS grid_connection (
    id            BIGINT           COMMENT 'Unique identifier for the grid connection',
    connection_id VARCHAR          COMMENT 'Unique connection identifier (36-character UUID)',
    session_id    VARCHAR          COMMENT 'Identifier of the grid session this connection belongs to',
    replica_id    BIGINT           COMMENT 'Identifier of the grid replica this connection is attached to',
    created_by    BIGINT           COMMENT 'Identifier of the user who created this connection',
    created_on    TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the connection was created',
    source        VARCHAR          COMMENT 'Source type. One of: WEBSOCKET, INTERNAL, VALIDATION, AGENT, USER_SUPPORT, API'
);

-- grid_patch
CREATE TABLE IF NOT EXISTS grid_patch (
    id               BIGINT           COMMENT 'Unique identifier for the grid patch',
    session_id       VARCHAR          COMMENT 'Identifier of the grid session this patch belongs to',
    patch_id_rep     BIGINT           COMMENT 'Replica-scoped patch identifier',
    patch_id_seq     BIGINT           COMMENT 'Sequence number of this patch within the replica',
    created_on       TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the patch was created',
    expires_on       TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the patch expires',
    s3_key           VARCHAR          COMMENT 'S3 key where the patch data is stored',
    size_bytes       BIGINT           COMMENT 'Size of the patch in bytes'
);

-- grid_replica
CREATE TABLE IF NOT EXISTS grid_replica (
    id         BIGINT           COMMENT 'Unique identifier for the grid replica',
    replica_id BIGINT           COMMENT 'Replica identifier scoped to the session',
    created_by BIGINT           COMMENT 'Identifier of the user who created this replica',
    created_on TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the replica was created',
    session_id VARCHAR          COMMENT 'Identifier of the grid session this replica belongs to',
    is_agent   BOOLEAN          COMMENT 'Whether this replica represents an AI agent participant'
);

-- grid_session
CREATE TABLE IF NOT EXISTS grid_session (
    id                 BIGINT           COMMENT 'Unique identifier for the grid session',
    etag               VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    created_by         BIGINT           COMMENT 'Identifier of the user who created this session',
    created_on         TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the session was created',
    modified_on        TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the session was last modified',
    session_id         VARCHAR          COMMENT 'Unique session identifier (36-character UUID)',
    rep_id_client      BIGINT           COMMENT 'Replica ID assigned to the client',
    rep_id_service     BIGINT           COMMENT 'Replica ID assigned to the service',
    source_id          BIGINT           COMMENT 'Identifier of the source Synapse node for this session',
    schema_id          VARCHAR          COMMENT 'JSON schema identifier associated with this session',
    owner_id           BIGINT           COMMENT 'Identifier of the user who owns this session',
    authorization_mode VARCHAR          COMMENT 'Authorization mode. One of: SESSION_OWNER, SOURCE_BENEFACTOR',
    benefactor_ids     VARCHAR          COMMENT 'JSON array of benefactor entity IDs for authorization'
);

-- grid_snapshot
CREATE TABLE IF NOT EXISTS grid_snapshot (
    id         BIGINT           COMMENT 'Unique identifier for the grid snapshot',
    session_id VARCHAR          COMMENT 'Identifier of the grid session this snapshot belongs to',
    clock_table VARCHAR         COMMENT 'JSON object containing the vector clock state at snapshot time',
    created_on TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the snapshot was taken',
    created_by BIGINT           COMMENT 'Identifier of the user who triggered the snapshot',
    s3_key     VARCHAR          COMMENT 'S3 key where the snapshot data is stored'
);

-- group_members
CREATE TABLE IF NOT EXISTS group_members (
    group_id  BIGINT COMMENT 'Identifier of the group (team or user group)',
    member_id BIGINT COMMENT 'Identifier of the member being added to the group'
);

-- json_schema
CREATE TABLE IF NOT EXISTS json_schema (
    schema_id       BIGINT           COMMENT 'Unique identifier for the JSON schema',
    organization_id BIGINT           COMMENT 'Identifier of the organization that owns this schema',
    schema_name     VARCHAR          COMMENT 'Name of the schema within the organization',
    created_by      BIGINT           COMMENT 'Identifier of the user who created this schema',
    created_on      TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the schema was created'
);

-- json_schema_blob
CREATE TABLE IF NOT EXISTS json_schema_blob (
    blob_id     BIGINT  COMMENT 'Unique identifier for the JSON schema blob',
    json_blob   VARCHAR COMMENT 'The raw JSON schema content',
    sha_256_hex VARCHAR COMMENT 'SHA-256 hex digest of the JSON schema blob for deduplication'
);

-- json_schema_dependency
CREATE TABLE IF NOT EXISTS json_schema_dependency (
    version_id            BIGINT COMMENT 'The JSON schema version that has this dependency',
    depends_on_schema_id  BIGINT COMMENT 'Identifier of the schema this version depends on',
    depends_on_version_id BIGINT COMMENT 'Specific version of the dependent schema. NULL means any version.'
);

-- json_schema_latest_version
CREATE TABLE IF NOT EXISTS json_schema_latest_version (
    schema_id  BIGINT  COMMENT 'Identifier of the JSON schema',
    etag       VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    version_id BIGINT  COMMENT 'Identifier of the latest version of this schema'
);

-- json_schema_object_binding
CREATE TABLE IF NOT EXISTS json_schema_object_binding (
    bind_id        BIGINT           COMMENT 'Unique identifier for this schema-to-object binding',
    schema_id      BIGINT           COMMENT 'Identifier of the JSON schema bound to this object',
    version_id     BIGINT           COMMENT 'Specific schema version bound. NULL means the latest version.',
    object_id      BIGINT           COMMENT 'Identifier of the Synapse object bound to this schema',
    object_type    VARCHAR          COMMENT 'Type of object bound to this schema (e.g., entity)',
    created_by     BIGINT           COMMENT 'Identifier of the user who created this binding',
    created_on     TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the binding was created',
    enable_derived BOOLEAN          COMMENT 'Whether derived annotations should be computed from this binding'
);

-- json_schema_validation_results
CREATE TABLE IF NOT EXISTS json_schema_validation_results (
    object_id            BIGINT           COMMENT 'Identifier of the object that was validated',
    object_type          VARCHAR          COMMENT 'Type of object that was validated (e.g., entity)',
    object_etag          VARCHAR          COMMENT 'Etag of the object at the time of validation (36-character UUID)',
    schema_id            VARCHAR          COMMENT 'Full schema identifier used for validation',
    is_valid             BOOLEAN          COMMENT 'Whether the object passed validation',
    validated_on         TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the validation was performed',
    error_message        VARCHAR          COMMENT 'Top-level error message if validation failed',
    all_error_messages   VARCHAR          COMMENT 'JSON array of all validation error messages',
    validation_exception VARCHAR          COMMENT 'JSON details of any exception thrown during validation'
);

-- json_schema_version
CREATE TABLE IF NOT EXISTS json_schema_version (
    version_id       BIGINT           COMMENT 'Unique identifier for this schema version',
    schema_id        BIGINT           COMMENT 'Identifier of the schema this version belongs to',
    semantic_version VARCHAR          COMMENT 'Semantic version string (e.g., 1.0.0). NULL for unversioned schemas.',
    created_by       BIGINT           COMMENT 'Identifier of the user who created this version',
    created_on       TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this version was created',
    blob_id          BIGINT           COMMENT 'Identifier of the JSON schema blob for this version'
);

-- materialized_view_id
CREATE TABLE IF NOT EXISTS materialized_view_id (
    materialized_view_id BIGINT  COMMENT 'Identifier of the Synapse materialized view node',
    etag                 VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);

-- materialized_view_source_tables
CREATE TABLE IF NOT EXISTS materialized_view_source_tables (
    materialized_view_id      BIGINT COMMENT 'Identifier of the materialized view',
    materialized_view_version BIGINT COMMENT 'Version of the materialized view this snapshot refers to',
    source_table_id           BIGINT COMMENT 'Identifier of a source table used by this materialized view version',
    source_table_version      BIGINT COMMENT 'Version of the source table at the time the materialized view was built'
);

-- membership_invitation_submission
CREATE TABLE IF NOT EXISTS membership_invitation_submission (
    id            BIGINT  COMMENT 'Unique identifier for the membership invitation',
    etag          VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    team_id       BIGINT  COMMENT 'Identifier of the team the user is being invited to',
    invitee_id    BIGINT  COMMENT 'User ID of the person being invited. NULL if invited by email.',
    invitee_email VARCHAR COMMENT 'Email address of the person being invited. NULL if invited by user ID.',
    created_on    BIGINT  COMMENT 'Epoch milliseconds when the invitation was created',
    expires_on    BIGINT  COMMENT 'Epoch milliseconds when the invitation expires',
    properties    BINARY  COMMENT 'Serialized additional properties of the invitation'
);

-- membership_request_submission
CREATE TABLE IF NOT EXISTS membership_request_submission (
    id         BIGINT  COMMENT 'Unique identifier for the membership request',
    team_id    BIGINT  COMMENT 'Identifier of the team the user is requesting to join',
    created_on BIGINT  COMMENT 'Epoch milliseconds when the request was created',
    user_id    BIGINT  COMMENT 'Identifier of the user requesting membership',
    expires_on BIGINT  COMMENT 'Epoch milliseconds when the request expires',
    properties BINARY  COMMENT 'Serialized additional properties of the membership request'
);

-- message_broadcast
CREATE TABLE IF NOT EXISTS message_broadcast (
    change_number BIGINT COMMENT 'Change number of the message that was broadcast',
    sent_on       BIGINT COMMENT 'Epoch milliseconds when the broadcast was sent'
);

-- message_content
CREATE TABLE IF NOT EXISTS message_content (
    id             BIGINT  COMMENT 'Unique identifier for the message content',
    created_by     BIGINT  COMMENT 'Identifier of the user who created this message',
    file_handle_id BIGINT  COMMENT 'Identifier of the file handle containing the message body',
    created_on     BIGINT  COMMENT 'Epoch milliseconds when this message was created',
    etag           VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);

-- message_recipient
CREATE TABLE IF NOT EXISTS message_recipient (
    message_id   BIGINT COMMENT 'Identifier of the message',
    recipient_id BIGINT COMMENT 'Identifier of the user who is a recipient of this message'
);

-- message_status
CREATE TABLE IF NOT EXISTS message_status (
    message_id   BIGINT  COMMENT 'Identifier of the message',
    recipient_id BIGINT  COMMENT 'Identifier of the user this status is for',
    status       VARCHAR COMMENT 'Read status for this recipient. One of: READ, UNREAD, ARCHIVED'
);

-- message_to_user
CREATE TABLE IF NOT EXISTS message_to_user (
    message_id                     BIGINT  COMMENT 'Identifier of the message content',
    root_message_id                BIGINT  COMMENT 'Identifier of the root message in this thread',
    in_reply_to                    BIGINT  COMMENT 'Identifier of the message this is a reply to',
    subject                        BINARY  COMMENT 'Subject line of the message',
    notifications_endpoint         VARCHAR COMMENT 'Endpoint URL for the notifications portal link in the message',
    profile_setting_endpoint       VARCHAR COMMENT 'Endpoint URL for the profile settings link in the message',
    with_unsubscribe_link          BOOLEAN COMMENT 'Whether to include an unsubscribe link in the message',
    with_profile_setting_link      BOOLEAN COMMENT 'Whether to include a profile settings link in the message',
    is_notification_message        BOOLEAN COMMENT 'Whether this message is a system notification',
    override_notification_settings BOOLEAN COMMENT 'Whether to send regardless of the recipient notification settings',
    to                             BINARY  COMMENT 'Serialized list of primary recipients',
    cc                             BINARY  COMMENT 'Serialized list of CC recipients',
    bcc                            BINARY  COMMENT 'Serialized list of BCC recipients',
    sent                           BOOLEAN COMMENT 'Whether this message has been sent'
);

-- multipart_upload
CREATE TABLE IF NOT EXISTS multipart_upload (
    id                    BIGINT           COMMENT 'Unique identifier for the multipart upload',
    request_hash          VARCHAR          COMMENT 'Hash of the upload request used for deduplication',
    etag                  VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    request_blob          BINARY           COMMENT 'Serialized upload request object',
    started_by            BIGINT           COMMENT 'Identifier of the user who started this upload',
    started_on            TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the upload was initiated',
    updated_on            TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the upload was last updated',
    file_handle_id        BIGINT           COMMENT 'Identifier of the resulting file handle when upload is complete',
    state                 VARCHAR          COMMENT 'Current state. One of: UPLOADING, COMPLETED',
    upload_token          VARCHAR          COMMENT 'Token identifying this upload session',
    upload_type           VARCHAR          COMMENT 'Type of upload (e.g., S3, Google Cloud)',
    bucket                VARCHAR          COMMENT 'Storage bucket for this upload',
    file_key              VARCHAR          COMMENT 'Storage key for the final file in its bucket',
    number_of_parts       BIGINT           COMMENT 'Total number of parts in this multipart upload',
    request_type          VARCHAR          COMMENT 'Whether this is a new upload or a copy. One of: UPLOAD, COPY',
    part_size             BIGINT           COMMENT 'Size of each part in bytes',
    source_file_handle_id BIGINT           COMMENT 'Identifier of the source file handle for copy uploads',
    source_file_etag      VARCHAR          COMMENT 'Etag of the source file handle for copy uploads'
);

-- multipart_upload_composer_part_state
CREATE TABLE IF NOT EXISTS multipart_upload_composer_part_state (
    upload_id              BIGINT COMMENT 'Identifier of the multipart upload',
    part_range_lower_bound BIGINT COMMENT 'Lower bound (inclusive) of the composer part range',
    part_range_upper_bound BIGINT COMMENT 'Upper bound (inclusive) of the composer part range'
);

-- multipart_upload_part_state
CREATE TABLE IF NOT EXISTS multipart_upload_part_state (
    upload_id     BIGINT  COMMENT 'Identifier of the multipart upload',
    part_number   BIGINT  COMMENT 'Part number within the multipart upload',
    part_md5_hex  VARCHAR COMMENT 'MD5 hex digest of the uploaded part',
    error_details BINARY  COMMENT 'Details of any error that occurred while uploading this part'
);

-- node
CREATE TABLE IF NOT EXISTS node (
    id              BIGINT  COMMENT 'Unique identifier for the Synapse entity (node)',
    created_by      BIGINT  COMMENT 'Identifier of the user who created this entity',
    created_on      BIGINT  COMMENT 'Epoch milliseconds when this entity was created',
    current_rev_num BIGINT  COMMENT 'Current revision number of this entity',
    max_rev_num     BIGINT  COMMENT 'Maximum revision number ever assigned to this entity',
    etag            VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    name            VARCHAR COMMENT 'Name of the entity',
    node_type       VARCHAR COMMENT 'Type of entity (e.g., project, folder, file, table, entityview)',
    parent_id       BIGINT  COMMENT 'Identifier of the parent entity. NULL for root projects.',
    alias           VARCHAR COMMENT 'Optional unique alias for this entity'
);

-- node_access_requirement
CREATE TABLE IF NOT EXISTS node_access_requirement (
    subject_id     BIGINT  COMMENT 'Identifier of the subject (entity, evaluation, or team) bound to this requirement',
    subject_type   VARCHAR COMMENT 'Type of subject. One of: ENTITY, EVALUATION, TEAM',
    requirement_id BIGINT  COMMENT 'Identifier of the access requirement bound to this subject',
    binding_type   VARCHAR COMMENT 'How the requirement was bound. One of: DYNAMIC, MANUAL'
);

-- node_revision
CREATE TABLE IF NOT EXISTS node_revision (
    owner_node_id                 BIGINT  COMMENT 'Identifier of the node this revision belongs to',
    number                        BIGINT  COMMENT 'Revision number for this version of the node',
    activity_id                   BIGINT  COMMENT 'Identifier of the provenance activity for this revision',
    entity_property_annotations   BINARY  COMMENT 'Serialized entity-specific property annotations',
    user_annotations              VARCHAR COMMENT 'JSON user-defined annotations on this revision',
    description                   VARCHAR COMMENT 'Description of this revision',
    comment                       VARCHAR COMMENT 'Comment about this revision',
    label                         VARCHAR COMMENT 'Version label for this revision',
    modified_by                   BIGINT  COMMENT 'Identifier of the user who created this revision',
    modified_on                   BIGINT  COMMENT 'Epoch milliseconds when this revision was created',
    file_handle_id                BIGINT  COMMENT 'Identifier of the file handle for file entities',
    column_model_ids              BINARY  COMMENT 'Serialized list of column model IDs for table entities',
    scope_ids                     BINARY  COMMENT 'Serialized list of scope IDs for view entities',
    items                         VARCHAR COMMENT 'JSON list of items for dataset or collection entities',
    search_enabled                BOOLEAN COMMENT 'Whether search indexing is enabled for this entity revision',
    defining_sql                  VARCHAR COMMENT 'SQL definition for virtual table or materialized view entities',
    reference_json                VARCHAR COMMENT 'JSON reference details for link entities',
    upsert_key                    VARCHAR COMMENT 'JSON upsert key definition for table entities',
    csv_descriptor                VARCHAR COMMENT 'JSON CSV descriptor for table uploads',
    validation_res_file_handle_id BIGINT  COMMENT 'Identifier of the file handle containing validation results'
);

-- notification_email
CREATE TABLE IF NOT EXISTS notification_email (
    id           BIGINT  COMMENT 'Unique identifier for the notification email record',
    etag         VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    principal_id BIGINT  COMMENT 'Identifier of the user this notification email is for',
    alias_id     BIGINT  COMMENT 'Identifier of the principal alias representing the notification email address'
);

-- oauth_access_token
CREATE TABLE IF NOT EXISTS oauth_access_token (
    id               BIGINT           COMMENT 'Unique identifier for the OAuth access token record',
    token_id         VARCHAR          COMMENT 'Unique token identifier (36-character UUID)',
    refresh_token_id BIGINT           COMMENT 'Identifier of the refresh token this access token was issued from',
    principal_id     BIGINT           COMMENT 'Identifier of the user this token was issued to',
    client_id        BIGINT           COMMENT 'Identifier of the OAuth client this token was issued to',
    created_on       TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this access token was created',
    expires_on       TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this access token expires',
    session_id       VARCHAR          COMMENT 'Session identifier associated with this token'
);

-- oauth_authorization_code
CREATE TABLE IF NOT EXISTS oauth_authorization_code (
    auth_code             VARCHAR COMMENT 'The authorization code value',
    authorization_request BINARY  COMMENT 'Serialized OAuth authorization request associated with this code'
);

-- oauth_client
CREATE TABLE IF NOT EXISTS oauth_client (
    id                          BIGINT  COMMENT 'Unique identifier for the OAuth client',
    name                        VARCHAR COMMENT 'Unique display name of the OAuth client',
    secret_hash                 VARCHAR COMMENT 'Hashed client secret',
    oauth_sector_identifier_uri VARCHAR COMMENT 'Sector identifier URI for pairwise subject identifiers',
    is_verified                 BOOLEAN COMMENT 'Whether this OAuth client has been verified by Synapse administrators',
    json                        VARCHAR COMMENT 'JSON object containing the full OAuth client registration details',
    created_by                  BIGINT  COMMENT 'Identifier of the user who registered this OAuth client',
    created_on                  BIGINT  COMMENT 'Epoch milliseconds when this OAuth client was created',
    modified_on                 BIGINT  COMMENT 'Epoch milliseconds when this OAuth client was last modified',
    etag                        VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);

-- oauth_refresh_token
CREATE TABLE IF NOT EXISTS oauth_refresh_token (
    id           BIGINT           COMMENT 'Unique identifier for the OAuth refresh token record',
    token_hash   VARCHAR          COMMENT 'SHA-256 hash of the refresh token value',
    name         VARCHAR          COMMENT 'User-assigned name for this refresh token',
    principal_id BIGINT           COMMENT 'Identifier of the user this token was issued to',
    client_id    BIGINT           COMMENT 'Identifier of the OAuth client this token was issued for',
    scopes_json  VARCHAR          COMMENT 'JSON array of OAuth scopes this token is authorized for',
    claims_json  VARCHAR          COMMENT 'JSON object of additional claims associated with this token',
    last_used    TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this refresh token was last used',
    created_on   TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this refresh token was created',
    modified_on  TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this refresh token was last modified',
    etag         VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);

-- oauth_sector_identifier
CREATE TABLE IF NOT EXISTS oauth_sector_identifier (
    id         BIGINT  COMMENT 'Unique identifier for the sector identifier record',
    uri        VARCHAR COMMENT 'The sector identifier URI',
    secret     VARCHAR COMMENT 'Secret used for pairwise subject identifier generation',
    created_by BIGINT  COMMENT 'Identifier of the user who registered this sector identifier',
    created_on BIGINT  COMMENT 'Epoch milliseconds when this sector identifier was registered'
);

-- organization
CREATE TABLE IF NOT EXISTS organization (
    id         BIGINT           COMMENT 'Unique identifier for the organization',
    name       VARCHAR          COMMENT 'Unique name of the organization (ASCII, used in schema $id paths)',
    created_by BIGINT           COMMENT 'Identifier of the user who created this organization',
    created_on TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the organization was created'
);

-- otp_recovery_code
CREATE TABLE IF NOT EXISTS otp_recovery_code (
    secret_id  BIGINT           COMMENT 'Identifier of the OTP secret these recovery codes belong to',
    code_hash  VARCHAR          COMMENT 'Hashed value of the recovery code',
    created_on TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this recovery code was generated'
);

-- otp_secret
CREATE TABLE IF NOT EXISTS otp_secret (
    id           BIGINT           COMMENT 'Unique identifier for the OTP secret',
    etag         VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    principal_id BIGINT           COMMENT 'Identifier of the user this OTP secret belongs to',
    created_on   TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the OTP secret was created',
    secret       VARCHAR          COMMENT 'Base32-encoded TOTP secret key',
    active       BOOLEAN          COMMENT 'Whether this OTP secret is currently active for the user'
);

-- personal_access_token
CREATE TABLE IF NOT EXISTS personal_access_token (
    id           BIGINT           COMMENT 'Unique identifier for the personal access token',
    name         VARCHAR          COMMENT 'User-assigned name for this personal access token',
    principal_id BIGINT           COMMENT 'Identifier of the user this token belongs to',
    scopes       BINARY           COMMENT 'Serialized list of OAuth scopes this token is authorized for',
    claims       BINARY           COMMENT 'Serialized additional claims associated with this token',
    last_used    TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this token was last used',
    created_on   TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this token was created'
);

-- portal
CREATE TABLE IF NOT EXISTS portal (
    id          BIGINT           COMMENT 'Unique identifier for the portal',
    etag        VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    created_by  BIGINT           COMMENT 'Identifier of the user who created this portal',
    created_on  TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the portal was created',
    modified_by BIGINT           COMMENT 'Identifier of the user who last modified this portal',
    modified_on TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the portal was last modified',
    name        VARCHAR          COMMENT 'Unique name of the portal',
    endpoint    VARCHAR          COMMENT 'Unique base URL endpoint for this portal'
);

-- principal_oidc_binding
CREATE TABLE IF NOT EXISTS principal_oidc_binding (
    id           BIGINT           COMMENT 'Unique identifier for this OIDC identity binding',
    etag         VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    created_on   TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this binding was created',
    principal_id BIGINT           COMMENT 'Identifier of the Synapse user this binding belongs to',
    alias_id     BIGINT           COMMENT 'Identifier of the principal alias associated with this binding',
    provider     VARCHAR          COMMENT 'Identity provider for this binding (e.g., GOOGLE_OAUTH_2_0, ORCID)',
    subject      VARCHAR          COMMENT 'Subject identifier from the identity provider'
);

-- principal_prefix
CREATE TABLE IF NOT EXISTS principal_prefix (
    token        VARCHAR COMMENT 'Prefix token used for autocomplete lookups',
    principal_id BIGINT  COMMENT 'Identifier of the user or team this prefix belongs to'
);

-- processed_messages
CREATE TABLE IF NOT EXISTS processed_messages (
    change_num BIGINT           COMMENT 'Change number of the processed message',
    time_stamp TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the message was processed',
    queue_name VARCHAR          COMMENT 'Name of the message queue that processed this change'
);

-- project_setting
CREATE TABLE IF NOT EXISTS project_setting (
    id         BIGINT  COMMENT 'Unique identifier for the project setting',
    project_id BIGINT  COMMENT 'Identifier of the project this setting belongs to',
    type       VARCHAR COMMENT 'Type of project setting (e.g., upload)',
    etag       VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    json       VARCHAR COMMENT 'JSON object containing the project setting configuration'
);

-- project_stat
CREATE TABLE IF NOT EXISTS project_stat (
    id            BIGINT  COMMENT 'Unique identifier for the project stat record',
    project_id    BIGINT  COMMENT 'Identifier of the project',
    user_id       BIGINT  COMMENT 'Identifier of the user this stat is for',
    last_accessed BIGINT  COMMENT 'Epoch milliseconds when this user last accessed this project',
    etag          VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);

-- project_storage_data
CREATE TABLE IF NOT EXISTS project_storage_data (
    project_id            BIGINT           COMMENT 'Identifier of the project these storage metrics are for',
    etag                  VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    modified_on           TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the storage data was last computed',
    runtime_ms            BIGINT           COMMENT 'Time in milliseconds taken to compute the storage data',
    storage_location_data VARCHAR          COMMENT 'JSON array of storage usage by storage location'
);

-- project_storage_limit
CREATE TABLE IF NOT EXISTS project_storage_limit (
    id                  BIGINT           COMMENT 'Unique identifier for the storage limit record',
    etag                VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    created_by          BIGINT           COMMENT 'Identifier of the user who created this limit',
    created_on          TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the limit was created',
    modified_by         BIGINT           COMMENT 'Identifier of the user who last modified this limit',
    modified_on         TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the limit was last modified',
    project_id          BIGINT           COMMENT 'Identifier of the project this limit applies to',
    storage_location_id BIGINT           COMMENT 'Identifier of the storage location this limit applies to',
    max_bytes           BIGINT           COMMENT 'Maximum allowed storage in bytes. NULL means no limit.'
);

-- quarantined_emails
CREATE TABLE IF NOT EXISTS quarantined_emails (
    id             BIGINT           COMMENT 'Unique identifier for the quarantined email record',
    email          VARCHAR          COMMENT 'The email address that has been quarantined',
    etag           VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    created_on     TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this email was first quarantined',
    updated_on     TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this quarantine record was last updated',
    expires_on     TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the quarantine expires. NULL means permanent.',
    reason         VARCHAR          COMMENT 'Reason for quarantine. One of: PERMANENT_BOUNCE, TRANSIENT_BOUNCE, COMPLAINT, OTHER',
    reason_details VARCHAR          COMMENT 'Additional details about why this email was quarantined',
    ses_message_id VARCHAR          COMMENT 'AWS SES message ID that triggered this quarantine'
);

-- quiz_response
CREATE TABLE IF NOT EXISTS quiz_response (
    id            BIGINT  COMMENT 'Unique identifier for the quiz response',
    etag          VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    created_by    BIGINT  COMMENT 'Identifier of the user who submitted this quiz response',
    created_on    BIGINT  COMMENT 'Epoch milliseconds when this response was submitted',
    revoked_on    BIGINT  COMMENT 'Epoch milliseconds when this passing record was revoked. NULL if not revoked.',
    quiz_id       BIGINT  COMMENT 'Identifier of the quiz this response is for',
    score         BIGINT  COMMENT 'Score achieved on the quiz',
    passed        BOOLEAN COMMENT 'Whether the user passed the quiz',
    response_json VARCHAR COMMENT 'JSON object containing all question responses',
    passing_json  VARCHAR COMMENT 'JSON object containing the passing record details'
);

-- recordset_validation_stats
CREATE TABLE IF NOT EXISTS recordset_validation_stats (
    id                BIGINT  COMMENT 'Unique identifier for the validation stats record',
    etag              VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    recordset_id      BIGINT  COMMENT 'Identifier of the record set that was validated',
    recordset_version BIGINT  COMMENT 'Version of the record set that was validated',
    stats_json        VARCHAR COMMENT 'JSON object containing the validation statistics'
);

-- research_project
CREATE TABLE IF NOT EXISTS research_project (
    id                    BIGINT  COMMENT 'Unique identifier for the research project',
    access_requirement_id BIGINT  COMMENT 'Identifier of the access requirement this research project is associated with',
    created_by            BIGINT  COMMENT 'Identifier of the user who created this research project',
    created_on            BIGINT  COMMENT 'Epoch milliseconds when the research project was created',
    modified_by           BIGINT  COMMENT 'Identifier of the user who last modified this research project',
    modified_on           BIGINT  COMMENT 'Epoch milliseconds when the research project was last modified',
    etag                  VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    project_lead          VARCHAR COMMENT 'Name of the principal investigator or project lead',
    institution           VARCHAR COMMENT 'Name of the institution affiliated with this research project',
    idu                   BINARY  COMMENT 'Intended data use statement for this research project'
);

-- search_configuration
CREATE TABLE IF NOT EXISTS search_configuration (
    id                       BIGINT           COMMENT 'Unique identifier for the search configuration',
    etag                     VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    organization_name        VARCHAR          COMMENT 'Name of the organization that owns this search configuration',
    name                     VARCHAR          COMMENT 'Name of this search configuration within the organization',
    description              VARCHAR          COMMENT 'Optional description of this search configuration',
    default_analyzer         VARCHAR          COMMENT 'JSON configuration for the default text analyzer',
    column_analyzer_overrides VARCHAR         COMMENT 'JSON configuration for per-column analyzer overrides',
    created_by               BIGINT           COMMENT 'Identifier of the user who created this configuration',
    created_on               TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the configuration was created',
    modified_by              BIGINT           COMMENT 'Identifier of the user who last modified this configuration',
    modified_on              TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the configuration was last modified'
);

-- search_config_object_binding
CREATE TABLE IF NOT EXISTS search_config_object_binding (
    bind_id          BIGINT           COMMENT 'Unique identifier for this search config binding',
    search_config_id BIGINT           COMMENT 'Identifier of the search configuration being bound',
    object_id        BIGINT           COMMENT 'Identifier of the Synapse object bound to this search config',
    object_type      VARCHAR          COMMENT 'Type of object bound (e.g., entity)',
    created_by       BIGINT           COMMENT 'Identifier of the user who created this binding',
    created_on       TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the binding was created'
);

-- sent_messages
CREATE TABLE IF NOT EXISTS sent_messages (
    change_num     BIGINT           COMMENT 'Change number of the sent message',
    time_stamp     TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the message was sent',
    object_id      BIGINT           COMMENT 'Identifier of the object whose change triggered this message',
    object_version BIGINT           COMMENT 'Version of the object at the time of the change',
    object_type    VARCHAR          COMMENT 'Type of object that triggered this message (e.g., ENTITY, TEAM)'
);

-- ses_notifications
CREATE TABLE IF NOT EXISTS ses_notifications (
    id                   BIGINT           COMMENT 'Unique identifier for the SES notification record',
    created_on           TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this notification was received',
    instance_number      BIGINT           COMMENT 'Stack instance number that received this notification',
    ses_message_id       VARCHAR          COMMENT 'AWS SES message identifier',
    ses_feedback_id      VARCHAR          COMMENT 'AWS SES feedback identifier',
    notification_type    VARCHAR          COMMENT 'Type of SES notification. One of: BOUNCE, COMPLAINT, DELIVERY, UNKNOWN',
    notification_subtype VARCHAR          COMMENT 'Subtype of the SES notification (e.g., Permanent, Transient for bounces)',
    notification_reason  VARCHAR          COMMENT 'Reason for the notification',
    notification_body    VARCHAR          COMMENT 'Full JSON body of the SES notification'
);

-- stack_status
CREATE TABLE IF NOT EXISTS stack_status (
    id              BIGINT  COMMENT 'Unique identifier for the stack status record',
    current_message VARCHAR COMMENT 'Message describing the current stack status',
    pending_message VARCHAR COMMENT 'Message describing a pending status change',
    status          VARCHAR COMMENT 'Current read/write status of the stack. One of: READ_WRITE, READ_ONLY, DOWN'
);

-- statistics_monthly_project_files
CREATE TABLE IF NOT EXISTS statistics_monthly_project_files (
    project_id      BIGINT  COMMENT 'Identifier of the project these statistics are for',
    month           VARCHAR COMMENT 'The month these statistics cover (YYYY-MM-DD format)',
    event_type      VARCHAR COMMENT 'Type of file event counted. One of: FILE_DOWNLOAD, FILE_UPLOAD',
    last_updated_on BIGINT  COMMENT 'Epoch milliseconds when these statistics were last computed',
    files_count     BIGINT  COMMENT 'Number of distinct files involved in events this month',
    users_count     BIGINT  COMMENT 'Number of distinct users who performed events this month'
);

-- statistics_monthly_status
CREATE TABLE IF NOT EXISTS statistics_monthly_status (
    object_type     VARCHAR COMMENT 'Type of object these statistics are for (e.g., PROJECT)',
    month           VARCHAR COMMENT 'The month these statistics cover (YYYY-MM-DD format)',
    status          VARCHAR COMMENT 'Processing status. One of: AVAILABLE, PROCESSING, PROCESSING_FAILED',
    last_started_on BIGINT  COMMENT 'Epoch milliseconds when processing of this month last started',
    last_updated_on BIGINT  COMMENT 'Epoch milliseconds when this status was last updated',
    error_message   VARCHAR COMMENT 'Error message if processing failed',
    error_details   BINARY  COMMENT 'Detailed error information if processing failed'
);

-- storage_location
CREATE TABLE IF NOT EXISTS storage_location (
    id          BIGINT           COMMENT 'Unique identifier for the storage location',
    description VARCHAR          COMMENT 'Human-readable description of this storage location',
    upload_type VARCHAR          COMMENT 'Type of upload storage. One of: S3, GOOGLECLOUDSTORAGE, SFTP, HTTPS, PROXYLOCAL, NONE',
    etag        VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    json        VARCHAR          COMMENT 'JSON object containing storage location configuration',
    data_hash   VARCHAR          COMMENT 'Hash of the storage location configuration for deduplication',
    created_by  BIGINT           COMMENT 'Identifier of the user who created this storage location',
    created_on  TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the storage location was created'
);

-- submission_contributor
CREATE TABLE IF NOT EXISTS submission_contributor (
    id            BIGINT           COMMENT 'Unique identifier for the submission contributor record',
    etag          VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    submission_id BIGINT           COMMENT 'Identifier of the evaluation submission',
    principal_id  BIGINT           COMMENT 'Identifier of the user who contributed to this submission',
    created_on    TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this contribution was recorded'
);

-- subscription
CREATE TABLE IF NOT EXISTS subscription (
    id            BIGINT  COMMENT 'Unique identifier for the subscription',
    subscriber_id BIGINT  COMMENT 'Identifier of the user who subscribed',
    object_id     BIGINT  COMMENT 'Identifier of the object being subscribed to',
    object_type   VARCHAR COMMENT 'Type of object subscribed to. One of: FORUM, THREAD, DATA_ACCESS_SUBMISSION, DATA_ACCESS_SUBMISSION_STATUS',
    created_on    BIGINT  COMMENT 'Epoch milliseconds when this subscription was created'
);

-- substatus_annotations_blob
CREATE TABLE IF NOT EXISTS substatus_annotations_blob (
    submission_id    BIGINT COMMENT 'Identifier of the evaluation submission these annotations belong to',
    version          BIGINT COMMENT 'Version of the annotations blob',
    annotations_blob BINARY COMMENT 'Serialized annotations data for this submission status'
);

-- substatus_annotations_owner
CREATE TABLE IF NOT EXISTS substatus_annotations_owner (
    submission_id BIGINT COMMENT 'Identifier of the evaluation submission',
    evaluation_id BIGINT COMMENT 'Identifier of the evaluation this submission belongs to'
);

-- substatus_doubleannotation
CREATE TABLE IF NOT EXISTS substatus_doubleannotation (
    id            BIGINT  COMMENT 'Unique identifier for this annotation record',
    attribute     VARCHAR COMMENT 'Name of the annotation attribute',
    submission_id BIGINT  COMMENT 'Identifier of the submission this annotation belongs to',
    value         FLOAT   COMMENT 'Double-precision floating point value of the annotation',
    is_private    BOOLEAN COMMENT 'Whether this annotation is private (not shown to submitters)'
);

-- substatus_longannotation
CREATE TABLE IF NOT EXISTS substatus_longannotation (
    id            BIGINT  COMMENT 'Unique identifier for this annotation record',
    attribute     VARCHAR COMMENT 'Name of the annotation attribute',
    submission_id BIGINT  COMMENT 'Identifier of the submission this annotation belongs to',
    value         BIGINT  COMMENT 'Long integer value of the annotation',
    is_private    BOOLEAN COMMENT 'Whether this annotation is private (not shown to submitters)'
);

-- substatus_stringannotation
CREATE TABLE IF NOT EXISTS substatus_stringannotation (
    id            BIGINT  COMMENT 'Unique identifier for this annotation record',
    attribute     VARCHAR COMMENT 'Name of the annotation attribute',
    submission_id BIGINT  COMMENT 'Identifier of the submission this annotation belongs to',
    value         VARCHAR COMMENT 'String value of the annotation',
    is_private    BOOLEAN COMMENT 'Whether this annotation is private (not shown to submitters)'
);

-- synapse_realm
CREATE TABLE IF NOT EXISTS synapse_realm (
    id         BIGINT           COMMENT 'Unique identifier for the Synapse realm',
    name       VARCHAR          COMMENT 'Unique name of the realm (ASCII)',
    created_on TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the realm was created'
);

-- synapse_realm_idp
CREATE TABLE IF NOT EXISTS synapse_realm_idp (
    realm_id BIGINT  COMMENT 'Identifier of the realm this identity provider belongs to',
    provider VARCHAR COMMENT 'Identity provider for this realm (e.g., SYNAPSE, GOOGLE_OAUTH_2_0, ORCID)'
);

-- synapse_realm_principal
CREATE TABLE IF NOT EXISTS synapse_realm_principal (
    id           BIGINT  COMMENT 'Unique identifier for this realm principal record',
    realm_id     BIGINT  COMMENT 'Identifier of the realm this principal belongs to',
    principal_id BIGINT  COMMENT 'Identifier of the Synapse principal (user or group)',
    type         VARCHAR COMMENT 'Type of principal in the realm. One of: ANONYMOUS, PUBLIC, AUTHENTICATED, ADMINISTRATORS'
);

-- synonym_set
CREATE TABLE IF NOT EXISTS synonym_set (
    id                BIGINT           COMMENT 'Unique identifier for the synonym set',
    etag              VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    organization_name VARCHAR          COMMENT 'Name of the organization that owns this synonym set',
    name              VARCHAR          COMMENT 'Name of this synonym set within the organization',
    description       VARCHAR          COMMENT 'Optional description of this synonym set',
    definition        VARCHAR          COMMENT 'JSON array defining synonym groups',
    created_by        BIGINT           COMMENT 'Identifier of the user who created this synonym set',
    created_on        TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the synonym set was created',
    modified_by       BIGINT           COMMENT 'Identifier of the user who last modified this synonym set',
    modified_on       TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the synonym set was last modified'
);

-- table_id_sequence
CREATE TABLE IF NOT EXISTS table_id_sequence (
    table_id    BIGINT  COMMENT 'Identifier of the Synapse table',
    etag        VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    row_version BIGINT  COMMENT 'Current row version for this table',
    sequence    BIGINT  COMMENT 'Current row ID sequence counter for this table'
);

-- table_row_change
CREATE TABLE IF NOT EXISTS table_row_change (
    id             BIGINT  COMMENT 'Unique identifier for the table row change',
    table_id       BIGINT  COMMENT 'Identifier of the Synapse table this change belongs to',
    row_version    BIGINT  COMMENT 'Row version number for this change',
    etag           VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    created_by     BIGINT  COMMENT 'Identifier of the user who made this change',
    created_on     BIGINT  COMMENT 'Epoch milliseconds when this change was created',
    s3_bucket      VARCHAR COMMENT 'S3 bucket where the change data is stored',
    s3_key         VARCHAR COMMENT 'S3 key where the change data is stored',
    row_count      BIGINT  COMMENT 'Number of rows affected by this change',
    change_type    VARCHAR COMMENT 'Type of change. One of: ROW, COLUMN, SEARCH',
    trx_id         BIGINT  COMMENT 'Identifier of the table transaction this change belongs to',
    has_file_refs  BOOLEAN COMMENT 'Whether any rows in this change reference file handles',
    search_enabled BOOLEAN COMMENT 'Whether search indexing is enabled for this change'
);

-- table_snapshot
CREATE TABLE IF NOT EXISTS table_snapshot (
    snapshot_id BIGINT           COMMENT 'Unique identifier for the table snapshot',
    table_id    BIGINT           COMMENT 'Identifier of the Synapse table this snapshot is for',
    version     BIGINT           COMMENT 'Version number of the snapshot',
    created_by  BIGINT           COMMENT 'Identifier of the user who created this snapshot',
    created_on  TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the snapshot was created',
    bucket_name VARCHAR          COMMENT 'S3 bucket where the snapshot data is stored',
    key         VARCHAR          COMMENT 'S3 key where the snapshot data is stored'
);

-- table_status
CREATE TABLE IF NOT EXISTS table_status (
    table_id               BIGINT  COMMENT 'Identifier of the Synapse table',
    version                BIGINT  COMMENT 'Version of the table this status is for',
    state                  VARCHAR COMMENT 'Processing state. One of: AVAILABLE, PROCESSING, PROCESSING_FAILED',
    reset_token            VARCHAR COMMENT 'Token used to reset or validate the current processing state',
    last_table_change_etag VARCHAR COMMENT 'Etag of the last table change that triggered this status',
    started_on             BIGINT  COMMENT 'Epoch milliseconds when processing started',
    changed_on             BIGINT  COMMENT 'Epoch milliseconds when this status was last updated',
    progress_message       VARCHAR COMMENT 'Human-readable progress message',
    progress_current       BIGINT  COMMENT 'Current progress count',
    progress_total         BIGINT  COMMENT 'Total progress count',
    error_message          VARCHAR COMMENT 'Error message if processing failed',
    error_details          BINARY  COMMENT 'Detailed error information if processing failed',
    runtime_ms             BIGINT  COMMENT 'Total processing time in milliseconds'
);

-- table_transaction
CREATE TABLE IF NOT EXISTS table_transaction (
    trx_id     BIGINT  COMMENT 'Unique identifier for the table transaction',
    table_id   BIGINT  COMMENT 'Identifier of the Synapse table this transaction is for',
    started_by BIGINT  COMMENT 'Identifier of the user who started this transaction',
    started_on BIGINT  COMMENT 'Epoch milliseconds when this transaction was started',
    etag       VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);

-- table_trx_to_version
CREATE TABLE IF NOT EXISTS table_trx_to_version (
    trx_id  BIGINT COMMENT 'Identifier of the table transaction',
    version BIGINT COMMENT 'Version number this transaction was applied to'
);

-- team
CREATE TABLE IF NOT EXISTS team (
    id         BIGINT  COMMENT 'Unique identifier for the team (shared with USER_GROUP)',
    etag       VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    icon       BIGINT  COMMENT 'Identifier of the file handle for the team icon',
    properties BINARY  COMMENT 'Serialized team properties and metadata',
    state      VARCHAR COMMENT 'Team membership type. One of: OPEN, CLOSED, PUBLIC'
);

-- terms_of_service_agreement
CREATE TABLE IF NOT EXISTS terms_of_service_agreement (
    id         BIGINT           COMMENT 'Unique identifier for this terms of service agreement record',
    created_by BIGINT           COMMENT 'Identifier of the user who agreed to the terms',
    created_on TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the user agreed to the terms',
    version    VARCHAR          COMMENT 'Version of the terms of service that was agreed to'
);

-- terms_of_service_latest_version
CREATE TABLE IF NOT EXISTS terms_of_service_latest_version (
    id         BIGINT           COMMENT 'Unique identifier for this record',
    updated_on TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the latest version was last updated',
    version    VARCHAR          COMMENT 'The current latest version of the terms of service'
);

-- terms_of_service_requirement
CREATE TABLE IF NOT EXISTS terms_of_service_requirement (
    id          BIGINT           COMMENT 'Unique identifier for this terms of service requirement record',
    created_by  BIGINT           COMMENT 'Identifier of the user who created this requirement',
    created_on  TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this requirement was created',
    min_version VARCHAR          COMMENT 'Minimum version of the terms of service users must agree to',
    enforced_on TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this requirement began being enforced'
);

-- text_analyzer
CREATE TABLE IF NOT EXISTS text_analyzer (
    id                BIGINT           COMMENT 'Unique identifier for the text analyzer',
    etag              VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    name              VARCHAR          COMMENT 'Name of this text analyzer',
    description       VARCHAR          COMMENT 'Optional description of this text analyzer',
    organization_name VARCHAR          COMMENT 'Name of the organization that owns this analyzer',
    settings          VARCHAR          COMMENT 'JSON configuration settings for the text analyzer',
    created_by        BIGINT           COMMENT 'Identifier of the user who created this analyzer',
    created_on        TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the analyzer was created',
    modified_by       BIGINT           COMMENT 'Identifier of the user who last modified this analyzer',
    modified_on       TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the analyzer was last modified'
);

-- throttle_rules
CREATE TABLE IF NOT EXISTS throttle_rules (
    throttle_id                   BIGINT           COMMENT 'Unique identifier for the throttle rule',
    normalized_path               VARCHAR          COMMENT 'Normalized URL path pattern this rule applies to',
    max_calls_per_user_per_period BIGINT           COMMENT 'Maximum number of calls allowed per user within the period',
    period_in_seconds             BIGINT           COMMENT 'Duration of the throttle period in seconds',
    modified_on                   TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this rule was last modified'
);

-- trash_can
CREATE TABLE IF NOT EXISTS trash_can (
    node_id        BIGINT           COMMENT 'Identifier of the deleted entity (node)',
    node_name      VARCHAR          COMMENT 'Name of the entity at the time of deletion',
    deleted_by     BIGINT           COMMENT 'Identifier of the user who deleted this entity',
    deleted_on     TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the entity was moved to trash',
    parent_id      BIGINT           COMMENT 'Identifier of the parent entity at the time of deletion',
    etag           VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    priority_purge BOOLEAN          COMMENT 'Whether this entity should be purged with high priority'
);

-- unsuccessful_login_lockout
CREATE TABLE IF NOT EXISTS unsuccessful_login_lockout (
    user_id                  BIGINT COMMENT 'Identifier of the user being tracked for failed logins',
    unsuccessful_login_count BIGINT COMMENT 'Number of consecutive failed login attempts',
    lockout_expiration       BIGINT COMMENT 'Epoch milliseconds when the lockout expires'
);

-- user_group
CREATE TABLE IF NOT EXISTS user_group (
    id            BIGINT           COMMENT 'Unique identifier for the user or group',
    creation_date TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this user or group was created',
    isindividual  BOOLEAN          COMMENT 'Whether this principal is an individual user (true) or a group/team (false)',
    etag          VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    realm         BIGINT           COMMENT 'Identifier of the Synapse realm this principal belongs to'
);

-- user_profile
CREATE TABLE IF NOT EXISTS user_profile (
    owner_id                BIGINT  COMMENT 'Identifier of the user this profile belongs to',
    etag                    VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    properties              BINARY  COMMENT 'Serialized user profile properties',
    picture_id              BIGINT  COMMENT 'Identifier of the file handle for the profile picture',
    send_email_notification BOOLEAN COMMENT 'Whether the user has opted into email notifications',
    first_name              BINARY  COMMENT 'User first name (stored as binary to support arbitrary encoding)',
    last_name               BINARY  COMMENT 'User last name (stored as binary to support arbitrary encoding)'
);

-- user_status
CREATE TABLE IF NOT EXISTS user_status (
    principal_id BIGINT           COMMENT 'Identifier of the user this status is for',
    etag         VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    last_seen_on TIMESTAMP_NTZ(9) COMMENT 'Timestamp when this user was last active',
    disabled     BOOLEAN          COMMENT 'Whether this user account is disabled'
);

-- user_two_fa_status
CREATE TABLE IF NOT EXISTS user_two_fa_status (
    principal_id BIGINT  COMMENT 'Identifier of the user this two-factor authentication status is for',
    enabled      BOOLEAN COMMENT 'Whether two-factor authentication is enabled for this user'
);

-- v2_wiki_attachment_reservation
CREATE TABLE IF NOT EXISTS v2_wiki_attachment_reservation (
    wiki_id        BIGINT           COMMENT 'Identifier of the wiki page this attachment is reserved for',
    file_handle_id BIGINT           COMMENT 'Identifier of the file handle reserved as an attachment',
    time_stamp     TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the attachment reservation was made'
);

-- v2_wiki_markdown
CREATE TABLE IF NOT EXISTS v2_wiki_markdown (
    wiki_id          BIGINT  COMMENT 'Identifier of the wiki page this markdown version belongs to',
    file_handle_id   BIGINT  COMMENT 'Identifier of the file handle containing the markdown content',
    markdown_version BIGINT  COMMENT 'Version number of this markdown revision',
    modified_on      BIGINT  COMMENT 'Epoch milliseconds when this markdown version was created',
    modified_by      BIGINT  COMMENT 'Identifier of the user who created this markdown version',
    title            VARCHAR COMMENT 'Title of the wiki page at this version',
    attachment_id_list BINARY COMMENT 'Serialized list of attachment file handle IDs for this version'
);

-- v2_wiki_owners
CREATE TABLE IF NOT EXISTS v2_wiki_owners (
    owner_id          BIGINT  COMMENT 'Identifier of the Synapse object that owns this wiki',
    owner_object_type VARCHAR COMMENT 'Type of object that owns this wiki. One of: ENTITY, EVALUATION, ACCESS_REQUIREMENT',
    root_wiki_id      BIGINT  COMMENT 'Identifier of the root wiki page for this owner',
    order_hint        BINARY  COMMENT 'Serialized ordering hint for wiki sub-pages',
    etag              VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);

-- v2_wiki_page
CREATE TABLE IF NOT EXISTS v2_wiki_page (
    id               BIGINT  COMMENT 'Unique identifier for the wiki page',
    etag             VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    title            VARCHAR COMMENT 'Title of the wiki page',
    created_by       BIGINT  COMMENT 'Identifier of the user who created this wiki page',
    created_on       BIGINT  COMMENT 'Epoch milliseconds when this wiki page was created',
    modified_by      BIGINT  COMMENT 'Identifier of the user who last modified this wiki page',
    modified_on      BIGINT  COMMENT 'Epoch milliseconds when this wiki page was last modified',
    parent_id        BIGINT  COMMENT 'Identifier of the parent wiki page. NULL for root pages.',
    root_id          BIGINT  COMMENT 'Identifier of the root wiki page in this hierarchy',
    markdown_version BIGINT  COMMENT 'Current markdown version number for this wiki page'
);

-- validation_json_schema_index
CREATE TABLE IF NOT EXISTS validation_json_schema_index (
    version_id        BIGINT  COMMENT 'Identifier of the JSON schema version',
    validation_schema VARCHAR COMMENT 'JSON schema used for validation, derived from the version'
);

-- verification_file
CREATE TABLE IF NOT EXISTS verification_file (
    verification_id BIGINT COMMENT 'Identifier of the verification submission',
    file_handle_id  BIGINT COMMENT 'Identifier of a file handle submitted as part of the verification'
);

-- verification_state
CREATE TABLE IF NOT EXISTS verification_state (
    id              BIGINT  COMMENT 'Unique identifier for the verification state record',
    verification_id BIGINT  COMMENT 'Identifier of the verification submission',
    created_by      BIGINT  COMMENT 'Identifier of the reviewer who set this state',
    created_on      BIGINT  COMMENT 'Epoch milliseconds when this state was set',
    state           VARCHAR COMMENT 'State of the verification. One of: SUBMITTED, APPROVED, REJECTED, SUSPENDED',
    reason          BINARY  COMMENT 'Reason for rejection or suspension',
    notes           BINARY  COMMENT 'Internal reviewer notes'
);

-- verification_submission
CREATE TABLE IF NOT EXISTS verification_submission (
    id         BIGINT  COMMENT 'Unique identifier for the verification submission',
    etag       VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    created_by BIGINT  COMMENT 'Identifier of the user who submitted the verification',
    created_on BIGINT  COMMENT 'Epoch milliseconds when the verification was submitted',
    serialized BINARY  COMMENT 'Serialized representation of the complete verification submission object'
);

-- view_scope
CREATE TABLE IF NOT EXISTS view_scope (
    view_id      BIGINT COMMENT 'Identifier of the Synapse entity view',
    container_id BIGINT COMMENT 'Identifier of a container (project or folder) in the view scope'
);

-- view_type
CREATE TABLE IF NOT EXISTS view_type (
    view_id          BIGINT  COMMENT 'Identifier of the Synapse entity view',
    view_object_type VARCHAR COMMENT 'Type of objects in this view. One of: ENTITY, SUBMISSION, DATASET, DATASET_COLLECTION',
    view_type_mask   BIGINT  COMMENT 'Bitmask defining which entity types are included in this view',
    etag             VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);

-- webhook
CREATE TABLE IF NOT EXISTS webhook (
    id              BIGINT           COMMENT 'Unique identifier for the webhook',
    etag            VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    created_by      BIGINT           COMMENT 'Identifier of the user who created this webhook',
    created_on      TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the webhook was created',
    modified_on     TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the webhook was last modified',
    object_id       BIGINT           COMMENT 'Identifier of the Synapse object this webhook is monitoring',
    object_type     VARCHAR          COMMENT 'Type of object this webhook monitors (e.g., ENTITY)',
    event_types     VARCHAR          COMMENT 'JSON array of event types this webhook fires on',
    invoke_endpoint VARCHAR          COMMENT 'URL endpoint that will be called when this webhook fires',
    is_enabled      BOOLEAN          COMMENT 'Whether this webhook is active'
);

-- webhook_allowed_domain
CREATE TABLE IF NOT EXISTS webhook_allowed_domain (
    id      BIGINT  COMMENT 'Unique identifier for the allowed domain record',
    etag    VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    pattern VARCHAR COMMENT 'Domain pattern that is allowed for webhook endpoints'
);

-- webhook_verification
CREATE TABLE IF NOT EXISTS webhook_verification (
    webhook_id      BIGINT           COMMENT 'Identifier of the webhook this verification record belongs to',
    etag            VARCHAR          COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    modified_on     TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the verification status was last modified',
    code            VARCHAR          COMMENT 'Verification code sent to the webhook endpoint',
    code_expires_on TIMESTAMP_NTZ(9) COMMENT 'Timestamp when the verification code expires',
    code_message_id VARCHAR          COMMENT 'Message identifier of the verification code delivery',
    status          VARCHAR          COMMENT 'Current verification status. One of: PENDING, CODE_SENT, VERIFIED, FAILED, REVOKED',
    message         VARCHAR          COMMENT 'Message describing the current verification status'
);
