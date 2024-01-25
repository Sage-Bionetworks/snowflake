USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
ALTER TABLE FILEDOWNLOAD ADD COLUMN session_id STRING;
