USE SCHEMA {{database_name}}.RDS_RAW; --noqa: JJ01,PRS,TMP

-- Promotes the remaining RDS_LANDING tables (now on a daily COPY INTO cadence,
-- per V2.76.1-V2.76.4) to RDS_RAW dynamic tables, following the same pattern as
-- the high-priority tables in V2.74.0: straight SELECT * copies with no
-- transformations. Transformation logic lives in the dbt staging layer.
--
-- A subset of columns carrying credentials/secrets are masked via the RDS_RAW
-- PII masking policies (admin/policies/V1.36.0), matching the masking applied
-- to the same columns in SYNAPSE_RDS_SNAPSHOT for SNOW-482.
--
-- Tables whose upstream source is periodically truncated (job/token/log-style
-- tables such as asynch_job_status, materialized_view_id, and
-- materialized_view_source_tables) are excluded here: a same-day snapshot
-- filter would silently drop history. Those get dedup-based dynamic tables in
-- V2.77.1 instead.

-- activity
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.activity --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.activity with no transformations applied. Serves as the dbt source table for the stg_synapse__activity staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.activity --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- agent_registration
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.agent_registration --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.agent_registration with no transformations applied. Serves as the dbt source table for the stg_synapse__agent_registration staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.agent_registration --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- agent_session
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.agent_session --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.agent_session with no transformations applied. Serves as the dbt source table for the stg_synapse__agent_session staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.agent_session --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- authenticated_on
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.authenticated_on --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.authenticated_on with no transformations applied. Serves as the dbt source table for the stg_synapse__authenticated_on staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.authenticated_on --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- authorization_consent
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.authorization_consent --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.authorization_consent with no transformations applied. Serves as the dbt source table for the stg_synapse__authorization_consent staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.authorization_consent --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- bound_column_ordinal
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.bound_column_ordinal --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.bound_column_ordinal with no transformations applied. Serves as the dbt source table for the stg_synapse__bound_column_ordinal staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.bound_column_ordinal --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- bound_column_owner
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.bound_column_owner --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.bound_column_owner with no transformations applied. Serves as the dbt source table for the stg_synapse__bound_column_owner staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.bound_column_owner --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- certified_users
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.certified_users --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.certified_users with no transformations applied. Serves as the dbt source table for the stg_synapse__certified_users staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.certified_users --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- challenge
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.challenge --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.challenge with no transformations applied. Serves as the dbt source table for the stg_synapse__challenge staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.challenge --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- challenge_team
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.challenge_team --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.challenge_team with no transformations applied. Serves as the dbt source table for the stg_synapse__challenge_team staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.challenge_team --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- changes
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.changes --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.changes with no transformations applied. Serves as the dbt source table for the stg_synapse__changes staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.changes --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- column_analyzer_override
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.column_analyzer_override --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.column_analyzer_override with no transformations applied. Serves as the dbt source table for the stg_synapse__column_analyzer_override staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.column_analyzer_override --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- column_model
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.column_model --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.column_model with no transformations applied. Serves as the dbt source table for the stg_synapse__column_model staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.column_model --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- comment
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.comment --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.comment with no transformations applied. Serves as the dbt source table for the stg_synapse__comment staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.comment --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- credential
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.credential --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.credential with no transformations applied. Serves as the dbt source table for the stg_synapse__credential staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.credential --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();
ALTER TABLE {{database_name}}.RDS_RAW.credential --noqa: JJ01,PRS,TMP
    MODIFY COLUMN pass_hash SET MASKING POLICY {{database_name}}.RDS_RAW.PII_MASK_TEXT;


