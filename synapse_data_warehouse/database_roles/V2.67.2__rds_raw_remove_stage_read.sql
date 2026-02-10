USE DATABASE {{ database_name }}; --noqa: JJ01,PRS,TMP

-- Following the syntax here:
-- https://docs.snowflake.com/en/sql-reference/sql/drop-database-role
DROP DATABASE ROLE IF EXISTS RDS_RAW_STAGE_READ;
