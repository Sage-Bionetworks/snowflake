USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- * SNOW-11 add user profile snapshots
CREATE TABLE IF NOT EXISTS temp_validation_table (
    temp_validation_type STRING,
    temp_validation_id NUMBER,
);