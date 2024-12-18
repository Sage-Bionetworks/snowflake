-- Configure environment
USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP,CP02

-- Add new column
ALTER TABLE userprofilesnapshot
  ADD COLUMN is_two_factor_auth_enabled BOOLEAN
  COMMENT 'Indicates if the user had two factor authentication enabled when the snapshot was captured.';