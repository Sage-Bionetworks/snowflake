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
CREATE TABLE IF NOT EXISTS garmindailysummary
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garmindailysummary'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garmindailysummary
from '@recover_dev/main/parquet/dataset_garmindailysummary'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garmindailysummary limit 10;

// dataset_garmindailysummary_timeoffsetheartratesamples

CREATE TABLE IF NOT EXISTS garmindailysummary_timeoffsetheartratesamples
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garmindailysummary_timeoffsetheartratesamples'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garmindailysummary_timeoffsetheartratesamples
from '@recover_dev/main/parquet/dataset_garmindailysummary_timeoffsetheartratesamples'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garmindailysummary_timeoffsetheartratesamples limit 10;

// dataset_garminepochsummary
CREATE TABLE IF NOT EXISTS garminepochsummary
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garminepochsummary'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garminepochsummary
from '@recover_dev/main/parquet/dataset_garminepochsummary'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garminepochsummary limit 10;
// dataset_garminhrvsummary
CREATE TABLE IF NOT EXISTS garminhrvsummary
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garminhrvsummary'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garminhrvsummary
from '@recover_dev/main/parquet/dataset_garminhrvsummary'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garminhrvsummary limit 10;
// dataset_garminhrvsummary_hrvvalues
CREATE TABLE IF NOT EXISTS garminhrvsummary_hrvvalues
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garminhrvsummary_hrvvalues'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garminhrvsummary_hrvvalues
from '@recover_dev/main/parquet/dataset_garminhrvsummary_hrvvalues'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garminhrvsummary_hrvvalues limit 10;
// dataset_garminpulseoxsummary

CREATE TABLE IF NOT EXISTS garminpulseoxsummary
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garminpulseoxsummary'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garminpulseoxsummary
from '@recover_dev/main/parquet/dataset_garminpulseoxsummary'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garminpulseoxsummary limit 10;
// dataset_garminpulseoxsummary_timeoffsetspo2values
CREATE TABLE IF NOT EXISTS garminpulseoxsummary_timeoffsetspo2values
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garminpulseoxsummary_timeoffsetspo2values'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garminpulseoxsummary_timeoffsetspo2values
from '@recover_dev/main/parquet/dataset_garminpulseoxsummary_timeoffsetspo2values'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garminpulseoxsummary_timeoffsetspo2values limit 10;
// dataset_garminrespirationsummary
CREATE TABLE IF NOT EXISTS garminrespirationsummary
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garminrespirationsummary'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garminrespirationsummary
from '@recover_dev/main/parquet/dataset_garminrespirationsummary'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garminrespirationsummary limit 10;
// dataset_garminrespirationsummary_timeoffsetepochtobreaths
CREATE TABLE IF NOT EXISTS garminrespirationsummary_timeoffsetepochtobreaths
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garminrespirationsummary_timeoffsetepochtobreaths'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garminrespirationsummary_timeoffsetepochtobreaths
from '@recover_dev/main/parquet/dataset_garminrespirationsummary_timeoffsetepochtobreaths'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garminrespirationsummary_timeoffsetepochtobreaths limit 10;

// dataset_garminsleepsummary
CREATE TABLE IF NOT EXISTS garminsleepsummary
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garminsleepsummary'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garminsleepsummary
from '@recover_dev/main/parquet/dataset_garminsleepsummary'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garminsleepsummary limit 10;

