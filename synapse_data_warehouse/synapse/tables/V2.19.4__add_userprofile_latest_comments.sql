USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

COMMENT ON TABLE USERPROFILE_LATEST IS 'This table contain the latest snapshot of user-profiles. Snapshots are taken when user profiles are created or modified. Note: Snapshots are also taken periodically and independently of the changes. The snapshot_timestamp records when the snapshot was taken.';
COMMENT ON COLUMN USERPROFILE_LATEST.change_type IS 'The type of change that occurred to the user profile, e.g., CREATE, UPDATE (Snapshotting does not capture DELETE change).';
COMMENT ON COLUMN USERPROFILE_LATEST.change_timestamp IS 'The time when any change to the user profile was made (e.g. create or update).';
COMMENT ON COLUMN USERPROFILE_LATEST.change_user_id IS 'The unique identifier of the user who made the change to the user profile.';
COMMENT ON COLUMN USERPROFILE_LATEST.snapshot_timestamp IS 'The time when the snapshot was taken (It is usually after the change happened).';
COMMENT ON COLUMN USERPROFILE_LATEST.snapshot_date IS 'The snapshot_timestamp field is converted into a date and stored in the snapshot_date field.';
COMMENT ON COLUMN USERPROFILE_LATEST.id IS 'The unique identifier of a response wherein a user submitted a set of answers while participating in the quiz.';
COMMENT ON COLUMN USERPROFILE_LATEST.user_name  IS 'The Synapse username.'; 
COMMENT ON COLUMN USERPROFILE_LATEST.first_name IS 'The first name of the user.'; 
COMMENT ON COLUMN USERPROFILE_LATEST.last_name IS 'The last name of the user.';
COMMENT ON COLUMN USERPROFILE_LATEST.email IS 'The primary email of the user.';
COMMENT ON COLUMN USERPROFILE_LATEST.location IS 'The location of the user.';
COMMENT ON COLUMN USERPROFILE_LATEST.company IS 'The company where the user works.';
COMMENT ON COLUMN USERPROFILE_LATEST.position IS 'The position of the user in the company.';
COMMENT ON COLUMN USERPROFILE_LATEST.created_on IS 'The creation time of the user profile.';

