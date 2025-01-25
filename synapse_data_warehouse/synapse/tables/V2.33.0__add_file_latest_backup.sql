-- Backup the original latest table 
USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

-- Clone the FILE_LATEST table to ``FILE_LATEST_BACKUP`` for validation purposes
CREATE OR REPLACE TABLE FILE_LATEST_BACKUP CLONE FILE_LATEST;
