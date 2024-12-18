USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Add table comment
COMMENT ON TABLE userprofilesnapshot IS 'This table contain snapshots of user-profiles. Snapshots are taken when user profiles are created or modified. Note: Snapshots are also taken periodically and independently of the changes. The snapshot_timestamp records when the snapshot was taken.';

-- Add column comments
COMMENT ON COLUMN userprofilesnapshot.change_type IS 'The type of change that occurred to the user profile, e.g., CREATE, UPDATE (Snapshotting does not capture DELETE change).';
COMMENT ON COLUMN userprofilesnapshot.change_timestamp IS 'The time when any change to the user profile was made (e.g. create or update).';
COMMENT ON COLUMN userprofilesnapshot.change_user_id IS 'The unique identifier of the user who made the change to the user profile.';
COMMENT ON COLUMN userprofilesnapshot.snapshot_timestamp IS 'The time when the snapshot was taken (It is usually after the change happened).';
COMMENT ON COLUMN userprofilesnapshot.id IS 'The unique identifier of the user.';
COMMENT ON COLUMN userprofilesnapshot.user_name IS 'The Synapse username.';
COMMENT ON COLUMN userprofilesnapshot.first_name IS 'The first name of the user.';
COMMENT ON COLUMN userprofilesnapshot.last_name IS 'The last name of the user.';
COMMENT ON COLUMN userprofilesnapshot.email IS 'The primary email of the user.';
COMMENT ON COLUMN userprofilesnapshot.location IS 'The location of the user.';
COMMENT ON COLUMN userprofilesnapshot.company IS 'The company where the user works.';
COMMENT ON COLUMN userprofilesnapshot.position IS 'The position of the user in the company.';
COMMENT ON COLUMN userprofilesnapshot.created_on IS 'The creation time of the user profile.';
COMMENT ON COLUMN userprofilesnapshot.snapshot_date IS 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';
