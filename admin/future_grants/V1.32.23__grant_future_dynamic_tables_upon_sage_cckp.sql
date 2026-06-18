-- Future grants for dynamic tables in SAGE.CCKP for the analyst role.
-- USAGE on future Streamlits is already covered by V1.32.16.
GRANT SELECT
    ON FUTURE DYNAMIC TABLES
    IN SCHEMA SAGE.CCKP
    TO ROLE SAGE_CCKP_ANALYST;
GRANT MONITOR
    ON FUTURE DYNAMIC TABLES
    IN SCHEMA SAGE.CCKP
    TO ROLE SAGE_CCKP_ANALYST;
