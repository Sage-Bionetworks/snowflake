-- The four LIST_DOWNLOADERS* procedures (synapse_data_warehouse/synapse/procedures/) were created
-- directly in Snowflake, never tracked by schemachange, before being brought under schemachange
-- management. SYNAPSE_DATA_WAREHOUSE_ADMIN (the schemachange deploy role) had no privileges on the
-- pre-existing objects, so its first CREATE OR REPLACE PROCEDURE failed with a 42710 permission error.
-- This script codifies the correct ownership model.
--
-- NOTE: Ownership is transferred to the PROXY_ADMIN account role (not a database role) because
-- procedures may generally require cross-schema privileges.

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
