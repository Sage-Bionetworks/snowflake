USE DATABASE {{ database_name }}; --noqa: JJ01,PRS,TMP

-- RDS_RAW_ALL_ADMIN owns the dbt-managed staging/intermediate views inside RDS_RAW, but
-- dynamic tables in RDS_RAW are owned by the PROXY_ADMIN account role (Snowflake requires
-- an account role to own dynamic tables), so schema ownership no longer gives
-- RDS_RAW_ALL_ADMIN implicit read access to them.
GRANT DATABASE ROLE RDS_RAW_TABLE_READ
    TO DATABASE ROLE RDS_RAW_ALL_ADMIN;
