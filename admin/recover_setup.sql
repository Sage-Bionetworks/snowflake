CREATE DATABASE IF NOT EXISTS recover;
CREATE SCHEMA IF NOT EXISTS pilot_raw
  WITH MANAGED ACCESS;
USE SCHEMA recover.pilot_raw;

USE ROLE securityadmin;
GRANT CREATE SCHEMA, USAGE ON DATABASE RECOVER
TO ROLE recover_data_engineer;
GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE recover
TO ROLE recover_data_engineer;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN DATABASE recover
TO ROLE recover_data_engineer;
GRANT USAGE ON WAREHOUSE recover_xsmall
TO ROLE recover_data_engineer;
GRANT USAGE ON DATABASE RECOVER
TO ROLE recover_data_analytics;
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE recover
TO ROLE recover_data_analytics;
GRANT SELECT ON FUTURE TABLES IN DATABASE recover
TO ROLE recover_data_analytics;

-- Set up storage integration
use role accountadmin;

CREATE STORAGE INTEGRATION IF NOT EXISTS recover_dev_s3
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::914833433684:role/snowflake_access'
  STORAGE_ALLOWED_LOCATIONS = ('s3://recover-dev-processed-data', 's3://recover-dev-intermediate-data');

DESC INTEGRATION recover_dev_s3;
GRANT USAGE ON INTEGRATION recover_dev_s3
TO ROLE SYSADMIN;
use role sysadmin;
CREATE STAGE IF NOT EXISTS recover_dev
  STORAGE_INTEGRATION = recover_dev_s3
  URL = 's3://recover-dev-processed-data'
  FILE_FORMAT = (TYPE = PARQUET COMPRESSION = AUTO);

CREATE STAGE IF NOT EXISTS recover_dev_intermediate
  STORAGE_INTEGRATION = recover_dev_s3
  URL = 's3://recover-dev-intermediate-data'
  FILE_FORMAT = (TYPE = JSON COMPRESSION = AUTO);

LIST @recover_dev/main/parquet
PATTERN = '^((?!archive|owner).)*$';

CREATE FILE FORMAT IF NOT EXISTS my_parquet
  TYPE = PARQUET
  COMPRESSION = AUTO;