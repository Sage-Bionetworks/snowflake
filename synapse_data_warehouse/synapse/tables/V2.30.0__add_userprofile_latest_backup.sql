-- Backup the original latest table 
USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

-- Clone the USERPROFILE_LATEST table to ``USERPROFILE_LATEST_BACKUP`` for validation purposes
CREATE OR REPLACE TABLE USERPROFILE_LATEST_BACKUP CLONE USERPROFILE_LATEST;
