USE SCHEMA {{database_name}}.RDS_RAW; --noqa: JJ01,PRS,TMP

-- Promotes RDS_LANDING tables whose upstream MySQL source is periodically
-- truncated (job/token/log-style tables), unlike the straight-copy tables in
-- V2.77.0. A same-day snapshot_date filter on these tables would silently
-- drop rows that existed in an earlier snapshot but were purged upstream
-- before today. Instead, dedup across all of RDS_LANDING history by natural
-- key, keeping the most recent snapshot_date seen for each key, so every
-- record ever observed is preserved even after it disappears upstream.
--
-- Confirmed via SNOW-562 investigation: these tables show near-zero overlap
-- in natural key between snapshots a month apart, unlike the immutable
-- tables in V2.77.0. A full-history QUALIFY dedup on COMPUTE_XSMALL was
-- measured at under 10 seconds even for the largest table here
-- (asynch_job_status, 86M+ rows / 45GB), so no incremental/task-based
-- approach is needed.
--
-- oauth_access_token.token_id is masked via the RDS_RAW PII masking
-- policies (admin/policies/V1.36.0), matching SYNAPSE_RDS_SNAPSHOT (SNOW-482).

-- asynch_job_status
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.asynch_job_status --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table deduplicating RDS_LANDING.asynch_job_status by job_id, keeping the most recent snapshot_date per key. asynch_job_status is periodically truncated upstream, so a same-day snapshot filter would silently drop historical records. Serves as the dbt source table for the stg_synapse__asynch_job_status staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.asynch_job_status --noqa: JJ01,PRS,TMP
QUALIFY ROW_NUMBER() OVER (PARTITION BY job_id ORDER BY snapshot_date DESC) = 1;

-- oauth_access_token
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.oauth_access_token --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table deduplicating RDS_LANDING.oauth_access_token by id, keeping the most recent snapshot_date per key. oauth_access_token is periodically truncated upstream, so a same-day snapshot filter would silently drop historical records. Serves as the dbt source table for the stg_synapse__oauth_access_token staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.oauth_access_token --noqa: JJ01,PRS,TMP
QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY snapshot_date DESC) = 1;
ALTER TABLE {{database_name}}.RDS_RAW.oauth_access_token --noqa: JJ01,PRS,TMP
    MODIFY COLUMN token_id SET MASKING POLICY {{database_name}}.RDS_RAW.PII_MASK_TEXT;

-- files_scanner_status
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.files_scanner_status --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table deduplicating RDS_LANDING.files_scanner_status by id, keeping the most recent snapshot_date per key. files_scanner_status is periodically truncated upstream, so a same-day snapshot filter would silently drop historical records. Serves as the dbt source table for the stg_synapse__files_scanner_status staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.files_scanner_status --noqa: JJ01,PRS,TMP
QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY snapshot_date DESC) = 1;

-- multipart_upload
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.multipart_upload --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table deduplicating RDS_LANDING.multipart_upload by id, keeping the most recent snapshot_date per key. multipart_upload is periodically truncated upstream, so a same-day snapshot filter would silently drop historical records. Serves as the dbt source table for the stg_synapse__multipart_upload staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.multipart_upload --noqa: JJ01,PRS,TMP
QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY snapshot_date DESC) = 1;

-- multipart_upload_part_state
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.multipart_upload_part_state --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table deduplicating RDS_LANDING.multipart_upload_part_state by upload_id, part_number, keeping the most recent snapshot_date per key. multipart_upload_part_state is periodically truncated upstream, so a same-day snapshot filter would silently drop historical records. Serves as the dbt source table for the stg_synapse__multipart_upload_part_state staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.multipart_upload_part_state --noqa: JJ01,PRS,TMP
QUALIFY ROW_NUMBER() OVER (PARTITION BY upload_id, part_number ORDER BY snapshot_date DESC) = 1;

-- trash_can
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.trash_can --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table deduplicating RDS_LANDING.trash_can by node_id, keeping the most recent snapshot_date per key. trash_can is periodically truncated upstream, so a same-day snapshot filter would silently drop historical records. Serves as the dbt source table for the stg_synapse__trash_can staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.trash_can --noqa: JJ01,PRS,TMP
QUALIFY ROW_NUMBER() OVER (PARTITION BY node_id ORDER BY snapshot_date DESC) = 1;

-- verification_file
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.verification_file --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table deduplicating RDS_LANDING.verification_file by verification_id, file_handle_id, keeping the most recent snapshot_date per key. verification_file is periodically truncated upstream, so a same-day snapshot filter would silently drop historical records. Serves as the dbt source table for the stg_synapse__verification_file staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.verification_file --noqa: JJ01,PRS,TMP
QUALIFY ROW_NUMBER() OVER (PARTITION BY verification_id, file_handle_id ORDER BY snapshot_date DESC) = 1;

-- json_schema_validation_results
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.json_schema_validation_results --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table deduplicating RDS_LANDING.json_schema_validation_results by object_id, object_type, schema_id, object_etag, keeping the most recent snapshot_date per key. json_schema_validation_results is periodically truncated upstream, so a same-day snapshot filter would silently drop historical records. Serves as the dbt source table for the stg_synapse__json_schema_validation_results staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.json_schema_validation_results --noqa: JJ01,PRS,TMP
QUALIFY ROW_NUMBER() OVER (PARTITION BY object_id, object_type, schema_id, object_etag ORDER BY snapshot_date DESC) = 1;

-- agent_trace
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.agent_trace --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table deduplicating RDS_LANDING.agent_trace by job_id, time_stamp, keeping the most recent snapshot_date per key. agent_trace is periodically truncated upstream, so a same-day snapshot filter would silently drop historical records. Serves as the dbt source table for the stg_synapse__agent_trace staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.agent_trace --noqa: JJ01,PRS,TMP
QUALIFY ROW_NUMBER() OVER (PARTITION BY job_id, time_stamp ORDER BY snapshot_date DESC) = 1;
