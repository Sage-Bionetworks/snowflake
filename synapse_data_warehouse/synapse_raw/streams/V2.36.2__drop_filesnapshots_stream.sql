-- Drop the snapshot stream
USE SCHEMA {{database_name}}.synapse_raw;
DROP STREAM IF EXISTS FILESNAPSHOTS_STREAM;