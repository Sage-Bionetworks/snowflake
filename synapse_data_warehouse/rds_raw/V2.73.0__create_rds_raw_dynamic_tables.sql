-- Replace the manually-created placeholder tables in RDS_RAW with dynamic tables
-- that are sourced directly from their RDS_LANDING counterparts. No transformations
-- are applied; these are straight SELECT * copies. Transformation logic lives in the
-- dbt staging layer (stg_ views in this same schema).
--
-- Migration strategy: existing plain tables are RENAMED (not dropped) to _backup
-- names before the dynamic tables are created. This ensures there is no window
-- where the table name is absent. Once the dynamic tables have completed their
-- initial refresh from RDS_LANDING, the _backup tables can be dropped via
-- V2.72.1__drop_rds_raw_backup_tables.sql.
--
-- Ownership of these dynamic tables will be transferred to {{database_name}}_PROXY_ADMIN
-- by admin/ownership_grants/V1.36.0__rds_raw_dynamic_tables_ownership.sql.
-- Future dynamic tables in this schema will be automatically owned by PROXY_ADMIN
-- after admin/future_grants/V1.36.1__rds_raw_future_dynamic_tables.sql is applied.

USE SCHEMA {{database_name}}.RDS_RAW; --noqa: JJ01,PRS,TMP

-- Rename existing plain tables to _backup so the original name is free for the
-- dynamic table. Snowflake does not allow CREATE OR REPLACE DYNAMIC TABLE over
-- a plain TABLE, so a rename is safer than a DROP (no data loss during the gap).
ALTER TABLE IF EXISTS access_approval RENAME TO access_approval_backup;
ALTER TABLE IF EXISTS acl RENAME TO acl_backup;
ALTER TABLE IF EXISTS acl_resource_access RENAME TO acl_resource_access_backup;
ALTER TABLE IF EXISTS acl_resource_access_type RENAME TO acl_resource_access_type_backup;
ALTER TABLE IF EXISTS data_access_submission RENAME TO data_access_submission_backup;
ALTER TABLE IF EXISTS data_access_submission_accessor_changes RENAME TO data_access_submission_accessor_changes_backup;
ALTER TABLE IF EXISTS data_access_submission_status RENAME TO data_access_submission_status_backup;
ALTER TABLE IF EXISTS data_access_submission_submitter RENAME TO data_access_submission_submitter_backup;
ALTER TABLE IF EXISTS data_access_request RENAME TO data_access_request_backup;
ALTER TABLE IF EXISTS access_requirement RENAME TO access_requirement_backup;
ALTER TABLE IF EXISTS access_requirement_project RENAME TO access_requirement_project_backup;
ALTER TABLE IF EXISTS access_requirement_revision RENAME TO access_requirement_revision_backup;
ALTER TABLE IF EXISTS data_access_notification RENAME TO data_access_notification_backup;
ALTER TABLE IF EXISTS principal_alias RENAME TO principal_alias_backup;

-- access_approval
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.access_approval --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.access_approval with no transformations applied. Serves as the dbt source table for the stg_synapse__access_approval staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.access_approval --noqa: JJ01,PRS,TMP
WHERE snapshot_date >= DATEADD(day, -1, CURRENT_DATE())
QUALIFY snapshot_date = MAX(snapshot_date) OVER ();

-- acl
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.acl --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.acl with no transformations applied. Serves as the dbt source table for the stg_synapse__acl staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.acl --noqa: JJ01,PRS,TMP
WHERE snapshot_date >= DATEADD(day, -1, CURRENT_DATE())
QUALIFY snapshot_date = MAX(snapshot_date) OVER ();

-- acl_resource_access
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.acl_resource_access --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.acl_resource_access with no transformations applied. Serves as the dbt source table for the stg_synapse__acl_resource_access staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.acl_resource_access --noqa: JJ01,PRS,TMP
WHERE snapshot_date >= DATEADD(day, -1, CURRENT_DATE())
QUALIFY snapshot_date = MAX(snapshot_date) OVER ();

-- acl_resource_access_type
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.acl_resource_access_type --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.acl_resource_access_type with no transformations applied. Serves as the dbt source table for the stg_synapse__acl_resource_access_type staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.acl_resource_access_type --noqa: JJ01,PRS,TMP
WHERE snapshot_date >= DATEADD(day, -1, CURRENT_DATE())
QUALIFY snapshot_date = MAX(snapshot_date) OVER ();

