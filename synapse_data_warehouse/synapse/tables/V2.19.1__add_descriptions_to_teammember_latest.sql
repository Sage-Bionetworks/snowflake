USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

ALTER TABLE TEAMMEMBER_LATEST SET COMMENT = 'The latest snapshot with information for team members in Synapse.';  

COMMENT ON COLUMN TEAMMEMBER_LATEST.change_timestamp IS 'The time when any change to the team was made (e.g. update of the team or a change to its members).';
COMMENT ON COLUMN TEAMMEMBER_LATEST.change_type IS 'The type of change that occurred to the member of team, e.g., CREATE, UPDATE (Snapshotting does not capture DELETE change).';
COMMENT ON COLUMN TEAMMEMBER_LATEST.change_user_id IS 'The unique identifier of the user who made the change to the team member.';
COMMENT ON COLUMN TEAMMEMBER_LATEST.is_admin IS 'If true, then the member is manager of the team.';
COMMENT ON COLUMN TEAMMEMBER_LATEST.member_id IS 'The unique identifier of the member of the team. The member is a Synapse user.';
COMMENT ON COLUMN TEAMMEMBER_LATEST.snapshot_date IS 'The date when the snapshot was taken.';  
COMMENT ON COLUMN TEAMMEMBER_LATEST.snapshot_timestamp IS 'The time when the snapshot was taken (It is usually after the change happened).';
COMMENT ON COLUMN TEAMMEMBER_LATEST.team_id IS 'The unique identifier of the team.';
