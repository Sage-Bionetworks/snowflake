-- Grant ownership of object types which potentially need
-- internamespace privileges and/or account-level privileges to admin role.
-- SYNAPSE
GRANT OWNERSHIP
	ON ALL DYNAMIC TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE
	TO ROLE SYNAPSE_DATA_WAREHOUSE_ALL_ADMIN
	COPY CURRENT GRANTS;

-- SYNAPSE_RAW
GRANT OWNERSHIP
	ON ALL TASKS
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW
	TO ROLE SYNAPSE_DATA_WAREHOUSE_ALL_ADMIN
	COPY CURRENT GRANTS;