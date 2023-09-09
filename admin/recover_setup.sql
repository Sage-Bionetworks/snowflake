USE ROLE sysadmin;
CREATE DATABASE IF NOT EXISTS recover;
CREATE SCHEMA IF NOT EXISTS pilot WITH MANAGED ACCESS;
USE SCHEMA recover.pilot;

USE ROLE securityadmin;
GRANT SELECT ON FUTURE TABLES IN SCHEMA RECOVER.PILOT
TO ROLE RECOVER_ADMIN;

-- GRANT SELECT ON ALL TABLES IN SCHEMA RECOVER.PILOT
-- TO ROLE RECOVER_ADMIN;

// Set up storage integration
use role accountadmin;

CREATE STORAGE INTEGRATION IF NOT EXISTS recover_dev_s3
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::914833433684:role/snowflake_access'
  STORAGE_ALLOWED_LOCATIONS = ('s3://recover-dev-processed-data');
  //[ STORAGE_BLOCKED_LOCATIONS = ('s3://<bucket>/<path>/', 's3://<bucket>/<path>/') ]

DESC INTEGRATION recover_dev_s3;
GRANT USAGE ON INTEGRATION recover_dev_s3 TO ROLE SYSADMIN;

use role sysadmin;

CREATE STAGE IF NOT EXISTS recover_dev
  STORAGE_INTEGRATION = recover_dev_s3
  URL = 's3://recover-dev-processed-data'
  FILE_FORMAT = (TYPE = PARQUET COMPRESSION = AUTO);

LIST @recover_dev/main/parquet
PATTERN = '^((?!archive|owner).)*$';

CREATE FILE FORMAT IF NOT EXISTS my_parquet
  TYPE = PARQUET
  COMPRESSION = AUTO;
  
SELECT *
  FROM TABLE(
    INFER_SCHEMA(
      LOCATION=>'@recover_dev/main/parquet/dataset_enrolledparticipants_customfields_symptoms/part-00000-2c0aad59-ee49-4046-b313-cb44d8b763e1-c000.snappy.parquet'
      , FILE_FORMAT=>'my_parquet'
      )
    );

USE ROLE recover_admin;
CREATE TABLE IF NOT EXISTS enrolledparticipants_customfields_symptoms
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_enrolledparticipants_customfields_symptoms'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into enrolledparticipants_customfields_symptoms
from '@recover_dev/main/parquet/dataset_enrolledparticipants_customfields_symptoms'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet') MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from enrolledparticipants_customfields_symptoms;

// dataset_enrolledparticipants
CREATE TABLE IF NOT EXISTS enrolledparticipants
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_enrolledparticipants'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into enrolledparticipants
from '@recover_dev/main/parquet/dataset_enrolledparticipants'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet') MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from enrolledparticipants limit 10;

// dataset_enrolledparticipants_customfields_treatments

CREATE TABLE IF NOT EXISTS enrolledparticipants_customfields_treatments
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_enrolledparticipants_customfields_treatments'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into enrolledparticipants_customfields_treatments
from '@recover_dev/main/parquet/dataset_enrolledparticipants_customfields_treatments'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet') MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from enrolledparticipants_customfields_treatments limit 10;

// dataset_fitbitactivitylogs

CREATE TABLE IF NOT EXISTS fitbitactivitylogs
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_fitbitactivitylogs'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into fitbitactivitylogs
from '@recover_dev/main/parquet/dataset_fitbitactivitylogs'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from fitbitactivitylogs limit 10;

// dataset_fitbitdailydata
CREATE TABLE IF NOT EXISTS fitbitdailydata
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_fitbitdailydata'
          , FILE_FORMAT=>'my_parquet'
        )
      ));
COPY into fitbitdailydata
from '@recover_dev/main/parquet/dataset_fitbitdailydata'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from fitbitdailydata limit 10;

// dataset_fitbitdevices

CREATE TABLE IF NOT EXISTS fitbitdevices
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_fitbitdevices'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into fitbitdevices
from '@recover_dev/main/parquet/dataset_fitbitdevices'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from fitbitdevices limit 10;

// dataset_fitbitintradaycombined

CREATE TABLE IF NOT EXISTS fitbitintradaycombined
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_fitbitintradaycombined'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into fitbitintradaycombined
from '@recover_dev/main/parquet/dataset_fitbitintradaycombined'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from fitbitintradaycombined limit 10;

// dataset_fitbitrestingheartrates
CREATE TABLE IF NOT EXISTS fitbitrestingheartrates
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_fitbitrestingheartrates'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into fitbitrestingheartrates
from '@recover_dev/main/parquet/dataset_fitbitrestingheartrates'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from fitbitrestingheartrates limit 10;

// dataset_fitbitsleeplogs

CREATE TABLE IF NOT EXISTS fitbitsleeplogs
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_fitbitsleeplogs'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into fitbitsleeplogs
from '@recover_dev/main/parquet/dataset_fitbitsleeplogs'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from fitbitsleeplogs limit 10;

// dataset_fitbitsleeplogs_sleeplogdetails

CREATE TABLE IF NOT EXISTS fitbitsleeplogs_sleeplogdetails
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_fitbitsleeplogs_sleeplogdetails'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into fitbitsleeplogs_sleeplogdetails
from '@recover_dev/main/parquet/dataset_fitbitsleeplogs_sleeplogdetails'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from fitbitsleeplogs_sleeplogdetails limit 10;

// dataset_garmindailysummary
// dataset_garmindailysummary_timeoffsetheartratesamples
// dataset_garminepochsummary
// dataset_garminhrvsummary
// dataset_garminhrvsummary_hrvvalues
// dataset_garminpulseoxsummary
// dataset_garminpulseoxsummary_timeoffsetspo2values
// dataset_garminrespirationsummary
// dataset_garminrespirationsummary_timeoffsetepochtobreaths
// dataset_garminsleepsummary
// dataset_garminsleepsummary_sleeplevelsmap_awake
// dataset_garminsleepsummary_sleeplevelsmap_deep
// dataset_garminsleepsummary_sleeplevelsmap_light
// dataset_garminsleepsummary_sleeplevelsmap_rem
// dataset_garminsleepsummary_sleepscoremodels
// dataset_garminsleepsummary_timeoffsetsleeprespiration
// dataset_garminsleepsummary_timeoffsetsleepspo2
// dataset_garminstressdetailsummary
// dataset_garminstressdetailsummary_timeoffsetbodybatteryvalues
// dataset_garminstressdetailsummary_timeoffsetstresslevelvalues
// dataset_googlefitsamples
// dataset_healthkitv2activitysummaries
// dataset_healthkitv2electrocardiogram
// dataset_healthkitv2electrocardiogram_subsamples
// dataset_healthkitv2heartbeat
// dataset_healthkitv2heartbeat_subsamples
// dataset_healthkitv2samples
// dataset_healthkitv2statistics
// dataset_healthkitv2workouts
// dataset_healthkitv2workouts_events
// dataset_symptomlog
// dataset_symptomlog_value_symptoms
// dataset_symptomlog_value_treatments
