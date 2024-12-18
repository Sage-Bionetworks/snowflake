USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Add table comment
COMMENT ON TABLE usergroupsnapshots IS 'This table lists all principals (individual users and groups of users). (A group is the low-level object of a underlying team, much like a file handle is the low-level object of an underlying file entity.) In addition to explicit users and teams, principals in Synapse include the anonymous user, the implicit group of all authenticated users, and the implicit public group which includes all users, authenticated or not. Note: Snapshots are also taken periodically and independently of the changes. The snapshot_timestamp records when the snapshot was taken.';

-- Add column comments
COMMENT ON COLUMN usergroupsnapshots.change_type IS 'The type of change that occurred to the user-group, e.g., CREATE, UPDATE (Snapshotting does not capture DELETE change).';
COMMENT ON COLUMN usergroupsnapshots.change_timestamp IS 'The time when the change (creation/update) to the user-group is pushed to the queue for snapshotting.';
COMMENT ON COLUMN usergroupsnapshots.change_user_id IS 'The unique identifier of the user who made the change to the user-group.';
COMMENT ON COLUMN usergroupsnapshots.snapshot_timestamp IS 'The time when the snapshot was taken (It is usually after the change happened).';
COMMENT ON COLUMN usergroupsnapshots.id IS 'The unique identifier of user or group.';
COMMENT ON COLUMN usergroupsnapshots.is_individual IS 'If true, then this user group is an individual user not a team.';
COMMENT ON COLUMN usergroupsnapshots.created_on IS 'The creation time of the user or group.';
COMMENT ON COLUMN usergroupsnapshots.snapshot_date IS 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';
