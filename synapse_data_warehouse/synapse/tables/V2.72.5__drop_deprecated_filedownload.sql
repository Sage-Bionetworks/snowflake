USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

-- This table has been replaced by synapse_event.objectdownload_event (V2.56.0)
DROP TABLE IF EXISTS filedownload;
