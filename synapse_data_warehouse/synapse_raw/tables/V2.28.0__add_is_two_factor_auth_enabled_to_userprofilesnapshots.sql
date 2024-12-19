-- Configure environment
USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP,CP02

-- Add new column
ALTER TABLE userprofilesnapshot ADD COLUMN is_two_factor_auth_enabled BOOLEAN COMMENT 'Indicates if the user had two factor authentication enabled when the snapshot was captured.';
ALTER TABLE userprofilesnapshot ADD COLUMN industry VARCHAR(255) COMMENT 'The industry/discipline that this person is associated with.';
ALTER TABLE userprofilesnapshot ADD COLUMN tos_agreements VARIANT COMMENT 'Contains the list of all the term of service that the user agreed to, with their agreed on date and version.';
