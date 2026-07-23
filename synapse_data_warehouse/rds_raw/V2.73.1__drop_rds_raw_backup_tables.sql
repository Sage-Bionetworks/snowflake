-- Drop the _backup plain tables created by V2.72.0__create_rds_raw_dynamic_tables.sql.
-- These were the original manually-created placeholder tables in RDS_RAW, renamed
-- to _backup to preserve their rows during the transition to dynamic tables.
-- This script should only be applied after confirming that the dynamic tables
-- created in V2.72.0 have completed their initial refresh from RDS_LANDING.

USE SCHEMA {{database_name}}.RDS_RAW; --noqa: JJ01,PRS,TMP

DROP TABLE IF EXISTS access_approval_backup;
DROP TABLE IF EXISTS acl_backup;
DROP TABLE IF EXISTS acl_resource_access_backup;
DROP TABLE IF EXISTS acl_resource_access_type_backup;
DROP TABLE IF EXISTS data_access_submission_backup;
DROP TABLE IF EXISTS data_access_submission_accessor_changes_backup;
DROP TABLE IF EXISTS data_access_submission_status_backup;
DROP TABLE IF EXISTS data_access_submission_submitter_backup;
DROP TABLE IF EXISTS data_access_request_backup;
DROP TABLE IF EXISTS access_requirement_backup;
DROP TABLE IF EXISTS access_requirement_project_backup;
DROP TABLE IF EXISTS access_requirement_revision_backup;
DROP TABLE IF EXISTS data_access_notification_backup;
DROP TABLE IF EXISTS principal_alias_backup;
