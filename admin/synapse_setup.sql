// Follow this blog https://www.snowflake.com/blog/how-to-load-terabytes-into-snowflake-speeds-feeds-and-techniques/#:~:text=Best%20Practices%20for%20Parquet%20and%20ORC
USE DATABASE synapse_data_warehouse;
USE SCHEMA synapse_raw;
USE WAREHOUSE COMPUTE_ORG;
USE ROLE ACCOUNTADMIN;
-- * Test Integration
CREATE STORAGE INTEGRATION IF NOT EXISTS synapse_dev_warehouse_s3
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::449435941126:role/test-snowflake-access-SnowflakeServiceRole-1LXZYAMMKTHJY'
  STORAGE_ALLOWED_LOCATIONS = ('s3://dev.datawarehouse.sagebase.org');
-- * Integration to prod (SNOW-14)
CREATE STORAGE INTEGRATION IF NOT EXISTS synapse_prod_warehouse_s3
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::325565585839:role/snowflake-accesss-SnowflakeServiceRole-HL66JOP7K4BT'
  STORAGE_ALLOWED_LOCATIONS = ('s3://prod.datawarehouse.sagebase.org');
DESC INTEGRATION synapse_dev_warehouse_s3;
DESC INTEGRATION synapse_prod_warehouse_s3;

USE SCHEMA synapse_data_warehouse.synapse_raw;
USE ROLE SECURITYADMIN;
GRANT USAGE ON INTEGRATION synapse_dev_warehouse_s3
TO ROLE SYSADMIN;
GRANT USAGE ON INTEGRATION synapse_prod_warehouse_s3
TO ROLE SYSADMIN;

-- * Create external stage
USE ROLE sysadmin;
USE DATABASE synapse_data_warehouse;
USE SCHEMA synapse_raw;
CREATE STAGE IF NOT EXISTS synapse_dev_warehouse_s3_stage
  STORAGE_INTEGRATION = synapse_dev_warehouse_s3
  URL = 's3://dev.datawarehouse.sagebase.org/datawarehouse/'
  FILE_FORMAT = (TYPE = PARQUET COMPRESSION = AUTO)
  DIRECTORY = (ENABLE = TRUE);

ALTER STAGE IF EXISTS synapse_dev_warehouse_s3_stage REFRESH;
LIST @synapse_dev_warehouse_s3_stage;

-- * SNOW-14
CREATE STAGE IF NOT EXISTS synapse_prod_warehouse_s3_stage
  STORAGE_INTEGRATION = synapse_prod_warehouse_s3
  URL = 's3://prod.datawarehouse.sagebase.org/warehouse/'
  FILE_FORMAT = (TYPE = PARQUET COMPRESSION = AUTO)
  DIRECTORY = (ENABLE = TRUE);

ALTER STAGE IF EXISTS synapse_prod_warehouse_s3_stage REFRESH;

USE ROLE SECURITYADMIN;

GRANT CREATE MASKING POLICY ON SCHEMA SYNAPSE_DATA_WAREHOUSE.synapse
TO ROLE masking_admin;
GRANT CREATE SCHEMA, USAGE ON DATABASE SYNAPSE_DATA_WAREHOUSE
TO ROLE data_engineer;
-- GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE SYNAPSE_DATA_WAREHOUSE
-- TO ROLE data_engineer;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN DATABASE SYNAPSE_DATA_WAREHOUSE
-- TO ROLE data_engineer;
GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE SYNAPSE_DATA_WAREHOUSE
TO ROLE data_engineer;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN DATABASE SYNAPSE_DATA_WAREHOUSE
TO ROLE data_engineer;