// dataset_garminsleepsummary_sleeplevelsmap_awake
CREATE TABLE IF NOT EXISTS garminsleepsummary_sleeplevelsmap_awake
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garminsleepsummary_sleeplevelsmap_awake'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garminsleepsummary_sleeplevelsmap_awake
from '@recover_dev/main/parquet/dataset_garminsleepsummary_sleeplevelsmap_awake'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garminsleepsummary_sleeplevelsmap_awake limit 10;
// dataset_garminsleepsummary_sleeplevelsmap_deep
CREATE TABLE IF NOT EXISTS garminsleepsummary_sleeplevelsmap_deep
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garminsleepsummary_sleeplevelsmap_deep'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garminsleepsummary_sleeplevelsmap_deep
from '@recover_dev/main/parquet/dataset_garminsleepsummary_sleeplevelsmap_deep'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garminsleepsummary_sleeplevelsmap_deep limit 10;
// dataset_garminsleepsummary_sleeplevelsmap_light
CREATE TABLE IF NOT EXISTS garminsleepsummary_sleeplevelsmap_light
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garminsleepsummary_sleeplevelsmap_light'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garminsleepsummary_sleeplevelsmap_light
from '@recover_dev/main/parquet/dataset_garminsleepsummary_sleeplevelsmap_light'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garminsleepsummary_sleeplevelsmap_light limit 10;
// dataset_garminsleepsummary_sleeplevelsmap_rem
CREATE TABLE IF NOT EXISTS garminsleepsummary_sleeplevelsmap_rem
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garminsleepsummary_sleeplevelsmap_rem'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garminsleepsummary_sleeplevelsmap_rem
from '@recover_dev/main/parquet/dataset_garminsleepsummary_sleeplevelsmap_rem'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garminsleepsummary_sleeplevelsmap_rem limit 10;
// dataset_garminsleepsummary_sleepscoremodels
CREATE TABLE IF NOT EXISTS garminsleepsummary_sleepscoremodels
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garminsleepsummary_sleepscoremodels'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garminsleepsummary_sleepscoremodels
from '@recover_dev/main/parquet/dataset_garminsleepsummary_sleepscoremodels'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garminsleepsummary_sleepscoremodels limit 10;
// dataset_garminsleepsummary_timeoffsetsleeprespiration
CREATE TABLE IF NOT EXISTS garminsleepsummary_timeoffsetsleeprespiration
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garminsleepsummary_timeoffsetsleeprespiration'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garminsleepsummary_timeoffsetsleeprespiration
from '@recover_dev/main/parquet/dataset_garminsleepsummary_timeoffsetsleeprespiration'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garminsleepsummary_timeoffsetsleeprespiration limit 10;
// dataset_garminsleepsummary_timeoffsetsleepspo2

CREATE TABLE IF NOT EXISTS garminsleepsummary_timeoffsetsleepspo2
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garminsleepsummary_timeoffsetsleepspo2'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garminsleepsummary_timeoffsetsleepspo2
from '@recover_dev/main/parquet/dataset_garminsleepsummary_timeoffsetsleepspo2'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garminsleepsummary_timeoffsetsleepspo2 limit 10;
// dataset_garminstressdetailsummary

CREATE TABLE IF NOT EXISTS garminstressdetailsummary
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garminstressdetailsummary'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garminstressdetailsummary
from '@recover_dev/main/parquet/dataset_garminstressdetailsummary'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garminstressdetailsummary limit 10;
// dataset_garminstressdetailsummary_timeoffsetbodybatteryvalues

CREATE TABLE IF NOT EXISTS garminstressdetailsummary_timeoffsetbodybatteryvalues
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garminstressdetailsummary_timeoffsetbodybatteryvalues'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garminstressdetailsummary_timeoffsetbodybatteryvalues
from '@recover_dev/main/parquet/dataset_garminstressdetailsummary_timeoffsetbodybatteryvalues'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garminstressdetailsummary_timeoffsetbodybatteryvalues limit 10;
// dataset_garminstressdetailsummary_timeoffsetstresslevelvalues

CREATE TABLE IF NOT EXISTS garminstressdetailsummary_timeoffsetstresslevelvalues
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_garminstressdetailsummary_timeoffsetstresslevelvalues'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into garminstressdetailsummary_timeoffsetstresslevelvalues
from '@recover_dev/main/parquet/dataset_garminstressdetailsummary_timeoffsetstresslevelvalues'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from garminstressdetailsummary_timeoffsetstresslevelvalues limit 10;
// dataset_googlefitsamples

CREATE TABLE IF NOT EXISTS googlefitsamples
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_googlefitsamples'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into googlefitsamples
from '@recover_dev/main/parquet/dataset_googlefitsamples'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from googlefitsamples limit 10;
// dataset_healthkitv2activitysummaries

