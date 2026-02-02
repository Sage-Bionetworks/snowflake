-- Steps are a CONTINUATION of the procedures started in /synapse_data_warehouse/database_roles for the RDS_LANDING schema,
-- and are following the RBAC design pattern for schemas documented here:
-- https://sagebionetworks.jira.com/wiki/spaces/DPE/pages/4115366084/Managing+Object+Privileges#Schemas

------------------------------------------------------------------------------------------
-- Step 7) Grant ownership of schema in PROD database to <SCHEMA>_ALL_ADMIN database role:
------------------------------------------------------------------------------------------
GRANT OWNERSHIP
    ON SCHEMA SYNAPSE_DATA_WAREHOUSE.RDS_LANDING
    TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.RDS_LANDING_ALL_ADMIN
    REVOKE CURRENT GRANTS;


-----------------------------------------------------------------------------------------
-- Step 8) Grant ownership of schema in DEV database to <SCHEMA>_ALL_ADMIN database role:
-----------------------------------------------------------------------------------------
GRANT OWNERSHIP
    ON SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.RDS_LANDING
    TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.RDS_LANDING_ALL_ADMIN
    REVOKE CURRENT GRANTS;
