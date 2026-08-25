USE SCHEMA {{database_name}}.RDS_LANDING; --noqa: JJ01,PRS,TMP

-- ACTIVITY
TRUNCATE TABLE activity;
-- Add ingest metadata columns
ALTER TABLE activity ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE activity ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE activity ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE activity CLUSTER BY (snapshot_date);

-- AGENT_REGISTRATION
TRUNCATE TABLE agent_registration;
-- Add ingest metadata columns
ALTER TABLE agent_registration ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE agent_registration ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE agent_registration ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE agent_registration CLUSTER BY (snapshot_date);

-- AGENT_SESSION
TRUNCATE TABLE agent_session;
-- Add ingest metadata columns
ALTER TABLE agent_session ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE agent_session ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE agent_session ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE agent_session CLUSTER BY (snapshot_date);

-- AGENT_TRACE
TRUNCATE TABLE agent_trace;
-- Add ingest metadata columns
ALTER TABLE agent_trace ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE agent_trace ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE agent_trace ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE agent_trace CLUSTER BY (snapshot_date);

-- ASYNCH_JOB_STATUS
TRUNCATE TABLE asynch_job_status;
-- Add ingest metadata columns
ALTER TABLE asynch_job_status ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE asynch_job_status ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE asynch_job_status ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE asynch_job_status CLUSTER BY (snapshot_date);

-- AUTHENTICATED_ON
TRUNCATE TABLE authenticated_on;
-- Add ingest metadata columns
ALTER TABLE authenticated_on ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE authenticated_on ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE authenticated_on ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE authenticated_on CLUSTER BY (snapshot_date);

-- AUTHORIZATION_CONSENT
TRUNCATE TABLE authorization_consent;
-- Add ingest metadata columns
ALTER TABLE authorization_consent ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE authorization_consent ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE authorization_consent ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE authorization_consent CLUSTER BY (snapshot_date);

-- BOUND_COLUMN_ORDINAL
TRUNCATE TABLE bound_column_ordinal;
-- Add ingest metadata columns
ALTER TABLE bound_column_ordinal ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE bound_column_ordinal ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE bound_column_ordinal ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE bound_column_ordinal CLUSTER BY (snapshot_date);

-- BOUND_COLUMN_OWNER
TRUNCATE TABLE bound_column_owner;
-- Add ingest metadata columns
ALTER TABLE bound_column_owner ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE bound_column_owner ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE bound_column_owner ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE bound_column_owner CLUSTER BY (snapshot_date);

-- CERTIFIED_USERS
TRUNCATE TABLE certified_users;
-- Add ingest metadata columns
ALTER TABLE certified_users ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE certified_users ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE certified_users ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE certified_users CLUSTER BY (snapshot_date);

-- CHALLENGE
TRUNCATE TABLE challenge;
-- Add ingest metadata columns
ALTER TABLE challenge ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE challenge ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE challenge ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE challenge CLUSTER BY (snapshot_date);

-- CHALLENGE_TEAM
TRUNCATE TABLE challenge_team;
-- Add ingest metadata columns
ALTER TABLE challenge_team ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE challenge_team ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE challenge_team ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE challenge_team CLUSTER BY (snapshot_date);

-- CHANGES
TRUNCATE TABLE changes;
-- Add ingest metadata columns
ALTER TABLE changes ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE changes ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE changes ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE changes CLUSTER BY (snapshot_date);

-- COLUMN_ANALYZER_OVERRIDE
TRUNCATE TABLE column_analyzer_override;
-- Add ingest metadata columns
ALTER TABLE column_analyzer_override ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE column_analyzer_override ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE column_analyzer_override ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE column_analyzer_override CLUSTER BY (snapshot_date);

-- COLUMN_MODEL
TRUNCATE TABLE column_model;
-- Add ingest metadata columns
ALTER TABLE column_model ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE column_model ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE column_model ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE column_model CLUSTER BY (snapshot_date);

-- COMMENT
TRUNCATE TABLE comment;
-- Add ingest metadata columns
ALTER TABLE comment ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE comment ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE comment ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE comment CLUSTER BY (snapshot_date);

-- CREDENTIAL
TRUNCATE TABLE credential;
-- Add ingest metadata columns
ALTER TABLE credential ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE credential ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE credential ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE credential CLUSTER BY (snapshot_date);

-- CURATION_TASK
TRUNCATE TABLE curation_task;
-- Add ingest metadata columns
ALTER TABLE curation_task ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE curation_task ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE curation_task ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE curation_task CLUSTER BY (snapshot_date);

-- DATA_TYPE
TRUNCATE TABLE data_type;
-- Add ingest metadata columns
ALTER TABLE data_type ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE data_type ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE data_type ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE data_type CLUSTER BY (snapshot_date);

-- DERIVED_ANNOTATIONS
TRUNCATE TABLE derived_annotations;
-- Add ingest metadata columns
ALTER TABLE derived_annotations ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE derived_annotations ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE derived_annotations ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE derived_annotations CLUSTER BY (snapshot_date);

