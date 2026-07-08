USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

-- This table has been replaced by synapse_event.access_event (V2.54.4)
DROP TABLE IF EXISTS processedaccess;
