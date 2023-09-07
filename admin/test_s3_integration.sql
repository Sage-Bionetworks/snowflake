use role accountadmin;


CREATE STORAGE INTEGRATION test_s3
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::914833433684:role/snowflake_access'
  STORAGE_ALLOWED_LOCATIONS = ('s3://recover-dev-processed-data');
  //[ STORAGE_BLOCKED_LOCATIONS = ('s3://<bucket>/<path>/', 's3://<bucket>/<path>/') ]

DESC INTEGRATION test_s3;

USE SCHEMA synapse_data_warehouse.synapse_raw;

use role accountadmin;
GRANT USAGE ON INTEGRATION test_s3 TO ROLE SYSADMIN;

use role sysadmin;

CREATE STAGE my_test_s3_stage
  STORAGE_INTEGRATION = test_s3
  URL = 's3://tyu-test-snowflake/'
  FILE_FORMAT = (TYPE = PARQUET COMPRESSION = AUTO);


LIST @my_test_s3_stage;
use role sysadmin;

CREATE TABLE test_automation_table (
	session_id STRING,
    record_date DATE
);

// https://docs.snowflake.com/en/sql-reference/sql/create-task
use role accountadmin;
CREATE OR REPLACE TASK test_s3_integration
  SCHEDULE = 'USING CRON * * * * * America/Los_Angeles'
  USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
AS
copy into test_automation_table from (
  select 
     $1:session_id as session_id,
     NULLIF(
       regexp_replace (
       METADATA$FILENAME,
       '.*\=(.*)\/.*',
       '\\1'), 
       '__HIVE_DEFAULT_PARTITION__'
     )                         as record_date
   from @my_test_s3_stage/)
   pattern='.*processedaccess/record_date=.*/.*'
;
ALTER TASK test_s3_integration RESUME;
ALTER TASK test_s3_integration SET SCHEDULE = '60 MINUTE';

SHOW tasks;
DESCRIBE task test_s3_integration;

select *
  from table(information_schema.task_history())
  order by scheduled_time;

use role sysadmin;

select * from test_automation_table;



-- copy into test_automation_table from (
--   select 
--      $1:session_id as session_id,
--      NULLIF(
--        regexp_replace (
--        METADATA$FILENAME,
--        '.*\=(.*)\/.*',
--        '\\1'), 
--        '__HIVE_DEFAULT_PARTITION__'
--      )                         as record_date
--    from @my_test_s3_stage/)
--    pattern='.*processedaccess/record_date=.*/.*'
--    FORCE = TRUE;
-- DELETE FROM test_automation_table;