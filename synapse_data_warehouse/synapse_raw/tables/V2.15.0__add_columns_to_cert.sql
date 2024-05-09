USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
ALTER TABLE certifiedquizsnapshots ADD COLUMN revoked BOOLEAN;
ALTER TABLE certifiedquizsnapshots ADD COLUMN revoked_on TIMESTAMP;
ALTER TABLE certifiedquizsnapshots ADD COLUMN certified BOOLEAN;
