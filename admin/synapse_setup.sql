-- This is the admin setup of the synapse_data_warehouse prod and dev environments
-- This script has the external stages.
USE DATABASE synapse_data_warehouse;
USE ROLE sysadmin;
USE SCHEMA synapse_raw;
USE WAREHOUSE compute_org;

-- * SNOW-14
CREATE STAGE IF NOT EXISTS synapse_prod_warehouse_s3_stage
    STORAGE_INTEGRATION = synapse_prod_warehouse_s3 --noqa: LT02,PRS
    URL = 's3://prod.datawarehouse.sagebase.org/warehouse/'
    FILE_FORMAT = (TYPE = PARQUET COMPRESSION = AUTO)
    DIRECTORY = (ENABLE = TRUE);

ALTER STAGE IF EXISTS synapse_prod_warehouse_s3_stage REFRESH;


-- * Dev synapse setup
USE DATABASE synapse_data_warehouse_dev;
USE ROLE SYSADMIN;

CREATE STAGE IF NOT EXISTS synapse_dev_warehouse_s3_stage
    STORAGE_INTEGRATION = synapse_dev_warehouse_s3
    URL = 's3://dev.datawarehouse.sagebase.org/datawarehouse/'
    FILE_FORMAT = (TYPE = PARQUET COMPRESSION = AUTO)
    DIRECTORY = (ENABLE = TRUE);
ALTER STAGE IF EXISTS synapse_dev_warehouse_s3_stage REFRESH;
