-- Steps are a CONTINUATION of the procedures started in /synapse_data_warehouse/database_roles for the RDS_RAW schema,
-- and are following the RBAC design pattern for schemas documented here:
-- https://sagebionetworks.jira.com/wiki/spaces/DPE/pages/4115366084/Managing+Object+Privileges#Schemas

--------------------------------------------------------------------------------------------------------
-- Step 9) Grant ownership of future tables in PROD database to <SCHEMA>_ALL_ADMIN database role:
--------------------------------------------------------------------------------------------------------
GRANT OWNERSHIP
	ON FUTURE TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.RDS_RAW
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.RDS_RAW_ALL_ADMIN;


--------------------------------------------------------------------------------------------------------
-- Step 10) Grant ownership of future tables in DEV database to <SCHEMA>_ALL_ADMIN database role:
--------------------------------------------------------------------------------------------------------
GRANT OWNERSHIP
	ON FUTURE TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.RDS_RAW
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.RDS_RAW_ALL_ADMIN;


-----------------------------------------------------------------------------------------------------------------
-- Step 11) Grant read access on future tables in PROD database to appropriate read access database roles:
-----------------------------------------------------------------------------------------------------------------
GRANT SELECT, REFERENCES
	ON FUTURE TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.RDS_RAW
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.RDS_RAW_TABLE_READ;


-----------------------------------------------------------------------------------------------------------------
-- Step 12) Grant read access on future tables in DEV database to appropriate read access database roles:
-----------------------------------------------------------------------------------------------------------------
GRANT SELECT, REFERENCES
	ON FUTURE TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.RDS_RAW
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.RDS_RAW_TABLE_READ;
