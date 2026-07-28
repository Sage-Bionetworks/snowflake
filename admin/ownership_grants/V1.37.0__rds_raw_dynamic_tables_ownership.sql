-- Transfer ownership of all dynamic tables in RDS_RAW to the PROXY_ADMIN account role.
-- Dynamic tables (like tasks) must be owned by an account role, not a database role.
-- This script runs after synapse_data_warehouse/ schemachange (which creates the dynamic
-- tables as DATA_ENGINEER) and transfers ownership to PROXY_ADMIN.
-- See admin/future_grants/V1.36.1__rds_raw_future_dynamic_tables.sql for future coverage.

GRANT OWNERSHIP
    ON ALL DYNAMIC TABLES
    IN SCHEMA SYNAPSE_DATA_WAREHOUSE.RDS_RAW
    TO ROLE SYNAPSE_DATA_WAREHOUSE_PROXY_ADMIN
    REVOKE CURRENT GRANTS;

GRANT OWNERSHIP
    ON ALL DYNAMIC TABLES
    IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.RDS_RAW
    TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_PROXY_ADMIN
    REVOKE CURRENT GRANTS;