-- DISCUSSION_REPLY
TRUNCATE TABLE discussion_reply;
-- Add ingest metadata columns
ALTER TABLE discussion_reply ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE discussion_reply ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE discussion_reply ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE discussion_reply CLUSTER BY (snapshot_date);

-- DISCUSSION_SEARCH_INDEX
TRUNCATE TABLE discussion_search_index;
-- Add ingest metadata columns
ALTER TABLE discussion_search_index ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE discussion_search_index ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE discussion_search_index ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE discussion_search_index CLUSTER BY (snapshot_date);

-- DISCUSSION_THREAD
TRUNCATE TABLE discussion_thread;
-- Add ingest metadata columns
ALTER TABLE discussion_thread ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE discussion_thread ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE discussion_thread ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE discussion_thread CLUSTER BY (snapshot_date);

-- DISCUSSION_THREAD_ENTITY_REFERENCE
TRUNCATE TABLE discussion_thread_entity_reference;
-- Add ingest metadata columns
ALTER TABLE discussion_thread_entity_reference ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE discussion_thread_entity_reference ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE discussion_thread_entity_reference ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE discussion_thread_entity_reference CLUSTER BY (snapshot_date);

-- DISCUSSION_THREAD_STATS
TRUNCATE TABLE discussion_thread_stats;
-- Add ingest metadata columns
ALTER TABLE discussion_thread_stats ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE discussion_thread_stats ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE discussion_thread_stats ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE discussion_thread_stats CLUSTER BY (snapshot_date);

-- DISCUSSION_THREAD_SUBMISSION_REFERENCE
TRUNCATE TABLE discussion_thread_submission_reference;
-- Add ingest metadata columns
ALTER TABLE discussion_thread_submission_reference ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE discussion_thread_submission_reference ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE discussion_thread_submission_reference ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE discussion_thread_submission_reference CLUSTER BY (snapshot_date);

-- DISCUSSION_THREAD_VIEW
TRUNCATE TABLE discussion_thread_view;
-- Add ingest metadata columns
ALTER TABLE discussion_thread_view ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE discussion_thread_view ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE discussion_thread_view ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE discussion_thread_view CLUSTER BY (snapshot_date);

-- DOCKER_COMMIT
TRUNCATE TABLE docker_commit;
-- Add ingest metadata columns
ALTER TABLE docker_commit ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE docker_commit ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE docker_commit ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE docker_commit CLUSTER BY (snapshot_date);

-- DOCKER_REPOSITORY_NAME
TRUNCATE TABLE docker_repository_name;
-- Add ingest metadata columns
ALTER TABLE docker_repository_name ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE docker_repository_name ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE docker_repository_name ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE docker_repository_name CLUSTER BY (snapshot_date);

-- DOI
TRUNCATE TABLE doi;
-- Add ingest metadata columns
ALTER TABLE doi ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE doi ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE doi ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE doi CLUSTER BY (snapshot_date);

-- DOWNLOAD_LIST
TRUNCATE TABLE download_list;
-- Add ingest metadata columns
ALTER TABLE download_list ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE download_list ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE download_list ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE download_list CLUSTER BY (snapshot_date);

-- DOWNLOAD_LIST_ITEM
TRUNCATE TABLE download_list_item;
-- Add ingest metadata columns
ALTER TABLE download_list_item ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE download_list_item ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE download_list_item ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE download_list_item CLUSTER BY (snapshot_date);

-- DOWNLOAD_LIST_ITEM_V2
TRUNCATE TABLE download_list_item_v2;
-- Add ingest metadata columns
ALTER TABLE download_list_item_v2 ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE download_list_item_v2 ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE download_list_item_v2 ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE download_list_item_v2 CLUSTER BY (snapshot_date);

-- DOWNLOAD_LIST_V2
TRUNCATE TABLE download_list_v2;
-- Add ingest metadata columns
ALTER TABLE download_list_v2 ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE download_list_v2 ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE download_list_v2 ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE download_list_v2 CLUSTER BY (snapshot_date);

-- DOWNLOAD_ORDER
TRUNCATE TABLE download_order;
-- Add ingest metadata columns
ALTER TABLE download_order ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE download_order ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE download_order ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE download_order CLUSTER BY (snapshot_date);

-- EVALUATION
TRUNCATE TABLE evaluation;
-- Add ingest metadata columns
ALTER TABLE evaluation ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE evaluation ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE evaluation ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE evaluation CLUSTER BY (snapshot_date);

-- EVALUATION_ROUNDS
TRUNCATE TABLE evaluation_rounds;
-- Add ingest metadata columns
ALTER TABLE evaluation_rounds ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE evaluation_rounds ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE evaluation_rounds ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE evaluation_rounds CLUSTER BY (snapshot_date);

-- EVALUATION_SUBMISSION
TRUNCATE TABLE evaluation_submission;
-- Add ingest metadata columns
ALTER TABLE evaluation_submission ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE evaluation_submission ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE evaluation_submission ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE evaluation_submission CLUSTER BY (snapshot_date);