CREATE TABLE IF NOT EXISTS healthkitv2activitysummaries
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_healthkitv2activitysummaries'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into healthkitv2activitysummaries
from '@recover_dev/main/parquet/dataset_healthkitv2activitysummaries'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from healthkitv2activitysummaries limit 10;
// dataset_healthkitv2electrocardiogram

CREATE TABLE IF NOT EXISTS healthkitv2electrocardiogram
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_healthkitv2electrocardiogram'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into healthkitv2electrocardiogram
from '@recover_dev/main/parquet/dataset_healthkitv2electrocardiogram'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from healthkitv2electrocardiogram limit 10;
// dataset_healthkitv2electrocardiogram_subsamples

CREATE TABLE IF NOT EXISTS healthkitv2electrocardiogram_subsamples
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_healthkitv2electrocardiogram_subsamples'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into healthkitv2electrocardiogram_subsamples
from '@recover_dev/main/parquet/dataset_healthkitv2electrocardiogram_subsamples'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from healthkitv2electrocardiogram_subsamples limit 10;
// dataset_healthkitv2heartbeat

CREATE TABLE IF NOT EXISTS healthkitv2heartbeat
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_healthkitv2heartbeat'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into healthkitv2heartbeat
from '@recover_dev/main/parquet/dataset_healthkitv2heartbeat'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from healthkitv2heartbeat limit 10;
// dataset_healthkitv2heartbeat_subsamples

CREATE TABLE IF NOT EXISTS healthkitv2heartbeat_subsamples
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_healthkitv2heartbeat_subsamples'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into healthkitv2heartbeat_subsamples
from '@recover_dev/main/parquet/dataset_healthkitv2heartbeat_subsamples'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from healthkitv2heartbeat_subsamples limit 10;
// dataset_healthkitv2samples

CREATE TABLE IF NOT EXISTS healthkitv2samples
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_healthkitv2samples'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into healthkitv2samples
from '@recover_dev/main/parquet/dataset_healthkitv2samples'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from healthkitv2samples limit 10;
// dataset_healthkitv2statistics

CREATE TABLE IF NOT EXISTS healthkitv2statistics
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_healthkitv2statistics'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into healthkitv2statistics
from '@recover_dev/main/parquet/dataset_healthkitv2statistics'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from healthkitv2statistics limit 10;
// dataset_healthkitv2workouts

CREATE TABLE IF NOT EXISTS healthkitv2workouts
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_healthkitv2workouts'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into healthkitv2workouts
from '@recover_dev/main/parquet/dataset_healthkitv2workouts'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from healthkitv2workouts limit 10;
// dataset_healthkitv2workouts_events

CREATE TABLE IF NOT EXISTS healthkitv2workouts_events
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_healthkitv2workouts_events'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into healthkitv2workouts_events
from '@recover_dev/main/parquet/dataset_healthkitv2workouts_events'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from healthkitv2workouts_events limit 10;
// dataset_symptomlog

CREATE TABLE IF NOT EXISTS symptomlog
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_symptomlog'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into symptomlog
from '@recover_dev/main/parquet/dataset_symptomlog'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from symptomlog limit 10;
// dataset_symptomlog_value_symptoms
CREATE TABLE IF NOT EXISTS symptomlog_value_symptoms
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_symptomlog_value_symptoms'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into symptomlog_value_symptoms
from '@recover_dev/main/parquet/dataset_symptomlog_value_symptoms'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from symptomlog_value_symptoms limit 10;
// dataset_symptomlog_value_treatments
CREATE TABLE IF NOT EXISTS symptomlog_value_treatments
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@recover_dev/main/parquet/dataset_symptomlog_value_treatments'
          , FILE_FORMAT=>'my_parquet'
        )
      ));

COPY into symptomlog_value_treatments
from '@recover_dev/main/parquet/dataset_symptomlog_value_treatments'
  FILE_FORMAT = (FORMAT_NAME= 'my_parquet')
  MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

select * from symptomlog_value_treatments limit 10;