-- data_access_submission
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.data_access_submission --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.data_access_submission with no transformations applied. Serves as the dbt source table for the stg_synapse__data_access_submission staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.data_access_submission --noqa: JJ01,PRS,TMP
WHERE snapshot_date >= DATEADD(day, -1, CURRENT_DATE())
QUALIFY snapshot_date = MAX(snapshot_date) OVER ();

-- data_access_submission_accessor_changes
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.data_access_submission_accessor_changes --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.data_access_submission_accessor_changes with no transformations applied. Serves as the dbt source table for the stg_synapse__data_access_submission_accessor_changes staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.data_access_submission_accessor_changes --noqa: JJ01,PRS,TMP
WHERE snapshot_date >= DATEADD(day, -1, CURRENT_DATE())
QUALIFY snapshot_date = MAX(snapshot_date) OVER ();

-- data_access_submission_status
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.data_access_submission_status --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.data_access_submission_status with no transformations applied. Serves as the dbt source table for the stg_synapse__data_access_submission_status staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.data_access_submission_status --noqa: JJ01,PRS,TMP
WHERE snapshot_date >= DATEADD(day, -1, CURRENT_DATE())
QUALIFY snapshot_date = MAX(snapshot_date) OVER ();

-- data_access_submission_submitter
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.data_access_submission_submitter --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.data_access_submission_submitter with no transformations applied. Serves as the dbt source table for the stg_synapse__data_access_submission_submitter staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.data_access_submission_submitter --noqa: JJ01,PRS,TMP
WHERE snapshot_date >= DATEADD(day, -1, CURRENT_DATE())
QUALIFY snapshot_date = MAX(snapshot_date) OVER ();

-- data_access_request
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.data_access_request --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.data_access_request with no transformations applied. Serves as the dbt source table for the stg_synapse__data_access_request staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.data_access_request --noqa: JJ01,PRS,TMP
WHERE snapshot_date >= DATEADD(day, -1, CURRENT_DATE())
QUALIFY snapshot_date = MAX(snapshot_date) OVER ();

-- access_requirement
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.access_requirement --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.access_requirement with no transformations applied. Serves as the dbt source table for the stg_synapse__access_requirement staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.access_requirement --noqa: JJ01,PRS,TMP
WHERE snapshot_date >= DATEADD(day, -1, CURRENT_DATE())
QUALIFY snapshot_date = MAX(snapshot_date) OVER ();

-- access_requirement_project
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.access_requirement_project --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.access_requirement_project with no transformations applied. Serves as the dbt source table for the stg_synapse__access_requirement_project staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.access_requirement_project --noqa: JJ01,PRS,TMP
WHERE snapshot_date >= DATEADD(day, -1, CURRENT_DATE())
QUALIFY snapshot_date = MAX(snapshot_date) OVER ();

-- access_requirement_revision
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.access_requirement_revision --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.access_requirement_revision with no transformations applied. Serves as the dbt source table for the stg_synapse__access_requirement_revision staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.access_requirement_revision --noqa: JJ01,PRS,TMP
WHERE snapshot_date >= DATEADD(day, -1, CURRENT_DATE())
QUALIFY snapshot_date = MAX(snapshot_date) OVER ();

-- data_access_notification
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.data_access_notification --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.data_access_notification with no transformations applied. Serves as the dbt source table for the stg_synapse__data_access_notification staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.data_access_notification --noqa: JJ01,PRS,TMP
WHERE snapshot_date >= DATEADD(day, -1, CURRENT_DATE())
QUALIFY snapshot_date = MAX(snapshot_date) OVER ();

-- principal_alias
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.RDS_RAW.principal_alias --noqa: JJ01,PRS,TMP
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Dynamic table sourcing all columns from RDS_LANDING.principal_alias with no transformations applied. Serves as the dbt source table for the stg_synapse__principal_alias staging model.'
AS
SELECT *
FROM {{database_name}}.RDS_LANDING.principal_alias --noqa: JJ01,PRS,TMP
WHERE snapshot_date >= DATEADD(day, -1, CURRENT_DATE())
QUALIFY snapshot_date = MAX(snapshot_date) OVER ();