-- EVALUATION_SUBMISSIONS
TRUNCATE TABLE evaluation_submissions;
-- Add ingest metadata columns
ALTER TABLE evaluation_submissions ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE evaluation_submissions ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE evaluation_submissions ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE evaluation_submissions CLUSTER BY (snapshot_date);

-- EVALUATION_SUBMISSION_FILE
TRUNCATE TABLE evaluation_submission_file;
-- Add ingest metadata columns
ALTER TABLE evaluation_submission_file ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE evaluation_submission_file ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE evaluation_submission_file ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE evaluation_submission_file CLUSTER BY (snapshot_date);

-- EVALUATION_SUBMISSION_STATUS
TRUNCATE TABLE evaluation_submission_status;
-- Add ingest metadata columns
ALTER TABLE evaluation_submission_status ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE evaluation_submission_status ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE evaluation_submission_status ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE evaluation_submission_status CLUSTER BY (snapshot_date);

-- FAVORITE
TRUNCATE TABLE favorite;
-- Add ingest metadata columns
ALTER TABLE favorite ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE favorite ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE favorite ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE favorite CLUSTER BY (snapshot_date);

-- FEATURE_STATUS
TRUNCATE TABLE feature_status;
-- Add ingest metadata columns
ALTER TABLE feature_status ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE feature_status ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE feature_status ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE feature_status CLUSTER BY (snapshot_date);

-- FILES
TRUNCATE TABLE files;
-- Add ingest metadata columns
ALTER TABLE files ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE files ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE files ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE files CLUSTER BY (snapshot_date);

-- FILES_SCANNER_STATUS
TRUNCATE TABLE files_scanner_status;
-- Add ingest metadata columns
ALTER TABLE files_scanner_status ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE files_scanner_status ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE files_scanner_status ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE files_scanner_status CLUSTER BY (snapshot_date);

-- FORM_DATA
TRUNCATE TABLE form_data;
-- Add ingest metadata columns
ALTER TABLE form_data ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE form_data ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE form_data ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE form_data CLUSTER BY (snapshot_date);

-- FORM_GROUP
TRUNCATE TABLE form_group;
-- Add ingest metadata columns
ALTER TABLE form_group ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE form_group ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE form_group ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE form_group CLUSTER BY (snapshot_date);

-- FORUM
TRUNCATE TABLE forum;
-- Add ingest metadata columns
ALTER TABLE forum ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE forum ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE forum ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE forum CLUSTER BY (snapshot_date);

-- GRID_CONNECTION
TRUNCATE TABLE grid_connection;
-- Add ingest metadata columns
ALTER TABLE grid_connection ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE grid_connection ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE grid_connection ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE grid_connection CLUSTER BY (snapshot_date);

-- GRID_PATCH
TRUNCATE TABLE grid_patch;
-- Add ingest metadata columns
ALTER TABLE grid_patch ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE grid_patch ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE grid_patch ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE grid_patch CLUSTER BY (snapshot_date);

-- GRID_REPLICA
TRUNCATE TABLE grid_replica;
-- Add ingest metadata columns
ALTER TABLE grid_replica ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE grid_replica ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE grid_replica ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE grid_replica CLUSTER BY (snapshot_date);

-- GRID_SESSION
TRUNCATE TABLE grid_session;
-- Add ingest metadata columns
ALTER TABLE grid_session ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE grid_session ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE grid_session ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE grid_session CLUSTER BY (snapshot_date);

-- GRID_SNAPSHOT
TRUNCATE TABLE grid_snapshot;
-- Add ingest metadata columns
ALTER TABLE grid_snapshot ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE grid_snapshot ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE grid_snapshot ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE grid_snapshot CLUSTER BY (snapshot_date);

-- GROUP_MEMBERS
TRUNCATE TABLE group_members;
-- Add ingest metadata columns
ALTER TABLE group_members ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE group_members ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE group_members ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE group_members CLUSTER BY (snapshot_date);

-- JSON_SCHEMA
TRUNCATE TABLE json_schema;
-- Add ingest metadata columns
ALTER TABLE json_schema ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE json_schema ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE json_schema ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE json_schema CLUSTER BY (snapshot_date);

-- JSON_SCHEMA_BLOB
TRUNCATE TABLE json_schema_blob;
-- Add ingest metadata columns
ALTER TABLE json_schema_blob ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE json_schema_blob ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE json_schema_blob ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE json_schema_blob CLUSTER BY (snapshot_date);

-- JSON_SCHEMA_DEPENDENCY
TRUNCATE TABLE json_schema_dependency;
-- Add ingest metadata columns
ALTER TABLE json_schema_dependency ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE json_schema_dependency ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE json_schema_dependency ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE json_schema_dependency CLUSTER BY (snapshot_date);

-- JSON_SCHEMA_LATEST_VERSION
TRUNCATE TABLE json_schema_latest_version;
-- Add ingest metadata columns
ALTER TABLE json_schema_latest_version ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE json_schema_latest_version ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE json_schema_latest_version ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE json_schema_latest_version CLUSTER BY (snapshot_date);

