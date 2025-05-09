-- Grant data warehouse proxy admin role to database admin role
GRANT OWNERSHIP
    ON ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ALL_ADMIN
	TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ADMIN;
GRANT ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ALL_ADMIN
	TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ADMIN;

-- Grant the proxy admin role ownership and usage
-- of the `*ALL_ADMIN` database roles.
GRANT OWNERSHIP
    ON DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_ALL_ADMIN
    TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ALL_ADMIN
    COPY CURRENT GRANTS;
GRANT OWNERSHIP
    ON DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_RAW_ALL_ADMIN
    TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ALL_ADMIN
    COPY CURRENT GRANTS;
GRANT OWNERSHIP
    ON DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SCHEMACHANGE_ALL_ADMIN
    TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ALL_ADMIN
    COPY CURRENT GRANTS;

GRANT DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_ALL_ADMIN
    TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ALL_ADMIN;
GRANT DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_RAW_ALL_ADMIN
    TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ALL_ADMIN;
GRANT DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SCHEMACHANGE_ALL_ADMIN
    TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ALL_ADMIN;
