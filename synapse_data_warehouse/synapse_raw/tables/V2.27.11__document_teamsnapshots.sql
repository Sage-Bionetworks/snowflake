USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Add table comment
COMMENT ON TABLE teamsnapshots IS 'This table contain snapshots of teams. Snapshots are taken when teams or its members are created or updated. Note: Snapshots are also taken periodically and independently of the changes. The snapshot_timestamp records when the snapshot was taken.';

-- Add column comments
COMMENT ON COLUMN teamsnapshots.change_type IS 'The type of change that occurred to the team, e.g., CREATE, UPDATE (Snapshotting does not capture DELETE change).';
COMMENT ON COLUMN teamsnapshots.change_timestamp IS 'The time when any change to the team was made (e.g. create, update or a change to its members).';
COMMENT ON COLUMN teamsnapshots.change_user_id IS 'The unique identifier of the user who made the change to the team.';
COMMENT ON COLUMN teamsnapshots.snapshot_timestamp IS 'The time when the snapshot was taken (It is usually after the change happened).';
COMMENT ON COLUMN teamsnapshots.id IS 'The unique identifier of the team.';
COMMENT ON COLUMN teamsnapshots.name IS 'The name of the team.';
COMMENT ON COLUMN teamsnapshots.can_public_join IS 'If true, a user can join the team without approval of a team manager.';
COMMENT ON COLUMN teamsnapshots.created_by IS 'The unique identifier of the user who created the team.';
COMMENT ON COLUMN teamsnapshots.created_on IS 'The creation time of the team.';
COMMENT ON COLUMN teamsnapshots.modified_by IS 'The unique identifier of the user who last modified the team.';
COMMENT ON COLUMN teamsnapshots.modified_on IS 'The time when the team was last modified.';
COMMENT ON COLUMN teamsnapshots.snapshot_date IS 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';
