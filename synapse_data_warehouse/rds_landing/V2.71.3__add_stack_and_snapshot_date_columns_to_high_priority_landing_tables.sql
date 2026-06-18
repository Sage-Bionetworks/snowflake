USE SCHEMA {{database_name}}.RDS_LANDING; --noqa: JJ01,PRS,TMP

ALTER TABLE access_approval ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE access_approval ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE access_approval ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';

ALTER TABLE acl ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE acl ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE acl ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';

ALTER TABLE acl_resource_access ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE acl_resource_access ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE acl_resource_access ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';

ALTER TABLE acl_resource_access_type ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE acl_resource_access_type ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE acl_resource_access_type ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';

ALTER TABLE data_access_submission ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE data_access_submission ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE data_access_submission ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';

ALTER TABLE data_access_submission_accessor_changes ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE data_access_submission_accessor_changes ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE data_access_submission_accessor_changes ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';

ALTER TABLE data_access_submission_status ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE data_access_submission_status ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE data_access_submission_status ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';

ALTER TABLE data_access_submission_submitter ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE data_access_submission_submitter ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE data_access_submission_submitter ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';

ALTER TABLE data_access_request ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE data_access_request ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE data_access_request ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';

ALTER TABLE access_requirement ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE access_requirement ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE access_requirement ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';

ALTER TABLE access_requirement_project ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE access_requirement_project ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE access_requirement_project ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';

ALTER TABLE access_requirement_revision ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE access_requirement_revision ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE access_requirement_revision ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';

ALTER TABLE data_access_notification ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE data_access_notification ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE data_access_notification ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';

ALTER TABLE principal_alias ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE principal_alias ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE principal_alias ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
