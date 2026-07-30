USE SCHEMA {{database_name}}.RDS_LANDING; --noqa: JJ01,PRS,TMP

-- ACCESS_APPROVAL
-- Add ingest metadata columns
ALTER TABLE access_approval ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE access_approval ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE access_approval ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE access_approval CLUSTER BY (snapshot_date);

-- ACL
-- Add ingest metadata columns
ALTER TABLE acl ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE acl ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE acl ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE acl CLUSTER BY (snapshot_date);

-- ACL_RESOURCE_ACCESS
-- Add ingest metadata columns
ALTER TABLE acl_resource_access ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE acl_resource_access ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE acl_resource_access ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE acl_resource_access CLUSTER BY (snapshot_date);

-- ACL_RESOURCE_ACCESS_TYPE
-- Add ingest metadata columns
ALTER TABLE acl_resource_access_type ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE acl_resource_access_type ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE acl_resource_access_type ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE acl_resource_access_type CLUSTER BY (snapshot_date);

-- DATA_ACCESS_SUBMISSION
-- Add ingest metadata columns
ALTER TABLE data_access_submission ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE data_access_submission ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE data_access_submission ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE data_access_submission CLUSTER BY (snapshot_date);

-- DATA_ACCESS_SUBMISSION_ACCESSOR_CHANGES
-- Add ingest metadata columns
ALTER TABLE data_access_submission_accessor_changes ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE data_access_submission_accessor_changes ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE data_access_submission_accessor_changes ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE data_access_submission_accessor_changes CLUSTER BY (snapshot_date);

-- DATA_ACCESS_SUBMISSION_STATUS
-- Add ingest metadata columns
ALTER TABLE data_access_submission_status ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE data_access_submission_status ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE data_access_submission_status ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE data_access_submission_status CLUSTER BY (snapshot_date);

-- DATA_ACCESS_SUBMISSION_SUBMITTER
-- Add ingest metadata columns
ALTER TABLE data_access_submission_submitter ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE data_access_submission_submitter ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE data_access_submission_submitter ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE data_access_submission_submitter CLUSTER BY (snapshot_date);

-- DATA_ACCESS_REQUEST
-- Add ingest metadata columns
ALTER TABLE data_access_request ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE data_access_request ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE data_access_request ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE data_access_request CLUSTER BY (snapshot_date);

-- ACCESS_REQUIREMENT
-- Add ingest metadata columns
ALTER TABLE access_requirement ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE access_requirement ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE access_requirement ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE access_requirement CLUSTER BY (snapshot_date);

-- ACCESS_REQUIREMENT_PROJECT
-- Add ingest metadata columns
ALTER TABLE access_requirement_project ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE access_requirement_project ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE access_requirement_project ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE access_requirement_project CLUSTER BY (snapshot_date);

-- ACCESS_REQUIREMENT_REVISION
-- Add ingest metadata columns
ALTER TABLE access_requirement_revision ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE access_requirement_revision ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE access_requirement_revision ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE access_requirement_revision CLUSTER BY (snapshot_date);

-- DATA_ACCESS_NOTIFICATION
-- Add ingest metadata columns
ALTER TABLE data_access_notification ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE data_access_notification ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE data_access_notification ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE data_access_notification CLUSTER BY (snapshot_date);

-- PRINCIPAL_ALIAS
-- Add ingest metadata columns
ALTER TABLE principal_alias ADD COLUMN stack INTEGER COMMENT 'The Synapse stack number from which this RDS snapshot was taken';
ALTER TABLE principal_alias ADD COLUMN snapshot_date DATE COMMENT 'The date on which the RDS snapshot was taken';
ALTER TABLE principal_alias ADD COLUMN filename VARCHAR COMMENT 'The S3 path of the parquet file from which this record was loaded';
-- Cluster by snapshot_date
ALTER TABLE principal_alias CLUSTER BY (snapshot_date);
