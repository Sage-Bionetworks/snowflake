USE ROLE DATA_ENGINEER;

-- We clone the DB using the syntax seen here:
-- https://docs.snowflake.com/en/sql-reference/sql/create-clone#databases-schemas
CREATE DATABASE &CLONED_DB_NAME CLONE SYNAPSE_DATA_WAREHOUSE_DEV;