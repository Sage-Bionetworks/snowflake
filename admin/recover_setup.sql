USE ROLE sysadmin;

CREATE DATABASE recover;
CREATE SCHEMA pilot WITH MANAGED ACCESS;
USE SCHEMA recover.pilot;

// Set up storage integration
use role accountadmin;

CREATE STORAGE INTEGRATION recover_dev_s3
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::914833433684:role/snowflake_access'
  STORAGE_ALLOWED_LOCATIONS = ('s3://recover-dev-processed-data');
  //[ STORAGE_BLOCKED_LOCATIONS = ('s3://<bucket>/<path>/', 's3://<bucket>/<path>/') ]

DESC INTEGRATION recover_dev_s3;
GRANT USAGE ON INTEGRATION recover_dev_s3 TO ROLE SYSADMIN;

USE SCHEMA recover.pilot;

use role sysadmin;

CREATE STAGE recover_dev
  STORAGE_INTEGRATION = recover_dev_s3
  URL = 's3://recover-dev-processed-data'
  FILE_FORMAT = (TYPE = PARQUET COMPRESSION = AUTO);


LIST @recover_dev;


select * from '@recover_dev/main/parquet/dataset_enrolledparticipants_customfields_symptoms/part-00000-2c0aad59-ee49-4046-b313-cb44d8b763e1-c000.snappy.parquet';

CREATE FILE FORMAT my_parquet
  TYPE = PARQUET
  COMPRESSION = AUTO;
  
SELECT *
  FROM TABLE(
    INFER_SCHEMA(
      LOCATION=>'@recover_dev/main/parquet/dataset_enrolledparticipants_customfields_symptoms/part-00000-2c0aad59-ee49-4046-b313-cb44d8b763e1-c000.snappy.parquet'
      , FILE_FORMAT=>'my_parquet'
      )
    );

CREATE TABLE enrolledparticipants_customfields_symptoms
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_enrolledparticipants_customfields_symptoms'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

USE ROLE securityadmin;

GRANT SELECT ON TABLE RECOVER.PILOT.ENROLLEDPARTICIPANTS_CUSTOMFIELDS_SYMPTOMS TO ROLE RECOVER_ADMIN;
// TODO add grant on stage

USE ROLE recover_admin;
COPY into enrolledparticipants_customfields_symptoms from '@recover_dev/main/parquet/dataset_enrolledparticipants_customfields_symptoms' FILE_FORMAT = (FORMAT_NAME= 'my_parquet') MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;
select * from enrolledparticipants_customfields_symptoms;

LIST @recover_dev/main/parquet
PATTERN = '^((?!archive|owner).)*$';


CREATE ROLE recover_admin;
USE ROLE securityadmin;
GRANT CREATE SCHEMA, USAGE on DATABASE RECOVER to ROLE recover_admin;
GRANT CREATE TABLE, USAGE on SCHEMA recover.pilot to ROLE recover_admin;

use role accountadmin;
GRANT ROLE recover_admin TO USER psnyder;
GRANT ROLE recover_admin TO USER rxu;

use ROLE sysadmin;

USE ROLE securityadmin;
GRANT USAGE ON WAREHOUSE recover_xsmall TO ROLE recover_admin;
GRANT ROLE recover_admin TO USER thomasyu888;

