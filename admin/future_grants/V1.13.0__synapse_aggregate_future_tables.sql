-- SYNAPSE_DATA_WAREHOUSE_DEV
-- admin/ownership
GRANT OWNERSHIP
	ON FUTURE TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_AGGREGATE
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_AGGREGATE_ALL_ADMIN;
GRANT OWNERSHIP
	ON FUTURE DYNAMIC TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_AGGREGATE
	TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_PROXY_ADMIN;

-- analyst/read
GRANT SELECT, REFERENCES
	ON FUTURE TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_AGGREGATE
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_AGGREGATE_TABLE_READ;
GRANT SELECT, MONITOR
	ON FUTURE DYNAMIC TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_AGGREGATE
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_AGGREGATE_TABLE_READ;

-- SYNAPSE_DATA_WAREHOUSE
-- admin/ownership
GRANT OWNERSHIP
	ON FUTURE TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE_AGGREGATE
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SYNAPSE_AGGREGATE_ALL_ADMIN;
GRANT OWNERSHIP
	ON FUTURE DYNAMIC TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE_AGGREGATE
	TO ROLE SYNAPSE_DATA_WAREHOUSE_PROXY_ADMIN;

-- analyst/read
GRANT SELECT, REFERENCES
	ON FUTURE TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE_AGGREGATE
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SYNAPSE_AGGREGATE_TABLE_READ;
GRANT SELECT, MONITOR
	ON FUTURE DYNAMIC TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE_AGGREGATE
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SYNAPSE_AGGREGATE_TABLE_READ;
