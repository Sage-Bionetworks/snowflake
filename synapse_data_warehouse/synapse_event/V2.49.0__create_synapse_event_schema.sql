USE DATABASE {{ database_name }}; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE SCHEMA SYNAPSE_EVENT
    COMMENT = 'A schema for Synapse event data. Event data is derived from raw data by retaining only the most recent snapshot for each index.';
