USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

-- Clone the NODE_LATEST table to ``NODE_LATEST_BACKUP``
-- This will begin the process of converting ``NODE_LATEST`` table into a dynamic table
CREATE OR REPLACE TABLE NODE_LATEST_BACKUP CLONE NODE_LATEST;