-- curation_task
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.curation_task --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.curation_task with no transformations applied. Serves as the dbt source table for the stg_synapse__curation_task staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.curation_task --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- data_type
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.data_type --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.data_type with no transformations applied. Serves as the dbt source table for the stg_synapse__data_type staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.data_type --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- derived_annotations
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.derived_annotations --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.derived_annotations with no transformations applied. Serves as the dbt source table for the stg_synapse__derived_annotations staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.derived_annotations --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- discussion_reply
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.discussion_reply --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.discussion_reply with no transformations applied. Serves as the dbt source table for the stg_synapse__discussion_reply staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.discussion_reply --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- discussion_search_index
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.discussion_search_index --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.discussion_search_index with no transformations applied. Serves as the dbt source table for the stg_synapse__discussion_search_index staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.discussion_search_index --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- discussion_thread
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.discussion_thread --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.discussion_thread with no transformations applied. Serves as the dbt source table for the stg_synapse__discussion_thread staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.discussion_thread --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- discussion_thread_entity_reference
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.discussion_thread_entity_reference --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.discussion_thread_entity_reference with no transformations applied. Serves as the dbt source table for the stg_synapse__discussion_thread_entity_reference staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.discussion_thread_entity_reference --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- discussion_thread_stats
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.discussion_thread_stats --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.discussion_thread_stats with no transformations applied. Serves as the dbt source table for the stg_synapse__discussion_thread_stats staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.discussion_thread_stats --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- discussion_thread_submission_reference
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.discussion_thread_submission_reference --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.discussion_thread_submission_reference with no transformations applied. Serves as the dbt source table for the stg_synapse__discussion_thread_submission_reference staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.discussion_thread_submission_reference --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- discussion_thread_view
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.discussion_thread_view --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.discussion_thread_view with no transformations applied. Serves as the dbt source table for the stg_synapse__discussion_thread_view staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.discussion_thread_view --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- docker_commit
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.docker_commit --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.docker_commit with no transformations applied. Serves as the dbt source table for the stg_synapse__docker_commit staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.docker_commit --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- docker_repository_name
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.docker_repository_name --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.docker_repository_name with no transformations applied. Serves as the dbt source table for the stg_synapse__docker_repository_name staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.docker_repository_name --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- doi
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.doi --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.doi with no transformations applied. Serves as the dbt source table for the stg_synapse__doi staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.doi --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- download_list
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.download_list --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.download_list with no transformations applied. Serves as the dbt source table for the stg_synapse__download_list staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.download_list --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- download_list_item
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.download_list_item --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.download_list_item with no transformations applied. Serves as the dbt source table for the stg_synapse__download_list_item staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.download_list_item --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- download_list_item_v2
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.download_list_item_v2 --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.download_list_item_v2 with no transformations applied. Serves as the dbt source table for the stg_synapse__download_list_item_v2 staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.download_list_item_v2 --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- download_list_v2
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.download_list_v2 --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.download_list_v2 with no transformations applied. Serves as the dbt source table for the stg_synapse__download_list_v2 staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.download_list_v2 --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- download_order
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.download_order --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.download_order with no transformations applied. Serves as the dbt source table for the stg_synapse__download_order staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.download_order --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- evaluation
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.evaluation --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.evaluation with no transformations applied. Serves as the dbt source table for the stg_synapse__evaluation staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.evaluation --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- evaluation_rounds
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.evaluation_rounds --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.evaluation_rounds with no transformations applied. Serves as the dbt source table for the stg_synapse__evaluation_rounds staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.evaluation_rounds --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- evaluation_submission
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.evaluation_submission --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.evaluation_submission with no transformations applied. Serves as the dbt source table for the stg_synapse__evaluation_submission staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.evaluation_submission --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- evaluation_submissions
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.evaluation_submissions --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.evaluation_submissions with no transformations applied. Serves as the dbt source table for the stg_synapse__evaluation_submissions staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.evaluation_submissions --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- evaluation_submission_file
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.evaluation_submission_file --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.evaluation_submission_file with no transformations applied. Serves as the dbt source table for the stg_synapse__evaluation_submission_file staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.evaluation_submission_file --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- evaluation_submission_status
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.evaluation_submission_status --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.evaluation_submission_status with no transformations applied. Serves as the dbt source table for the stg_synapse__evaluation_submission_status staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.evaluation_submission_status --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- favorite
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.favorite --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.favorite with no transformations applied. Serves as the dbt source table for the stg_synapse__favorite staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.favorite --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- feature_status
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.feature_status --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.feature_status with no transformations applied. Serves as the dbt source table for the stg_synapse__feature_status staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.feature_status --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- files
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.files --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.files with no transformations applied. Serves as the dbt source table for the stg_synapse__files staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.files --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- form_data
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.form_data --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.form_data with no transformations applied. Serves as the dbt source table for the stg_synapse__form_data staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.form_data --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- form_group
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.form_group --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.form_group with no transformations applied. Serves as the dbt source table for the stg_synapse__form_group staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.form_group --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- forum
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.forum --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.forum with no transformations applied. Serves as the dbt source table for the stg_synapse__forum staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.forum --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- grid_connection
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.grid_connection --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.grid_connection with no transformations applied. Serves as the dbt source table for the stg_synapse__grid_connection staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.grid_connection --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- grid_patch
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.grid_patch --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.grid_patch with no transformations applied. Serves as the dbt source table for the stg_synapse__grid_patch staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.grid_patch --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- grid_replica
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.grid_replica --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.grid_replica with no transformations applied. Serves as the dbt source table for the stg_synapse__grid_replica staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.grid_replica --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- grid_session
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.grid_session --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.grid_session with no transformations applied. Serves as the dbt source table for the stg_synapse__grid_session staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.grid_session --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- grid_snapshot
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.grid_snapshot --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.grid_snapshot with no transformations applied. Serves as the dbt source table for the stg_synapse__grid_snapshot staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.grid_snapshot --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- group_members
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.group_members --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.group_members with no transformations applied. Serves as the dbt source table for the stg_synapse__group_members staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.group_members --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- json_schema
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.json_schema --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.json_schema with no transformations applied. Serves as the dbt source table for the stg_synapse__json_schema staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.json_schema --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- json_schema_blob
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.json_schema_blob --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.json_schema_blob with no transformations applied. Serves as the dbt source table for the stg_synapse__json_schema_blob staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.json_schema_blob --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- json_schema_dependency
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.json_schema_dependency --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.json_schema_dependency with no transformations applied. Serves as the dbt source table for the stg_synapse__json_schema_dependency staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.json_schema_dependency --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- json_schema_latest_version
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.json_schema_latest_version --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.json_schema_latest_version with no transformations applied. Serves as the dbt source table for the stg_synapse__json_schema_latest_version staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.json_schema_latest_version --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- json_schema_object_binding
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.json_schema_object_binding --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.json_schema_object_binding with no transformations applied. Serves as the dbt source table for the stg_synapse__json_schema_object_binding staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.json_schema_object_binding --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- json_schema_version
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.json_schema_version --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.json_schema_version with no transformations applied. Serves as the dbt source table for the stg_synapse__json_schema_version staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.json_schema_version --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- membership_invitation_submission
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.membership_invitation_submission --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.membership_invitation_submission with no transformations applied. Serves as the dbt source table for the stg_synapse__membership_invitation_submission staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.membership_invitation_submission --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- membership_request_submission
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.membership_request_submission --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.membership_request_submission with no transformations applied. Serves as the dbt source table for the stg_synapse__membership_request_submission staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.membership_request_submission --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- message_broadcast
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.message_broadcast --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.message_broadcast with no transformations applied. Serves as the dbt source table for the stg_synapse__message_broadcast staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.message_broadcast --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- message_content
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.message_content --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.message_content with no transformations applied. Serves as the dbt source table for the stg_synapse__message_content staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.message_content --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- message_recipient
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.message_recipient --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.message_recipient with no transformations applied. Serves as the dbt source table for the stg_synapse__message_recipient staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.message_recipient --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- message_status
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.message_status --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.message_status with no transformations applied. Serves as the dbt source table for the stg_synapse__message_status staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.message_status --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- message_to_user
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.message_to_user --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.message_to_user with no transformations applied. Serves as the dbt source table for the stg_synapse__message_to_user staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.message_to_user --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- node
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.node --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.node with no transformations applied. Serves as the dbt source table for the stg_synapse__node staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.node --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- node_access_requirement
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.node_access_requirement --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.node_access_requirement with no transformations applied. Serves as the dbt source table for the stg_synapse__node_access_requirement staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.node_access_requirement --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- node_revision
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.node_revision --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.node_revision with no transformations applied. Serves as the dbt source table for the stg_synapse__node_revision staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.node_revision --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- notification_email
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.notification_email --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.notification_email with no transformations applied. Serves as the dbt source table for the stg_synapse__notification_email staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.notification_email --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- oauth_client
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.oauth_client --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.oauth_client with no transformations applied. Serves as the dbt source table for the stg_synapse__oauth_client staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.oauth_client --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();
ALTER TABLE {{database_name}}.RDS_RAW.oauth_client --noqa: JJ01,PRS,TMP
    MODIFY COLUMN secret_hash SET MASKING POLICY {{database_name}}.RDS_RAW.PII_MASK_TEXT;


