-- Steps are a CONTINUATION of the procedures started in /synapse_data_warehouse/database_roles for the RDS_RAW schema,
-- and are following the RBAC design pattern for schemas documented here:
-- https://sagebionetworks.jira.com/wiki/spaces/DPE/pages/4115366084/Managing+Object+Privileges#Schemas

-----------------------------------------------------------------------------------------------------------------
-- Grant read access on future tables in PROD database to the masked read access database role:
-----------------------------------------------------------------------------------------------------------------
GRANT SELECT, REFERENCES
	ON FUTURE TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.RDS_RAW
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.RDS_RAW_TABLE_READ_MASKED;


-----------------------------------------------------------------------------------------------------------------
-- Grant read access on future tables in DEV database to the masked read access database role:
-----------------------------------------------------------------------------------------------------------------
GRANT SELECT, REFERENCES
	ON FUTURE TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.RDS_RAW
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.RDS_RAW_TABLE_READ_MASKED;
