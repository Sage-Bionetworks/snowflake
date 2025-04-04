-- Grant ownership of internamespace objects to proxy admin database role
-- SYNAPSE
GRANT OWNERSHIP
	ON ALL DYNAMIC TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.ALL_ADMIN
	COPY CURRENT GRANTS;

-- SYNAPSE_RAW
GRANT OWNERSHIP
	ON ALL TASKS
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_RAW
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.ALL_ADMIN
	COPY CURRENT GRANTS;