-- JSON_SCHEMA_OBJECT_BINDING
TRUNCATE TABLE json_schema_object_binding;
-- Add ingest metadata columns
ALTER TABLE json_schema_object_binding ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE json_schema_object_binding ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE json_schema_object_binding ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE json_schema_object_binding CLUSTER BY (snapshot_date);

-- JSON_SCHEMA_VALIDATION_RESULTS
TRUNCATE TABLE json_schema_validation_results;
-- Add ingest metadata columns
ALTER TABLE json_schema_validation_results ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE json_schema_validation_results ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE json_schema_validation_results ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE json_schema_validation_results CLUSTER BY (snapshot_date);

-- JSON_SCHEMA_VERSION
TRUNCATE TABLE json_schema_version;
-- Add ingest metadata columns
ALTER TABLE json_schema_version ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE json_schema_version ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE json_schema_version ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE json_schema_version CLUSTER BY (snapshot_date);

-- MATERIALIZED_VIEW_ID
TRUNCATE TABLE materialized_view_id;
-- Add ingest metadata columns
ALTER TABLE materialized_view_id ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE materialized_view_id ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE materialized_view_id ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE materialized_view_id CLUSTER BY (snapshot_date);

-- MATERIALIZED_VIEW_SOURCE_TABLES
TRUNCATE TABLE materialized_view_source_tables;
-- Add ingest metadata columns
ALTER TABLE materialized_view_source_tables ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE materialized_view_source_tables ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE materialized_view_source_tables ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE materialized_view_source_tables CLUSTER BY (snapshot_date);

-- MEMBERSHIP_INVITATION_SUBMISSION
TRUNCATE TABLE membership_invitation_submission;
-- Add ingest metadata columns
ALTER TABLE membership_invitation_submission ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE membership_invitation_submission ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE membership_invitation_submission ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE membership_invitation_submission CLUSTER BY (snapshot_date);

-- MEMBERSHIP_REQUEST_SUBMISSION
TRUNCATE TABLE membership_request_submission;
-- Add ingest metadata columns
ALTER TABLE membership_request_submission ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE membership_request_submission ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE membership_request_submission ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE membership_request_submission CLUSTER BY (snapshot_date);

-- MESSAGE_BROADCAST
TRUNCATE TABLE message_broadcast;
-- Add ingest metadata columns
ALTER TABLE message_broadcast ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE message_broadcast ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE message_broadcast ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE message_broadcast CLUSTER BY (snapshot_date);

-- MESSAGE_CONTENT
TRUNCATE TABLE message_content;
-- Add ingest metadata columns
ALTER TABLE message_content ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE message_content ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE message_content ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE message_content CLUSTER BY (snapshot_date);

-- MESSAGE_RECIPIENT
TRUNCATE TABLE message_recipient;
-- Add ingest metadata columns
ALTER TABLE message_recipient ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE message_recipient ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE message_recipient ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE message_recipient CLUSTER BY (snapshot_date);

-- MESSAGE_STATUS
TRUNCATE TABLE message_status;
-- Add ingest metadata columns
ALTER TABLE message_status ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE message_status ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE message_status ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE message_status CLUSTER BY (snapshot_date);

-- MESSAGE_TO_USER
TRUNCATE TABLE message_to_user;
-- Add ingest metadata columns
ALTER TABLE message_to_user ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE message_to_user ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE message_to_user ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE message_to_user CLUSTER BY (snapshot_date);

-- MULTIPART_UPLOAD
TRUNCATE TABLE multipart_upload;
-- Add ingest metadata columns
ALTER TABLE multipart_upload ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE multipart_upload ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE multipart_upload ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE multipart_upload CLUSTER BY (snapshot_date);

-- MULTIPART_UPLOAD_COMPOSER_PART_STATE
TRUNCATE TABLE multipart_upload_composer_part_state;
-- Add ingest metadata columns
ALTER TABLE multipart_upload_composer_part_state ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE multipart_upload_composer_part_state ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE multipart_upload_composer_part_state ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE multipart_upload_composer_part_state CLUSTER BY (snapshot_date);

-- MULTIPART_UPLOAD_PART_STATE
TRUNCATE TABLE multipart_upload_part_state;
-- Add ingest metadata columns
ALTER TABLE multipart_upload_part_state ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE multipart_upload_part_state ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE multipart_upload_part_state ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE multipart_upload_part_state CLUSTER BY (snapshot_date);

-- NODE
TRUNCATE TABLE node;
-- Add ingest metadata columns
ALTER TABLE node ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE node ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE node ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE node CLUSTER BY (snapshot_date);

-- NODE_ACCESS_REQUIREMENT
TRUNCATE TABLE node_access_requirement;
-- Add ingest metadata columns
ALTER TABLE node_access_requirement ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE node_access_requirement ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE node_access_requirement ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE node_access_requirement CLUSTER BY (snapshot_date);

