-- Add table and column comments to userprofile_latest dynamic table
USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

-- Table comments
COMMENT ON DYNAMIC TABLE USERPROFILE_LATEST IS 'This dynamic table contain the latest snapshot of user-profiles during the past 14 days. Snapshots are taken when user profiles are created or modified. Note: Snapshots are also taken periodically and independently of the changes. The snapshot_timestamp records when the snapshot was taken.';

-- Column comments
COMMENT ON COLUMN USERPROFILE_LATEST.CHANGE_TYPE IS 'The type of change that occurred to the user profile, e.g., CREATE, UPDATE (Snapshotting does not capture DELETE change).';
COMMENT ON COLUMN USERPROFILE_LATEST.CHANGE_TIMESTAMP IS 'The time when any change to the user profile was made (e.g. create or update).';
COMMENT ON COLUMN USERPROFILE_LATEST.CHANGE_USER_ID IS 'The unique identifier of the user who made the change to the user profile.';
COMMENT ON COLUMN USERPROFILE_LATEST.SNAPSHOT_TIMESTAMP IS 'The time when the snapshot was taken (It is usually after the change happened).';
COMMENT ON COLUMN USERPROFILE_LATEST.ID IS 'The unique identifier of the user.';
COMMENT ON COLUMN USERPROFILE_LATEST.USER_NAME IS 'The Synapse username.';
COMMENT ON COLUMN USERPROFILE_LATEST.FIRST_NAME IS 'The first name of the user.';
COMMENT ON COLUMN USERPROFILE_LATEST.LAST_NAME IS 'The last name of the user.';
COMMENT ON COLUMN USERPROFILE_LATEST.EMAIL IS 'The primary email of the user.';
COMMENT ON COLUMN USERPROFILE_LATEST.SNAPSHOT_DATE IS 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';
COMMENT ON COLUMN USERPROFILE_LATEST.CREATED_ON IS 'The creation time of the user profile.';
COMMENT ON COLUMN USERPROFILE_LATEST.IS_TWO_FACTOR_AUTH_ENABLED IS 'Indicates if the user had two factor authentication enabled when the snapshot was captured.';
COMMENT ON COLUMN USERPROFILE_LATEST.TOS_AGREEMENTS IS 'Contains the list of all the term of service that the user agreed to, with their agreed on date and version.';
COMMENT ON COLUMN USERPROFILE_LATEST.LOCATION IS 'The location of the user.';
COMMENT ON COLUMN USERPROFILE_LATEST.COMPANY IS 'The company where the user works.';
COMMENT ON COLUMN USERPROFILE_LATEST.POSITION IS 'The position of the user in the company.';
COMMENT ON COLUMN USERPROFILE_LATEST.INDUSTRY IS 'The industry/discipline that this person is associated with.';