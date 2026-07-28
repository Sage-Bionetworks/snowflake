USE SCHEMA {{database_name}}.RDS_LANDING; --noqa: JJ01,PRS,TMP

ALTER TABLE access_approval ALTER COLUMN snapshot_date COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE acl ALTER COLUMN snapshot_date COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE acl_resource_access ALTER COLUMN snapshot_date COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE acl_resource_access_type ALTER COLUMN snapshot_date COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE data_access_submission ALTER COLUMN snapshot_date COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE data_access_submission_accessor_changes ALTER COLUMN snapshot_date COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE data_access_submission_status ALTER COLUMN snapshot_date COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE data_access_submission_submitter ALTER COLUMN snapshot_date COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE data_access_request ALTER COLUMN snapshot_date COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE access_requirement ALTER COLUMN snapshot_date COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE access_requirement_project ALTER COLUMN snapshot_date COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE access_requirement_revision ALTER COLUMN snapshot_date COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE data_access_notification ALTER COLUMN snapshot_date COMMENT 'Date the RDS snapshot was taken (in UTC)';
ALTER TABLE principal_alias ALTER COLUMN snapshot_date COMMENT 'Date the RDS snapshot was taken (in UTC)';