-- NODE_REVISION
TRUNCATE TABLE node_revision;
-- Add ingest metadata columns
ALTER TABLE node_revision ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE node_revision ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE node_revision ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE node_revision CLUSTER BY (snapshot_date);

-- NOTIFICATION_EMAIL
TRUNCATE TABLE notification_email;
-- Add ingest metadata columns
ALTER TABLE notification_email ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE notification_email ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE notification_email ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE notification_email CLUSTER BY (snapshot_date);

-- OAUTH_ACCESS_TOKEN
TRUNCATE TABLE oauth_access_token;
-- Add ingest metadata columns
ALTER TABLE oauth_access_token ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE oauth_access_token ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE oauth_access_token ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE oauth_access_token CLUSTER BY (snapshot_date);

-- OAUTH_AUTHORIZATION_CODE
TRUNCATE TABLE oauth_authorization_code;
-- Add ingest metadata columns
ALTER TABLE oauth_authorization_code ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE oauth_authorization_code ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE oauth_authorization_code ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE oauth_authorization_code CLUSTER BY (snapshot_date);

-- OAUTH_CLIENT
TRUNCATE TABLE oauth_client;
-- Add ingest metadata columns
ALTER TABLE oauth_client ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE oauth_client ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE oauth_client ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE oauth_client CLUSTER BY (snapshot_date);

-- OAUTH_REFRESH_TOKEN
TRUNCATE TABLE oauth_refresh_token;
-- Add ingest metadata columns
ALTER TABLE oauth_refresh_token ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE oauth_refresh_token ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE oauth_refresh_token ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE oauth_refresh_token CLUSTER BY (snapshot_date);

-- OAUTH_SECTOR_IDENTIFIER
TRUNCATE TABLE oauth_sector_identifier;
-- Add ingest metadata columns
ALTER TABLE oauth_sector_identifier ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE oauth_sector_identifier ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE oauth_sector_identifier ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE oauth_sector_identifier CLUSTER BY (snapshot_date);

-- ORGANIZATION
TRUNCATE TABLE organization;
-- Add ingest metadata columns
ALTER TABLE organization ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE organization ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE organization ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE organization CLUSTER BY (snapshot_date);

-- OTP_RECOVERY_CODE
TRUNCATE TABLE otp_recovery_code;
-- Add ingest metadata columns
ALTER TABLE otp_recovery_code ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE otp_recovery_code ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE otp_recovery_code ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE otp_recovery_code CLUSTER BY (snapshot_date);

-- OTP_SECRET
TRUNCATE TABLE otp_secret;
-- Add ingest metadata columns
ALTER TABLE otp_secret ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE otp_secret ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE otp_secret ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE otp_secret CLUSTER BY (snapshot_date);

-- PERSONAL_ACCESS_TOKEN
TRUNCATE TABLE personal_access_token;
-- Add ingest metadata columns
ALTER TABLE personal_access_token ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE personal_access_token ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE personal_access_token ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE personal_access_token CLUSTER BY (snapshot_date);

-- PORTAL
TRUNCATE TABLE portal;
-- Add ingest metadata columns
ALTER TABLE portal ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE portal ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE portal ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE portal CLUSTER BY (snapshot_date);

-- PRINCIPAL_OIDC_BINDING
TRUNCATE TABLE principal_oidc_binding;
-- Add ingest metadata columns
ALTER TABLE principal_oidc_binding ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE principal_oidc_binding ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE principal_oidc_binding ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE principal_oidc_binding CLUSTER BY (snapshot_date);

-- PRINCIPAL_PREFIX
TRUNCATE TABLE principal_prefix;
-- Add ingest metadata columns
ALTER TABLE principal_prefix ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE principal_prefix ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE principal_prefix ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE principal_prefix CLUSTER BY (snapshot_date);

-- PROCESSED_MESSAGES
TRUNCATE TABLE processed_messages;
-- Add ingest metadata columns
ALTER TABLE processed_messages ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE processed_messages ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE processed_messages ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE processed_messages CLUSTER BY (snapshot_date);

-- PROJECT_SETTING
TRUNCATE TABLE project_setting;
-- Add ingest metadata columns
ALTER TABLE project_setting ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE project_setting ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE project_setting ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE project_setting CLUSTER BY (snapshot_date);

-- PROJECT_STAT
TRUNCATE TABLE project_stat;
-- Add ingest metadata columns
ALTER TABLE project_stat ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE project_stat ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE project_stat ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE project_stat CLUSTER BY (snapshot_date);

-- PROJECT_STORAGE_DATA
TRUNCATE TABLE project_storage_data;
-- Add ingest metadata columns
ALTER TABLE project_storage_data ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE project_storage_data ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE project_storage_data ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE project_storage_data CLUSTER BY (snapshot_date);

-- PROJECT_STORAGE_LIMIT
TRUNCATE TABLE project_storage_limit;
-- Add ingest metadata columns
ALTER TABLE project_storage_limit ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE project_storage_limit ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE project_storage_limit ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE project_storage_limit CLUSTER BY (snapshot_date);

