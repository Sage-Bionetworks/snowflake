-- Backup the original latest table 
USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

-- Clone the TEAMMEMBER_LATEST table to ``TEAMMEMBER_LATEST_BACKUP`` for validation purposes
CREATE OR REPLACE TABLE TEAMMEMBER_LATEST_BACKUP CLONE TEAMMEMBER_LATEST;
