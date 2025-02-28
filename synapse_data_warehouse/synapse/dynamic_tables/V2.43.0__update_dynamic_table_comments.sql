-- Update table comments for userprofile_latest, file_latest, and teammember_latest dynamic table
USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

-- Table comments
ALTER DYNAMIC TABLE USERPROFILE_LATEST SET COMMENT = 'This dynamic table, indexed by the ID column, contains the most recent snapshot of user profiles. Since snapshotting does not capture DELETE changes events, records may still be retained if a user was deleted within the past 14 days.'; 

ALTER DYNAMIC TABLE FILE_LATEST SET COMMENT = 'This dynamic table, indexed by the ID column, contains the most recent snapshot of file handles.';

ALTER DYNAMIC TABLE TEAMMEMBER_LATEST SET COMMENT = 'This dynamic table, indexed by the TEAM_ID and MEMBER_ID columns, contains the most recent snapshot of team members. Since snapshotting does not capture DELETE changes events, records may still be retained if a team member was deleted within the past 14 days.';