-- QUARANTINED_EMAILS
TRUNCATE TABLE quarantined_emails;
-- Add ingest metadata columns
ALTER TABLE quarantined_emails ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE quarantined_emails ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE quarantined_emails ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE quarantined_emails CLUSTER BY (snapshot_date);

-- QUIZ_RESPONSE
TRUNCATE TABLE quiz_response;
-- Add ingest metadata columns
ALTER TABLE quiz_response ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE quiz_response ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE quiz_response ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE quiz_response CLUSTER BY (snapshot_date);

-- RECORDSET_VALIDATION_STATS
TRUNCATE TABLE recordset_validation_stats;
-- Add ingest metadata columns
ALTER TABLE recordset_validation_stats ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE recordset_validation_stats ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE recordset_validation_stats ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE recordset_validation_stats CLUSTER BY (snapshot_date);

-- RESEARCH_PROJECT
TRUNCATE TABLE research_project;
-- Add ingest metadata columns
ALTER TABLE research_project ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE research_project ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE research_project ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE research_project CLUSTER BY (snapshot_date);

-- SEARCH_CONFIGURATION
TRUNCATE TABLE search_configuration;
-- Add ingest metadata columns
ALTER TABLE search_configuration ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE search_configuration ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE search_configuration ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE search_configuration CLUSTER BY (snapshot_date);

-- SEARCH_CONFIG_OBJECT_BINDING
TRUNCATE TABLE search_config_object_binding;
-- Add ingest metadata columns
ALTER TABLE search_config_object_binding ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE search_config_object_binding ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE search_config_object_binding ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE search_config_object_binding CLUSTER BY (snapshot_date);

-- SENT_MESSAGES
TRUNCATE TABLE sent_messages;
-- Add ingest metadata columns
ALTER TABLE sent_messages ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE sent_messages ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE sent_messages ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE sent_messages CLUSTER BY (snapshot_date);

-- SES_NOTIFICATIONS
TRUNCATE TABLE ses_notifications;
-- Add ingest metadata columns
ALTER TABLE ses_notifications ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE ses_notifications ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE ses_notifications ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE ses_notifications CLUSTER BY (snapshot_date);

-- STACK_STATUS
TRUNCATE TABLE stack_status;
-- Add ingest metadata columns
ALTER TABLE stack_status ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE stack_status ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE stack_status ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE stack_status CLUSTER BY (snapshot_date);

-- STATISTICS_MONTHLY_PROJECT_FILES
TRUNCATE TABLE statistics_monthly_project_files;
-- Add ingest metadata columns
ALTER TABLE statistics_monthly_project_files ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE statistics_monthly_project_files ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE statistics_monthly_project_files ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE statistics_monthly_project_files CLUSTER BY (snapshot_date);

-- STATISTICS_MONTHLY_STATUS
TRUNCATE TABLE statistics_monthly_status;
-- Add ingest metadata columns
ALTER TABLE statistics_monthly_status ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE statistics_monthly_status ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE statistics_monthly_status ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE statistics_monthly_status CLUSTER BY (snapshot_date);

-- STORAGE_LOCATION
TRUNCATE TABLE storage_location;
-- Add ingest metadata columns
ALTER TABLE storage_location ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE storage_location ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE storage_location ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE storage_location CLUSTER BY (snapshot_date);

-- SUBMISSION_CONTRIBUTOR
TRUNCATE TABLE submission_contributor;
-- Add ingest metadata columns
ALTER TABLE submission_contributor ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE submission_contributor ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE submission_contributor ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE submission_contributor CLUSTER BY (snapshot_date);

-- SUBSCRIPTION
TRUNCATE TABLE subscription;
-- Add ingest metadata columns
ALTER TABLE subscription ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE subscription ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE subscription ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE subscription CLUSTER BY (snapshot_date);

-- SUBSTATUS_ANNOTATIONS_BLOB
TRUNCATE TABLE substatus_annotations_blob;
-- Add ingest metadata columns
ALTER TABLE substatus_annotations_blob ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE substatus_annotations_blob ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE substatus_annotations_blob ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE substatus_annotations_blob CLUSTER BY (snapshot_date);

-- SUBSTATUS_ANNOTATIONS_OWNER
TRUNCATE TABLE substatus_annotations_owner;
-- Add ingest metadata columns
ALTER TABLE substatus_annotations_owner ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE substatus_annotations_owner ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE substatus_annotations_owner ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE substatus_annotations_owner CLUSTER BY (snapshot_date);

-- SUBSTATUS_DOUBLEANNOTATION
TRUNCATE TABLE substatus_doubleannotation;
-- Add ingest metadata columns
ALTER TABLE substatus_doubleannotation ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE substatus_doubleannotation ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE substatus_doubleannotation ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE substatus_doubleannotation CLUSTER BY (snapshot_date);

-- SUBSTATUS_LONGANNOTATION
TRUNCATE TABLE substatus_longannotation;
-- Add ingest metadata columns
ALTER TABLE substatus_longannotation ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE substatus_longannotation ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE substatus_longannotation ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE substatus_longannotation CLUSTER BY (snapshot_date);

