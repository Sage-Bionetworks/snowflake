-- Steps are a CONTINUATION of the procedures started in /synapse_data_warehouse/database_roles for the RDS_RAW schema,
-- and are following the RBAC design pattern for schemas documented here:
-- https://sagebionetworks.jira.com/wiki/spaces/DPE/pages/4115366084/Managing+Object+Privileges#Schemas

GRANT SELECT, REFERENCES
	ON FUTURE TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.RDS_RAW
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.RDS_RAW_TABLE_READ_MASKED;

GRANT SELECT, REFERENCES
	ON FUTURE TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.RDS_RAW
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.RDS_RAW_TABLE_READ_MASKED;
