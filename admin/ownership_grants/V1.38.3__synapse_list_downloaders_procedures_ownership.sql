-- The four LIST_DOWNLOADERS* procedures (synapse_data_warehouse/synapse/procedures/) were created
-- directly in Snowflake, never tracked by schemachange, before being brought under schemachange
-- management. SYNAPSE_DATA_WAREHOUSE_ADMIN (the schemachange deploy role) had no privileges on the
-- pre-existing objects, so its first CREATE OR REPLACE PROCEDURE failed with a 42710 permission error.
--
-- NOTE: Ownership is transferred to the PROXY_ADMIN account role (not a database role) because these
-- procedures run EXECUTE AS OWNER (except LIST_DOWNLOADERS_DBG, which is EXECUTE AS CALLER) and query
-- across the SYNAPSE/SYNAPSE_EVENT schema split; PROXY_ADMIN already directly owns the dynamic tables
-- (NODE_LATEST, FILE_LATEST, USERPROFILE_LATEST, OBJECTDOWNLOAD_EVENT) they read, matching the existing
-- cross-schema ownership pattern for tasks and dynamic tables. This holds in both PROD and DEV.
--
-- DEV's copies of these procedures already exist (deployed successfully via schemachange on
-- 2026-08-28), owned by SYNAPSE_DATA_WAREHOUSE_DEV_ADMIN with no further grants -- the same
-- "incorrect" default state PROD's copies would end up in without this script.

-------------------------------------------------------------------------------------------------
-- Grant ownership of the four existing procedures in PROD SYNAPSE to the PROXY_ADMIN account role:
-------------------------------------------------------------------------------------------------
GRANT OWNERSHIP
    ON PROCEDURE SYNAPSE_DATA_WAREHOUSE.SYNAPSE.LIST_DOWNLOADERS(VARCHAR, VARCHAR)
    TO ROLE SYNAPSE_DATA_WAREHOUSE_PROXY_ADMIN
    REVOKE CURRENT GRANTS;

GRANT OWNERSHIP
    ON PROCEDURE SYNAPSE_DATA_WAREHOUSE.SYNAPSE.LIST_DOWNLOADERS_DBG(DATE, VARCHAR)
    TO ROLE SYNAPSE_DATA_WAREHOUSE_PROXY_ADMIN
    REVOKE CURRENT GRANTS;

GRANT OWNERSHIP
    ON PROCEDURE SYNAPSE_DATA_WAREHOUSE.SYNAPSE.LIST_DOWNLOADERS_WITH_SIZE(VARCHAR, VARCHAR)
    TO ROLE SYNAPSE_DATA_WAREHOUSE_PROXY_ADMIN
    REVOKE CURRENT GRANTS;

GRANT OWNERSHIP
    ON PROCEDURE SYNAPSE_DATA_WAREHOUSE.SYNAPSE.LIST_DOWNLOADERS_WITH_SIZE_BY_MONTH(VARCHAR, VARCHAR)
    TO ROLE SYNAPSE_DATA_WAREHOUSE_PROXY_ADMIN
    REVOKE CURRENT GRANTS;

------------------------------------------------------------------------------------------------
-- Grant ownership of the four existing procedures in DEV SYNAPSE to the PROXY_ADMIN account role:
------------------------------------------------------------------------------------------------
GRANT OWNERSHIP
    ON PROCEDURE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE.LIST_DOWNLOADERS(VARCHAR, VARCHAR)
    TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_PROXY_ADMIN
    REVOKE CURRENT GRANTS;

GRANT OWNERSHIP
    ON PROCEDURE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE.LIST_DOWNLOADERS_DBG(DATE, VARCHAR)
    TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_PROXY_ADMIN
    REVOKE CURRENT GRANTS;

GRANT OWNERSHIP
    ON PROCEDURE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE.LIST_DOWNLOADERS_WITH_SIZE(VARCHAR, VARCHAR)
    TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_PROXY_ADMIN
    REVOKE CURRENT GRANTS;

GRANT OWNERSHIP
    ON PROCEDURE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE.LIST_DOWNLOADERS_WITH_SIZE_BY_MONTH(VARCHAR, VARCHAR)
    TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_PROXY_ADMIN
    REVOKE CURRENT GRANTS;
