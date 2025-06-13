USE SCHEMA {{ database_name }}.synapse; --noqa: JJ01,PRS,TMP

-- These tables are in prod and dev
-- This has been supplanted by the CERTIFIEDQUIZQUESTION_LATEST dynamic table
DROP TABLE IF EXISTS CERTIFIEDQUIZQUESTION_LATEST_BACKUP;
-- This has been supplanted by the TEAMMEMBER_LATEST dynamic table
DROP TABLE IF EXISTS TEAMMEMBER_LATEST_BACKUP;

-- This table is only in dev
-- This has been supplanted by the FILEHANDLEASSOCIATION_LATEST dynamic table
DROP TABLE IF EXISTS FILEHANDLE_ASSOCIATION;