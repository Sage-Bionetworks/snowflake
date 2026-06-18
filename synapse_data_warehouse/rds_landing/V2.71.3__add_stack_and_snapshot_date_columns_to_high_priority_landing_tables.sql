USE SCHEMA {{database_name}}.RDS_LANDING; --noqa: JJ01,PRS,TMP

ALTER TABLE access_approval
    ADD COLUMN IF NOT EXISTS stack         VARCHAR COMMENT 'The Synapse stack number from which this RDS snapshot was taken',
    ADD COLUMN IF NOT EXISTS snapshot_date DATE    COMMENT 'The date on which the RDS snapshot was taken';

ALTER TABLE acl
    ADD COLUMN IF NOT EXISTS stack         VARCHAR COMMENT 'The Synapse stack number from which this RDS snapshot was taken',
    ADD COLUMN IF NOT EXISTS snapshot_date DATE    COMMENT 'The date on which the RDS snapshot was taken';

ALTER TABLE acl_resource_access
    ADD COLUMN IF NOT EXISTS stack         VARCHAR COMMENT 'The Synapse stack number from which this RDS snapshot was taken',
    ADD COLUMN IF NOT EXISTS snapshot_date DATE    COMMENT 'The date on which the RDS snapshot was taken';

ALTER TABLE acl_resource_access_type
    ADD COLUMN IF NOT EXISTS stack         VARCHAR COMMENT 'The Synapse stack number from which this RDS snapshot was taken',
    ADD COLUMN IF NOT EXISTS snapshot_date DATE    COMMENT 'The date on which the RDS snapshot was taken';

ALTER TABLE data_access_submission
    ADD COLUMN IF NOT EXISTS stack         VARCHAR COMMENT 'The Synapse stack number from which this RDS snapshot was taken',
    ADD COLUMN IF NOT EXISTS snapshot_date DATE    COMMENT 'The date on which the RDS snapshot was taken';

ALTER TABLE data_access_submission_accessor_changes
    ADD COLUMN IF NOT EXISTS stack         VARCHAR COMMENT 'The Synapse stack number from which this RDS snapshot was taken',
    ADD COLUMN IF NOT EXISTS snapshot_date DATE    COMMENT 'The date on which the RDS snapshot was taken';

ALTER TABLE data_access_submission_status
    ADD COLUMN IF NOT EXISTS stack         VARCHAR COMMENT 'The Synapse stack number from which this RDS snapshot was taken',
    ADD COLUMN IF NOT EXISTS snapshot_date DATE    COMMENT 'The date on which the RDS snapshot was taken';

ALTER TABLE data_access_submission_submitter
    ADD COLUMN IF NOT EXISTS stack         VARCHAR COMMENT 'The Synapse stack number from which this RDS snapshot was taken',
    ADD COLUMN IF NOT EXISTS snapshot_date DATE    COMMENT 'The date on which the RDS snapshot was taken';

ALTER TABLE data_access_request
    ADD COLUMN IF NOT EXISTS stack         VARCHAR COMMENT 'The Synapse stack number from which this RDS snapshot was taken',
    ADD COLUMN IF NOT EXISTS snapshot_date DATE    COMMENT 'The date on which the RDS snapshot was taken';

ALTER TABLE access_requirement
    ADD COLUMN IF NOT EXISTS stack         VARCHAR COMMENT 'The Synapse stack number from which this RDS snapshot was taken',
    ADD COLUMN IF NOT EXISTS snapshot_date DATE    COMMENT 'The date on which the RDS snapshot was taken';

ALTER TABLE access_requirement_project
    ADD COLUMN IF NOT EXISTS stack         VARCHAR COMMENT 'The Synapse stack number from which this RDS snapshot was taken',
    ADD COLUMN IF NOT EXISTS snapshot_date DATE    COMMENT 'The date on which the RDS snapshot was taken';

ALTER TABLE access_requirement_revision
    ADD COLUMN IF NOT EXISTS stack         VARCHAR COMMENT 'The Synapse stack number from which this RDS snapshot was taken',
    ADD COLUMN IF NOT EXISTS snapshot_date DATE    COMMENT 'The date on which the RDS snapshot was taken';

ALTER TABLE data_access_notification
    ADD COLUMN IF NOT EXISTS stack         VARCHAR COMMENT 'The Synapse stack number from which this RDS snapshot was taken',
    ADD COLUMN IF NOT EXISTS snapshot_date DATE    COMMENT 'The date on which the RDS snapshot was taken';

ALTER TABLE principal_alias
    ADD COLUMN IF NOT EXISTS stack         VARCHAR COMMENT 'The Synapse stack number from which this RDS snapshot was taken',
    ADD COLUMN IF NOT EXISTS snapshot_date DATE    COMMENT 'The date on which the RDS snapshot was taken';
