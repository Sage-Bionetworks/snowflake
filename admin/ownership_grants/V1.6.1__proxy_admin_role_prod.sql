-- Grant the proxy admin database role ownership and usage
-- of the `*ALL_ADMIN` database roles.
GRANT OWNERSHIP
    ON DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SYNAPSE_ALL_ADMIN
    TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.ALL_ADMIN
    COPY CURRENT GRANTS;
GRANT OWNERSHIP
    ON DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW_ALL_ADMIN
    TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.ALL_ADMIN
    COPY CURRENT GRANTS;
GRANT OWNERSHIP
    ON DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SCHEMACHANGE_ALL_ADMIN
    TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.ALL_ADMIN
    COPY CURRENT GRANTS;

GRANT DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SYNAPSE_ALL_ADMIN
    TO ROLE SYNAPSE_DATA_WAREHOUSE.ALL_ADMIN; --noqa: JJ01,PRS,TMP
GRANT DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW_ALL_ADMIN
    TO ROLE SYNAPSE_DATA_WAREHOUSE.ALL_ADMIN; --noqa: JJ01,PRS,TMP
GRANT DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SCHEMACHANGE_ALL_ADMIN
    TO ROLE SYNAPSE_DATA_WAREHOUSE.ALL_ADMIN; --noqa: JJ01,PRS,TMP