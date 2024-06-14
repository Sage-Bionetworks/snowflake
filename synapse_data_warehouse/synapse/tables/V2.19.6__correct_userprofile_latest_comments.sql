USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

COMMENT ON COLUMN USERPROFILE_LATEST.id IS 'The unique identifier of the user.';
COMMENT ON COLUMN USERPROFILE_LATEST.user_name IS 'The Synapse username.';
COMMENT ON COLUMN USERPROFILE_LATEST.first_name IS 'The first name of the user.';
