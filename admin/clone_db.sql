!set variable_substitution=true;

USE ROLE DATA_ENGINEER;

-- We clone the DB using the syntax seen here:
-- https://docs.snowflake.com/en/sql-reference/sql/create-clone#databases-schemas
CREATE DATABASE IDENTIFIER($cloned_db_name) CLONE SYNAPSE_DATA_WAREHOUSE_DEV;