-- oauth_refresh_token
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.oauth_refresh_token --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.oauth_refresh_token with no transformations applied. Serves as the dbt source table for the stg_synapse__oauth_refresh_token staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.oauth_refresh_token --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();
ALTER TABLE {{database_name}}.RDS_RAW.oauth_refresh_token --noqa: JJ01,PRS,TMP
    MODIFY COLUMN token_hash SET MASKING POLICY {{database_name}}.RDS_RAW.PII_MASK_TEXT;


-- oauth_sector_identifier
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.oauth_sector_identifier --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.oauth_sector_identifier with no transformations applied. Serves as the dbt source table for the stg_synapse__oauth_sector_identifier staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.oauth_sector_identifier --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();
ALTER TABLE {{database_name}}.RDS_RAW.oauth_sector_identifier --noqa: JJ01,PRS,TMP
    MODIFY COLUMN secret SET MASKING POLICY {{database_name}}.RDS_RAW.PII_MASK_TEXT;


-- organization
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.organization --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.organization with no transformations applied. Serves as the dbt source table for the stg_synapse__organization staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.organization --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- otp_recovery_code
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.otp_recovery_code --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.otp_recovery_code with no transformations applied. Serves as the dbt source table for the stg_synapse__otp_recovery_code staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.otp_recovery_code --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();
ALTER TABLE {{database_name}}.RDS_RAW.otp_recovery_code --noqa: JJ01,PRS,TMP
    MODIFY COLUMN code_hash SET MASKING POLICY {{database_name}}.RDS_RAW.PII_MASK_TEXT;


