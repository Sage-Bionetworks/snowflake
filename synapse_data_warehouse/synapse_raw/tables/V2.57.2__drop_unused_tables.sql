USE SCHEMA {{ database_name }}.synapse_raw; --noqa: JJ01,PRS,TMP

-- These tables are in prod and dev
-- This has been supplanted by the CERTIFIEDQUIZSNAPSHOTS table
DROP TABLE IF EXISTS CERTIFIEDQUIZ;
-- This has been supplanted by the CERTIFIEDQUIZQUESTIONSNAPSHOTS table
DROP TABLE IF EXISTS CERTIFIEDQUIZQUESTION;