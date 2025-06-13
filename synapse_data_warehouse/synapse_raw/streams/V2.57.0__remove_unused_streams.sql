USE SCHEMA {{ database_name }}.synapse_raw; --noqa: JJ01,PRS,TMP

-- All streams are stale and have already been supplanted by dynamic tables
-- These streams exist in dev/prod
DROP STREAM IF EXISTS USERGROUPSNAPSHOTS_STREAM;
DROP STREAM IF EXISTS VERIFICATIONSUBMISSIONSNAPSHOTS_STREAM;

-- These streams exist in dev only
DROP STREAM IF EXISTS ACLSNAPSHOTS_STREAM;
DROP STREAM IF EXISTS TEAMSNAPSHOTS_STREAM;