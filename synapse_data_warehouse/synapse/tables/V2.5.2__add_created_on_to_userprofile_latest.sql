USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP
ALTER TABLE userprofilesnapshot ADD COLUMN created_on TIMESTAMP;