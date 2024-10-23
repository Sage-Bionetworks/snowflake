!set variable_substitution=true; --noqa: PRS

USE ROLE DATA_ENGINEER;

SET DB_NAME = CLONED_DB_NAME;

-- We clone the DB using the syntax seen here:
-- https://docs.snowflake.com/en/sql-reference/sql/create-clone#databases-schemas
CREATE DATABASE IDENTIFIER(DB_NAME) CLONE SYNAPSE_DATA_WAREHOUSE_DEV;