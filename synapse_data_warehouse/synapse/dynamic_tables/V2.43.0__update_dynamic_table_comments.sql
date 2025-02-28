-- Update table comments for userprofile_latest, file_latest, and teammember_latest dynamic table
USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

-- Table comments
ALTER DYNAMIC TABLE USERPROFILE_LATEST SET COMMENT = 'This dynamic table contains the most recent snapshot of user profiles from the past 14 days. The latest snapshots are determined by the most recent CHANGE_TIMESTAMP and SNAPSHOT_TIMESTAMP. If multiple snapshots exist within this period, only the latest snapshot for each ID is retained. Since snapshotting does not capture DELETE changes, records may still be retained if a user was deleted within the past 14 days. For easier querying, NULL values in the LOCATION, COMPANY, POSITION, and INDUSTRY columns are replaced with empty strings.'; 

ALTER DYNAMIC TABLE FILE_LATEST SET COMMENT = 'This dynamic table contains the most recent snapshot of files from the past 30 days. The latest snapshots are determined by the most recent CHANGE_TIMESTAMP and SNAPSHOT_TIMESTAMP. If multiple snapshots exist within this period, only the latest snapshot for each ID is retained.';

ALTER DYNAMIC TABLE TEAMMEMBER_LATEST SET COMMENT = 'This dynamic table contains the most recent snapshot of team members from the past 14 days. The latest snapshots are determined by the most recent CHANGE_TIMESTAMP and SNAPSHOT_TIMESTAMP. If multiple snapshots exist within this period, only the latest snapshot for each TEAM_ID and MEMBER_ID pair is retained. Since snapshotting does not capture DELETE changes, records may still be retained if a team member was deleted within the past 14 days.';
