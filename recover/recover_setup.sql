CREATE DATABASE IF NOT EXISTS recover;
CREATE SCHEMA IF NOT EXISTS pilot_raw
WITH MANAGED ACCESS;
USE SCHEMA recover.pilot_raw;

-- Set up storage integration

USE ROLE sysadmin;
CREATE STAGE IF NOT EXISTS recover_dev
  STORAGE_INTEGRATION = recover_dev_s3 --noqa: LT02,PRS
  URL = 's3://recover-dev-processed-data' --noqa: LT02
  FILE_FORMAT = (TYPE = PARQUET COMPRESSION = AUTO); --noqa: LT02
DESC INTEGRATION recover_dev_s3;

CREATE STAGE IF NOT EXISTS recover_dev_intermediate
  STORAGE_INTEGRATION = recover_dev_s3 --noqa: LT02
  URL = 's3://recover-dev-intermediate-data' --noqa: LT02
  FILE_FORMAT = (TYPE = JSON COMPRESSION = AUTO); --noqa: LT02

-- LIST @recover_dev/main/parquet
-- PATTERN = '^((?!archive|owner).)*$';

CREATE FILE FORMAT IF NOT EXISTS my_parquet
  TYPE = PARQUET
  COMPRESSION = AUTO;