-- SUBSTATUS_STRINGANNOTATION
TRUNCATE TABLE substatus_stringannotation;
-- Add ingest metadata columns
ALTER TABLE substatus_stringannotation ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE substatus_stringannotation ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE substatus_stringannotation ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE substatus_stringannotation CLUSTER BY (snapshot_date);

-- SYNAPSE_REALM
TRUNCATE TABLE synapse_realm;
-- Add ingest metadata columns
ALTER TABLE synapse_realm ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE synapse_realm ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE synapse_realm ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE synapse_realm CLUSTER BY (snapshot_date);

-- SYNAPSE_REALM_IDP
TRUNCATE TABLE synapse_realm_idp;
-- Add ingest metadata columns
ALTER TABLE synapse_realm_idp ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE synapse_realm_idp ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE synapse_realm_idp ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE synapse_realm_idp CLUSTER BY (snapshot_date);

-- SYNAPSE_REALM_PRINCIPAL
TRUNCATE TABLE synapse_realm_principal;
-- Add ingest metadata columns
ALTER TABLE synapse_realm_principal ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE synapse_realm_principal ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE synapse_realm_principal ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE synapse_realm_principal CLUSTER BY (snapshot_date);

-- SYNONYM_SET
TRUNCATE TABLE synonym_set;
-- Add ingest metadata columns
ALTER TABLE synonym_set ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE synonym_set ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE synonym_set ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE synonym_set CLUSTER BY (snapshot_date);

-- TABLE_ID_SEQUENCE
TRUNCATE TABLE table_id_sequence;
-- Add ingest metadata columns
ALTER TABLE table_id_sequence ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE table_id_sequence ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE table_id_sequence ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE table_id_sequence CLUSTER BY (snapshot_date);

-- TABLE_ROW_CHANGE
TRUNCATE TABLE table_row_change;
-- Add ingest metadata columns
ALTER TABLE table_row_change ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE table_row_change ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE table_row_change ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE table_row_change CLUSTER BY (snapshot_date);

-- TABLE_SNAPSHOT
TRUNCATE TABLE table_snapshot;
-- Add ingest metadata columns
ALTER TABLE table_snapshot ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE table_snapshot ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE table_snapshot ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE table_snapshot CLUSTER BY (snapshot_date);

-- TABLE_STATUS
TRUNCATE TABLE table_status;
-- Add ingest metadata columns
ALTER TABLE table_status ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE table_status ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE table_status ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE table_status CLUSTER BY (snapshot_date);

-- TABLE_TRANSACTION
TRUNCATE TABLE table_transaction;
-- Add ingest metadata columns
ALTER TABLE table_transaction ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE table_transaction ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE table_transaction ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE table_transaction CLUSTER BY (snapshot_date);

-- TABLE_TRX_TO_VERSION
TRUNCATE TABLE table_trx_to_version;
-- Add ingest metadata columns
ALTER TABLE table_trx_to_version ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE table_trx_to_version ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE table_trx_to_version ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE table_trx_to_version CLUSTER BY (snapshot_date);

-- TEAM
TRUNCATE TABLE team;
-- Add ingest metadata columns
ALTER TABLE team ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE team ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE team ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE team CLUSTER BY (snapshot_date);

-- TERMS_OF_SERVICE_AGREEMENT
TRUNCATE TABLE terms_of_service_agreement;
-- Add ingest metadata columns
ALTER TABLE terms_of_service_agreement ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE terms_of_service_agreement ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE terms_of_service_agreement ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE terms_of_service_agreement CLUSTER BY (snapshot_date);

-- TERMS_OF_SERVICE_LATEST_VERSION
TRUNCATE TABLE terms_of_service_latest_version;
-- Add ingest metadata columns
ALTER TABLE terms_of_service_latest_version ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE terms_of_service_latest_version ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE terms_of_service_latest_version ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE terms_of_service_latest_version CLUSTER BY (snapshot_date);

-- TERMS_OF_SERVICE_REQUIREMENT
TRUNCATE TABLE terms_of_service_requirement;
-- Add ingest metadata columns
ALTER TABLE terms_of_service_requirement ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE terms_of_service_requirement ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE terms_of_service_requirement ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE terms_of_service_requirement CLUSTER BY (snapshot_date);

-- TEXT_ANALYZER
TRUNCATE TABLE text_analyzer;
-- Add ingest metadata columns
ALTER TABLE text_analyzer ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE text_analyzer ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE text_analyzer ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE text_analyzer CLUSTER BY (snapshot_date);

-- THROTTLE_RULES
TRUNCATE TABLE throttle_rules;
-- Add ingest metadata columns
ALTER TABLE throttle_rules ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE throttle_rules ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE throttle_rules ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE throttle_rules CLUSTER BY (snapshot_date);

-- TRASH_CAN
TRUNCATE TABLE trash_can;
-- Add ingest metadata columns
ALTER TABLE trash_can ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE trash_can ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE trash_can ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE trash_can CLUSTER BY (snapshot_date);