-- otp_secret
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.otp_secret --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.otp_secret with no transformations applied. Serves as the dbt source table for the stg_synapse__otp_secret staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.otp_secret --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();
ALTER TABLE {{database_name}}.RDS_RAW.otp_secret --noqa: JJ01,PRS,TMP
    MODIFY COLUMN secret SET MASKING POLICY {{database_name}}.RDS_RAW.PII_MASK_TEXT;


-- personal_access_token
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.personal_access_token --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.personal_access_token with no transformations applied. Serves as the dbt source table for the stg_synapse__personal_access_token staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.personal_access_token --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();
ALTER TABLE {{database_name}}.RDS_RAW.personal_access_token --noqa: JJ01,PRS,TMP
    MODIFY COLUMN scopes SET MASKING POLICY {{database_name}}.RDS_RAW.PII_MASK_BINARY;
ALTER TABLE {{database_name}}.RDS_RAW.personal_access_token --noqa: JJ01,PRS,TMP
    MODIFY COLUMN claims SET MASKING POLICY {{database_name}}.RDS_RAW.PII_MASK_BINARY;


-- portal
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.portal --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.portal with no transformations applied. Serves as the dbt source table for the stg_synapse__portal staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.portal --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- principal_oidc_binding
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.principal_oidc_binding --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.principal_oidc_binding with no transformations applied. Serves as the dbt source table for the stg_synapse__principal_oidc_binding staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.principal_oidc_binding --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- principal_prefix
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.principal_prefix --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.principal_prefix with no transformations applied. Serves as the dbt source table for the stg_synapse__principal_prefix staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.principal_prefix --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- project_setting
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.project_setting --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.project_setting with no transformations applied. Serves as the dbt source table for the stg_synapse__project_setting staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.project_setting --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- project_stat
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.project_stat --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.project_stat with no transformations applied. Serves as the dbt source table for the stg_synapse__project_stat staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.project_stat --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- project_storage_data
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.project_storage_data --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.project_storage_data with no transformations applied. Serves as the dbt source table for the stg_synapse__project_storage_data staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.project_storage_data --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- project_storage_limit
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.project_storage_limit --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.project_storage_limit with no transformations applied. Serves as the dbt source table for the stg_synapse__project_storage_limit staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.project_storage_limit --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- quarantined_emails
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.quarantined_emails --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.quarantined_emails with no transformations applied. Serves as the dbt source table for the stg_synapse__quarantined_emails staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.quarantined_emails --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- quiz_response
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.quiz_response --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.quiz_response with no transformations applied. Serves as the dbt source table for the stg_synapse__quiz_response staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.quiz_response --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- recordset_validation_stats
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.recordset_validation_stats --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.recordset_validation_stats with no transformations applied. Serves as the dbt source table for the stg_synapse__recordset_validation_stats staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.recordset_validation_stats --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- research_project
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.research_project --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.research_project with no transformations applied. Serves as the dbt source table for the stg_synapse__research_project staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.research_project --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- search_config_object_binding
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.search_config_object_binding --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.search_config_object_binding with no transformations applied. Serves as the dbt source table for the stg_synapse__search_config_object_binding staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.search_config_object_binding --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- search_configuration
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.search_configuration --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.search_configuration with no transformations applied. Serves as the dbt source table for the stg_synapse__search_configuration staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.search_configuration --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- sent_messages
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.sent_messages --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.sent_messages with no transformations applied. Serves as the dbt source table for the stg_synapse__sent_messages staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.sent_messages --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- ses_notifications
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.ses_notifications --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.ses_notifications with no transformations applied. Serves as the dbt source table for the stg_synapse__ses_notifications staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.ses_notifications --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- stack_status
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.stack_status --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.stack_status with no transformations applied. Serves as the dbt source table for the stg_synapse__stack_status staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.stack_status --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- statistics_monthly_project_files
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.statistics_monthly_project_files --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.statistics_monthly_project_files with no transformations applied. Serves as the dbt source table for the stg_synapse__statistics_monthly_project_files staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.statistics_monthly_project_files --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- statistics_monthly_status
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.statistics_monthly_status --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.statistics_monthly_status with no transformations applied. Serves as the dbt source table for the stg_synapse__statistics_monthly_status staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.statistics_monthly_status --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- storage_location
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.storage_location --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.storage_location with no transformations applied. Serves as the dbt source table for the stg_synapse__storage_location staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.storage_location --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- submission_contributor
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.submission_contributor --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.submission_contributor with no transformations applied. Serves as the dbt source table for the stg_synapse__submission_contributor staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.submission_contributor --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- subscription
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.subscription --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.subscription with no transformations applied. Serves as the dbt source table for the stg_synapse__subscription staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.subscription --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- substatus_annotations_blob
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.substatus_annotations_blob --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.substatus_annotations_blob with no transformations applied. Serves as the dbt source table for the stg_synapse__substatus_annotations_blob staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.substatus_annotations_blob --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- substatus_annotations_owner
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.substatus_annotations_owner --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.substatus_annotations_owner with no transformations applied. Serves as the dbt source table for the stg_synapse__substatus_annotations_owner staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.substatus_annotations_owner --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- substatus_doubleannotation
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.substatus_doubleannotation --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.substatus_doubleannotation with no transformations applied. Serves as the dbt source table for the stg_synapse__substatus_doubleannotation staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.substatus_doubleannotation --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- substatus_longannotation
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.substatus_longannotation --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.substatus_longannotation with no transformations applied. Serves as the dbt source table for the stg_synapse__substatus_longannotation staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.substatus_longannotation --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- substatus_stringannotation
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.substatus_stringannotation --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.substatus_stringannotation with no transformations applied. Serves as the dbt source table for the stg_synapse__substatus_stringannotation staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.substatus_stringannotation --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- synapse_realm
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.synapse_realm --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.synapse_realm with no transformations applied. Serves as the dbt source table for the stg_synapse__synapse_realm staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.synapse_realm --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- synapse_realm_idp
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.synapse_realm_idp --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.synapse_realm_idp with no transformations applied. Serves as the dbt source table for the stg_synapse__synapse_realm_idp staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.synapse_realm_idp --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- synapse_realm_principal
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.synapse_realm_principal --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.synapse_realm_principal with no transformations applied. Serves as the dbt source table for the stg_synapse__synapse_realm_principal staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.synapse_realm_principal --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- synonym_set
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.synonym_set --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.synonym_set with no transformations applied. Serves as the dbt source table for the stg_synapse__synonym_set staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.synonym_set --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- table_id_sequence
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.table_id_sequence --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.table_id_sequence with no transformations applied. Serves as the dbt source table for the stg_synapse__table_id_sequence staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.table_id_sequence --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- table_row_change
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.table_row_change --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.table_row_change with no transformations applied. Serves as the dbt source table for the stg_synapse__table_row_change staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.table_row_change --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- table_snapshot
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.table_snapshot --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.table_snapshot with no transformations applied. Serves as the dbt source table for the stg_synapse__table_snapshot staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.table_snapshot --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- table_status
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.table_status --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.table_status with no transformations applied. Serves as the dbt source table for the stg_synapse__table_status staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.table_status --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- table_transaction
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.table_transaction --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.table_transaction with no transformations applied. Serves as the dbt source table for the stg_synapse__table_transaction staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.table_transaction --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- table_trx_to_version
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.table_trx_to_version --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.table_trx_to_version with no transformations applied. Serves as the dbt source table for the stg_synapse__table_trx_to_version staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.table_trx_to_version --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- team
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.team --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.team with no transformations applied. Serves as the dbt source table for the stg_synapse__team staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.team --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- terms_of_service_agreement
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.terms_of_service_agreement --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.terms_of_service_agreement with no transformations applied. Serves as the dbt source table for the stg_synapse__terms_of_service_agreement staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.terms_of_service_agreement --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- terms_of_service_latest_version
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.terms_of_service_latest_version --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.terms_of_service_latest_version with no transformations applied. Serves as the dbt source table for the stg_synapse__terms_of_service_latest_version staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.terms_of_service_latest_version --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- terms_of_service_requirement
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.terms_of_service_requirement --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.terms_of_service_requirement with no transformations applied. Serves as the dbt source table for the stg_synapse__terms_of_service_requirement staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.terms_of_service_requirement --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- text_analyzer
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.text_analyzer --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.text_analyzer with no transformations applied. Serves as the dbt source table for the stg_synapse__text_analyzer staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.text_analyzer --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- throttle_rules
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.throttle_rules --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.throttle_rules with no transformations applied. Serves as the dbt source table for the stg_synapse__throttle_rules staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.throttle_rules --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- unsuccessful_login_lockout
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.unsuccessful_login_lockout --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.unsuccessful_login_lockout with no transformations applied. Serves as the dbt source table for the stg_synapse__unsuccessful_login_lockout staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.unsuccessful_login_lockout --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- user_group
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.user_group --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.user_group with no transformations applied. Serves as the dbt source table for the stg_synapse__user_group staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.user_group --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- user_profile
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.user_profile --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.user_profile with no transformations applied. Serves as the dbt source table for the stg_synapse__user_profile staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.user_profile --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- user_status
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.user_status --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.user_status with no transformations applied. Serves as the dbt source table for the stg_synapse__user_status staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.user_status --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- user_two_fa_status
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.user_two_fa_status --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.user_two_fa_status with no transformations applied. Serves as the dbt source table for the stg_synapse__user_two_fa_status staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.user_two_fa_status --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- v2_wiki_attachment_reservation
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.v2_wiki_attachment_reservation --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.v2_wiki_attachment_reservation with no transformations applied. Serves as the dbt source table for the stg_synapse__v2_wiki_attachment_reservation staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.v2_wiki_attachment_reservation --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- v2_wiki_markdown
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.v2_wiki_markdown --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.v2_wiki_markdown with no transformations applied. Serves as the dbt source table for the stg_synapse__v2_wiki_markdown staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.v2_wiki_markdown --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- v2_wiki_owners
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.v2_wiki_owners --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.v2_wiki_owners with no transformations applied. Serves as the dbt source table for the stg_synapse__v2_wiki_owners staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.v2_wiki_owners --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- v2_wiki_page
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.v2_wiki_page --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.v2_wiki_page with no transformations applied. Serves as the dbt source table for the stg_synapse__v2_wiki_page staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.v2_wiki_page --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- validation_json_schema_index
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.validation_json_schema_index --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.validation_json_schema_index with no transformations applied. Serves as the dbt source table for the stg_synapse__validation_json_schema_index staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.validation_json_schema_index --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- verification_state
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.verification_state --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.verification_state with no transformations applied. Serves as the dbt source table for the stg_synapse__verification_state staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.verification_state --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- verification_submission
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.verification_submission --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.verification_submission with no transformations applied. Serves as the dbt source table for the stg_synapse__verification_submission staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.verification_submission --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- view_scope
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.view_scope --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.view_scope with no transformations applied. Serves as the dbt source table for the stg_synapse__view_scope staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.view_scope --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- view_type
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.view_type --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.view_type with no transformations applied. Serves as the dbt source table for the stg_synapse__view_type staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.view_type --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- webhook
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.webhook --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.webhook with no transformations applied. Serves as the dbt source table for the stg_synapse__webhook staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.webhook --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- webhook_allowed_domain
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.webhook_allowed_domain --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.webhook_allowed_domain with no transformations applied. Serves as the dbt source table for the stg_synapse__webhook_allowed_domain staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.webhook_allowed_domain --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();


-- webhook_verification
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.webhook_verification --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.webhook_verification with no transformations applied. Serves as the dbt source table for the stg_synapse__webhook_verification staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.webhook_verification --noqa: JJ01,PRS,TMP
WHERE snapshot_date = CURRENT_DATE();
