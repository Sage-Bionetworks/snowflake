USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Add table comment
COMMENT ON TABLE aclsnapshots IS 'This table contain snapshots of access-control-list. Snapshots are taken when an acl is created, updated or deleted. Note: Snapshots are also taken periodically and independently of the changes. The snapshot_timestamp records when the snapshot was taken.';

-- Add column comments
COMMENT ON COLUMN aclsnapshots.change_timestamp IS 'The time when the change (created/updated/deleted) on an acl is pushed to the queue for snapshotting.';
COMMENT ON COLUMN aclsnapshots.change_type IS 'The type of change that occurred on the acl, e.g., CREATE, UPDATE, DELETE.';
COMMENT ON COLUMN aclsnapshots.snapshot_timestamp IS 'The time when the snapshot was taken (It is usually after the change happened).';
COMMENT ON COLUMN aclsnapshots.owner_id IS 'The unique identifier of the Synapse object to which the acl is applied.';
COMMENT ON COLUMN aclsnapshots.owner_type IS 'The type of the Synapse object that the acl is affecting, .e.g., ENTITY, FILE, SUBMISSION, MESSAGE, TEAM.';
COMMENT ON COLUMN aclsnapshots.created_on IS 'The creation time of the acl.';
COMMENT ON COLUMN aclsnapshots.resource_access IS 'The list of principals (users or teams) along with the permissions the principal is granted on the object to which the acl is applied.';
COMMENT ON COLUMN aclsnapshots.snapshot_date IS 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';