-- UNSUCCESSFUL_LOGIN_LOCKOUT
TRUNCATE TABLE unsuccessful_login_lockout;
-- Add ingest metadata columns
ALTER TABLE unsuccessful_login_lockout ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE unsuccessful_login_lockout ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE unsuccessful_login_lockout ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE unsuccessful_login_lockout CLUSTER BY (snapshot_date);

-- USER_GROUP
TRUNCATE TABLE user_group;
-- Add ingest metadata columns
ALTER TABLE user_group ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE user_group ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE user_group ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE user_group CLUSTER BY (snapshot_date);

-- USER_PROFILE
TRUNCATE TABLE user_profile;
-- Add ingest metadata columns
ALTER TABLE user_profile ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE user_profile ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE user_profile ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE user_profile CLUSTER BY (snapshot_date);

-- USER_STATUS
TRUNCATE TABLE user_status;
-- Add ingest metadata columns
ALTER TABLE user_status ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE user_status ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE user_status ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE user_status CLUSTER BY (snapshot_date);

-- USER_TWO_FA_STATUS
TRUNCATE TABLE user_two_fa_status;
-- Add ingest metadata columns
ALTER TABLE user_two_fa_status ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE user_two_fa_status ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE user_two_fa_status ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE user_two_fa_status CLUSTER BY (snapshot_date);

-- V2_WIKI_ATTACHMENT_RESERVATION
TRUNCATE TABLE v2_wiki_attachment_reservation;
-- Add ingest metadata columns
ALTER TABLE v2_wiki_attachment_reservation ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE v2_wiki_attachment_reservation ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE v2_wiki_attachment_reservation ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE v2_wiki_attachment_reservation CLUSTER BY (snapshot_date);

-- V2_WIKI_MARKDOWN
TRUNCATE TABLE v2_wiki_markdown;
-- Add ingest metadata columns
ALTER TABLE v2_wiki_markdown ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE v2_wiki_markdown ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE v2_wiki_markdown ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE v2_wiki_markdown CLUSTER BY (snapshot_date);

-- V2_WIKI_OWNERS
TRUNCATE TABLE v2_wiki_owners;
-- Add ingest metadata columns
ALTER TABLE v2_wiki_owners ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE v2_wiki_owners ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE v2_wiki_owners ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE v2_wiki_owners CLUSTER BY (snapshot_date);

-- V2_WIKI_PAGE
TRUNCATE TABLE v2_wiki_page;
-- Add ingest metadata columns
ALTER TABLE v2_wiki_page ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE v2_wiki_page ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE v2_wiki_page ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE v2_wiki_page CLUSTER BY (snapshot_date);

-- VALIDATION_JSON_SCHEMA_INDEX
TRUNCATE TABLE validation_json_schema_index;
-- Add ingest metadata columns
ALTER TABLE validation_json_schema_index ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE validation_json_schema_index ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE validation_json_schema_index ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE validation_json_schema_index CLUSTER BY (snapshot_date);

-- VERIFICATION_FILE
TRUNCATE TABLE verification_file;
-- Add ingest metadata columns
ALTER TABLE verification_file ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE verification_file ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE verification_file ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE verification_file CLUSTER BY (snapshot_date);

-- VERIFICATION_STATE
TRUNCATE TABLE verification_state;
-- Add ingest metadata columns
ALTER TABLE verification_state ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE verification_state ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE verification_state ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE verification_state CLUSTER BY (snapshot_date);

-- VERIFICATION_SUBMISSION
TRUNCATE TABLE verification_submission;
-- Add ingest metadata columns
ALTER TABLE verification_submission ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE verification_submission ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE verification_submission ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE verification_submission CLUSTER BY (snapshot_date);

-- VIEW_SCOPE
TRUNCATE TABLE view_scope;
-- Add ingest metadata columns
ALTER TABLE view_scope ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE view_scope ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE view_scope ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE view_scope CLUSTER BY (snapshot_date);

-- VIEW_TYPE
TRUNCATE TABLE view_type;
-- Add ingest metadata columns
ALTER TABLE view_type ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE view_type ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE view_type ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE view_type CLUSTER BY (snapshot_date);

-- WEBHOOK
TRUNCATE TABLE webhook;
-- Add ingest metadata columns
ALTER TABLE webhook ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE webhook ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE webhook ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE webhook CLUSTER BY (snapshot_date);

-- WEBHOOK_ALLOWED_DOMAIN
TRUNCATE TABLE webhook_allowed_domain;
-- Add ingest metadata columns
ALTER TABLE webhook_allowed_domain ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE webhook_allowed_domain ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE webhook_allowed_domain ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE webhook_allowed_domain CLUSTER BY (snapshot_date);

-- WEBHOOK_VERIFICATION
TRUNCATE TABLE webhook_verification;
-- Add ingest metadata columns
ALTER TABLE webhook_verification ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE webhook_verification ADD COLUMN snapshot_date DATE COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE webhook_verification ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE webhook_verification CLUSTER BY (snapshot_date);
