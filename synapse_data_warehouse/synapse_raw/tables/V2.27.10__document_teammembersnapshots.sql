USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Add table comment
COMMENT ON TABLE teammembersnapshots IS 'This table contain snapshots of team-members. Snapshots are captured when a team and/or its members are modified. Note: Snapshots are also taken periodically and independently of the changes. The snapshot_timestamp records when the snapshot was taken.';

-- Add column comments
COMMENT ON COLUMN teammembersnapshots.change_type IS 'The type of change that occurred to the member of team, e.g., CREATE, UPDATE (Snapshotting does not capture DELETE change).';
COMMENT ON COLUMN teammembersnapshots.change_timestamp IS 'The time when any change to the team was made (e.g. update of the team or a change to its members).';
COMMENT ON COLUMN teammembersnapshots.change_user_id IS 'The unique identifier of the user who made the change to the team member.';
COMMENT ON COLUMN teammembersnapshots.snapshot_timestamp IS 'The time when the snapshot was taken (It is usually after the change happened).';
COMMENT ON COLUMN teammembersnapshots.team_id IS 'The unique identifier of the team.';
COMMENT ON COLUMN teammembersnapshots.member_id IS 'The unique identifier of the member of the team. The member is a Synapse user.';
COMMENT ON COLUMN teammembersnapshots.is_admin IS 'If true, then the member is manager of the team.';
COMMENT ON COLUMN teammembersnapshots.snapshot_date IS 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';
