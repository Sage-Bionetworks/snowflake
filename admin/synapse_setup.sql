-- This is the admin setup of the synapse_data_warehouse prod and dev environments
-- This script has the storage integration, external stages, and grants the resources
-- to the appropriate roles
USE DATABASE synapse_data_warehouse;
USE ROLE SYSADMIN;
CREATE SCHEMA IF NOT EXISTS synapse_raw
    WITH MANAGED ACCESS;
CREATE SCHEMA IF NOT EXISTS synapse
    WITH MANAGED ACCESS;
USE SCHEMA synapse_raw;
USE WAREHOUSE compute_org;
USE ROLE account_admin;

-- * Integration to prod (SNOW-14)
CREATE STORAGE INTEGRATION IF NOT EXISTS synapse_prod_warehouse_s3
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::325565585839:role/snowflake-accesss-SnowflakeServiceRole-HL66JOP7K4BT'
    STORAGE_ALLOWED_LOCATIONS = ('s3://prod.datawarehouse.sagebase.org');

DESC INTEGRATION synapse_prod_warehouse_s3;


-- * SNOW-14
CREATE STAGE IF NOT EXISTS synapse_prod_warehouse_s3_stage
    STORAGE_INTEGRATION = synapse_prod_warehouse_s3
    URL = 's3://prod.datawarehouse.sagebase.org/warehouse/'
    FILE_FORMAT = (TYPE = PARQUET COMPRESSION = AUTO)
    DIRECTORY = (ENABLE = TRUE);

ALTER STAGE IF EXISTS synapse_prod_warehouse_s3_stage REFRESH;
USE SCHEMA synapse_data_warehouse.synapse_raw;
USE ROLE securityadmin;
GRANT USAGE ON INTEGRATION synapse_prod_warehouse_s3
TO ROLE sysadmin;
GRANT CREATE MASKING POLICY ON SCHEMA SYNAPSE_DATA_WAREHOUSE.synapse
TO ROLE masking_admin;
GRANT CREATE SCHEMA, USAGE ON DATABASE SYNAPSE_DATA_WAREHOUSE
TO ROLE data_engineer;

GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE SYNAPSE_DATA_WAREHOUSE
TO ROLE data_engineer;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN DATABASE SYNAPSE_DATA_WAREHOUSE
TO ROLE data_engineer;

// Public role
// Synapse data warehouse
GRANT USAGE ON SCHEMA synapse_data_warehouse.synapse
TO ROLE PUBLIC;
-- GRANT SELECT ON ALL TABLES IN SCHEMA synapse_data_warehouse.synapse
-- TO ROLE PUBLIC;
-- GRANT SELECT ON ALL VIEWS IN SCHEMA synapse_data_warehouse.synapse
-- TO ROLE PUBLIC;
GRANT SELECT ON FUTURE TABLES IN SCHEMA synapse_data_warehouse.synapse
TO ROLE PUBLIC;


-- * Dev synapse setup
USE DATABASE synapse_data_warehouse_dev;
USE ROLE SYSADMIN;
CREATE SCHEMA IF NOT EXISTS synapse_raw
    WITH MANAGED ACCESS;
CREATE SCHEMA IF NOT EXISTS synapse
    WITH MANAGED ACCESS;
USE SCHEMA synapse_raw;
USE WAREHOUSE compute_org;
USE ROLE account_admin;
CREATE STORAGE INTEGRATION IF NOT EXISTS synapse_dev_warehouse_s3
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::449435941126:role/test-snowflake-access-SnowflakeServiceRole-1LXZYAMMKTHJY'
    STORAGE_ALLOWED_LOCATIONS = ('s3://dev.datawarehouse.sagebase.org');
DESC INTEGRATION synapse_dev_warehouse_s3;
CREATE STAGE IF NOT EXISTS synapse_dev_warehouse_s3_stage
    STORAGE_INTEGRATION = synapse_dev_warehouse_s3
    URL = 's3://dev.datawarehouse.sagebase.org/datawarehouse/'
    FILE_FORMAT = (TYPE = PARQUET COMPRESSION = AUTO)
    DIRECTORY = (ENABLE = TRUE);
ALTER STAGE IF EXISTS synapse_dev_warehouse_s3_stage REFRESH;
USE SCHEMA synapse_data_warehouse_dev.synapse_raw;
USE ROLE securityadmin;
GRANT USAGE ON INTEGRATION synapse_dev_warehouse_s3
TO ROLE sysadmin;

-- GRANT CREATE MASKING POLICY ON SCHEMA synapse_data_warehouse_dev.synapse
-- TO ROLE masking_admin;
GRANT CREATE SCHEMA, USAGE ON DATABASE synapse_data_warehouse_dev
TO ROLE data_engineer;
GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE synapse_data_warehouse_dev
TO ROLE data_engineer;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN DATABASE synapse_data_warehouse_dev
TO ROLE data_engineer;
