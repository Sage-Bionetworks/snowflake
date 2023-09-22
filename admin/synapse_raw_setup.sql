USE DATABASE synapse_data_warehouse;
USE SCHEMA synapse_raw;
USE WAREHOUSE COMPUTE_ORG;
USE ROLE ACCOUNTADMIN;

CREATE STORAGE INTEGRATION IF NOT EXISTS test_s3
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::631692904429:role/test_snowflake_integration'
  STORAGE_ALLOWED_LOCATIONS = ('s3://tyu-test-snowflake');

DESC INTEGRATION test_s3;
USE SCHEMA synapse_data_warehouse.synapse_raw;
GRANT USAGE ON INTEGRATION test_s3 TO ROLE SYSADMIN;

USE ROLE sysadmin;
// Use this stage for now my_test_s3_stage
CREATE STAGE IF NOT EXISTS my_test_s3_stage
  STORAGE_INTEGRATION = test_s3
  URL = 's3://tyu-test-snowflake/'
  FILE_FORMAT = (TYPE = PARQUET COMPRESSION = AUTO)
  DIRECTORY = (ENABLE = TRUE);

ALTER STAGE IF EXISTS my_test_s3_stage REFRESH;
LIST @my_test_s3_stage;

// First time copying into the warehouse
CREATE OR REPLACE TABLE userprofilesnapshot (
  change_timestamp TIMESTAMP,
  snapshot_timestamp TIMESTAMP,
  id NUMBER,
  user_name STRING,
  first_name STRING,
  last_name STRING,
  email STRING,
  location STRING,
  company STRING,
  position STRING,
  snapshot_date DATE
);

USE WAREHOUSE COMPUTE_MEDIUM;
copy into
  userprofilesnapshot
from (
  select 
    $1:change_timestamp as change_timestamp,
    $1:snapshot_timestamp as snapshot_timestamp,
    $1:id as id,
    $1:user_name as user_name,
    $1:first_name as first_name,
    $1:last_name as last_name,
    $1:email as email,
    $1:location as location,
    $1:company as company,
    $1:position as position,
      NULLIF(
        regexp_replace(
          metadata$filename,
          '^userprofilesnapshots\/snapshot_date\=(.*)\/.*', '\\1'
        ), 
        '__HIVE_DEFAULT_PARTITION__'
      ) as snapshot_date
  from
    @my_test_s3_stage/userprofilesnapshots
  )
pattern='.*userprofilesnapshots/snapshot_date=.*/.*'
;

// create certified quiz
CREATE TABLE IF NOT EXISTS certifiedquiz (
    response_id NUMBER,
    user_id NUMBER,
    passed BOOLEAN,
    passed_on TIMESTAMP,
    stack STRING,
    instance STRING,
    record_date DATE
);

-- CREATE OR REPLACE EXTERNAL TABLE certifiedquiz_external (
--   response_id number AS (value:response_id::number),
--   user_id number AS (value:user_id::number),
--   passed boolean AS (value:passed::boolean),
--   passed_on timestamp AS (value:passed_on::timestamp),
--   stack varchar AS (value:stack::varchar),
--   instance varchar AS (value:instance::varchar),
--   record_date date as to_date(substring(metadata$filename, 34,10))
-- ) PARTITION BY (record_date)
--   LOCATION=@my_test_s3_stage/certifiedquizrecords
--   AUTO_REFRESH = false
--   FILE_FORMAT=(TYPE = PARQUET COMPRESSION = AUTO);
-- -- certifiedquizrecords/record_date=2022-07-08/
-- CREATE OR REPLACE STREAM certifiedquiz_stream ON EXTERNAL TABLE certifiedquiz_external INSERT_ONLY = TRUE;
-- ALTER EXTERNAL TABLE certifiedquiz_external REFRESH;


copy into
  certifiedquiz
from (
  select 
     $1:response_id as response_id,
     $1:user_id as user_id,
     $1:passed as passed,
     $1:passed_on as passed_on,
     $1:stack as stack,
     $1:instance as instance,
     NULLIF(
       regexp_replace (
       METADATA$FILENAME,
       '^certifiedquizrecords\/record_date\=(.*)\/.*',
       '\\1'), 
       '__HIVE_DEFAULT_PARTITION__'
     )                         as record_date
  from
    @my_test_s3_stage/certifiedquizrecords
  )
pattern='.*record_date=.*/.*'
;
TRUNCATE TABLE IF EXISTS certifiedquiz;
copy into certifiedquiz from (
  select 
    response_id,
    user_id,
    passed,
    passed_on,
    stack,
    instance,
    record_date date as to_date(substring(metadata$filename, 34,10))
   from @nodesnapshots_raw/)
   pattern='.*snapshot_date=.*/.*'
;


create table IF NOT EXISTS certifiedquizquestion (
    response_id NUMBER,
    question_index NUMBER,
    is_correct BOOLEAN,
    stack STRING,
    instance STRING,
    record_date DATE
);

create table filedownload (
    timestamp TIMESTAMP,
    user_id NUMBER,
    project_id NUMBER,
    file_handle_id NUMBER,
    downloaded_file_handle_id NUMBER,
    association_object_id NUMBER,
    association_object_type STRING,
    stack STRING,
    instance STRING,
    record_date DATE
);

create table IF NOT EXISTS aclsnapshots (
  change_timestamp TIMESTAMP,
  change_type STRING,
  snapshot_timestamp TIMESTAMP,
  owner_id NUMBER,
  owner_type STRING,
  created_on TIMESTAMP,
  resource_access STRING,
  snapshot_date DATE
);

create table IF NOT EXISTS team_snapshots (
  change_timestamp TIMESTAMP,
  snapshot_timestamp TIMESTAMP,
  id NUMBER,
  name STRING,
  can_public_join BOOLEAN,
  created_on TIMESTAMP,
  created_by NUMBER,
  modified_on TIMESTAMP,
  modified_by NUMBER,
  snapshot_date DATE
);

create TABLE IF NOT EXISTS usergroupsnapshots (
	CHANGE_TIMESTAMP TIMESTAMP,
	SNAPSHOT_TIMESTAMP TIMESTAMP,
	ID NUMBER,
	IS_INDIVIDUAL BOOLEAN,
	CREATED_ON TIMESTAMP,
	SNAPSHOT_DATE DATE
);

create TABLE NODESNAPSHOTS (
	change_type STRING,
	change_timestamp TIMESTAMP,
	change_user_id NUMBER,
	snapshot_timestamp TIMESTAMP,
	id NUMBER,
	benefactor_id NUMBER,
	project_id NUMBER,
	parent_id NUMBER,
	node_type STRING,
	created_on TIMESTAMP,
	created_by NUMBER,
	modified_on TIMESTAMP,
	modified_by NUMBER,
	version_number NUMBER,
	file_handle_id NUMBER,
	name STRING,
	is_public BOOLEAN,
	is_controlled BOOLEAN,
	is_restricted BOOLEAN,
	snapshot_date DATE
);

LIST @nodesnapshots_raw;

copy into NODESNAPSHOTS from (
  select 
     $1:change_type as change_type,
     $1:change_timestamp as change_timestamp,
     $1:change_user_id as change_user_id,
     $1:snapshot_timestamp as snapshot_timestamp,
     $1:id as id,
     $1:benefactor_id as benefactor_id,
     $1:project_id as project_id,
     $1:parent_id as parent_id,
     $1:node_type as node_type,
     $1:created_on as created_on,
     $1:created_by as created_by,
     $1:modified_on as modified_on,
     $1:modified_by as modified_by,
     $1:version_number as version_number,
     $1:file_handle_id as file_handle_id,
     $1:name as name,
     $1:is_public as is_public,
     $1:is_controlled as is_controlled,
     $1:is_restricted as is_restricted,
     NULLIF(
       regexp_replace (
       METADATA$FILENAME,
       '^snapshot_date\=(.*)\/.*',
       '\\1'), 
       '__HIVE_DEFAULT_PARTITION__'
     )                         as snapshot_date
   from @nodesnapshots_raw/)
   pattern='.*snapshot_date=.*/.*'
;


// This is to add a new column
// alter table verificationsubmissionsnapshots_raw
// add snapshot_date DATE;

// Create verification submission snapshots table
create TABLE verificationsubmissionsnapshots (
	snapshot_timestamp TIMESTAMP,
	created_on TIMESTAMP,
	created_by NUMBER,
  state_history STRING,
  change_timestamp TIMESTAMP,
  change_type STRING,
  id NUMBER,
	snapshot_date DATE
);

CREATE STAGE verificationsubmissionsnapshots
  file_format = (TYPE = PARQUET COMPRESSION = AUTO);

// This was the original way i did it, but..
// There is a simplier way
-- copy into VERIFICATIONSUBMISSIONSNAPSHOTS_RAW
--  from (select $1:snapshot_timestamp::TIMESTAMP,
--               $1:created_on::TIMESTAMP,
--               $1:created_by::NUMBER,
--               $1:state_history::STRING,
--               $1:change_timestamp::TIMESTAMP,
--               $1:change_type::STRING,
--               $1:id::NUMBER,
--               '2023-09-01'
--       from @verificationsubmissionsnapshots_raw/snapshot_date=2023-09-01/)
-- FILE_FORMAT = (TYPE = PARQUET);

-- select * from verificationsubmissionsnapshots_raw;

LIST @verificationsubmissionsnapshots;

// Follow this blog https://www.snowflake.com/blog/how-to-load-terabytes-into-snowflake-speeds-feeds-and-techniques/#:~:text=Best%20Practices%20for%20Parquet%20and%20ORC
copy into verificationsubmissionsnapshots from (
  select 
     $1:snapshot_timestamp as snapshot_timestamp,
     $1:created_on as created_on,
     $1:created_by as created_by,
     $1:state_history as state_history,
     $1:change_timestamp as change_timestamp,
     $1:change_type as change_type,
     $1:id as id,
     NULLIF(
       regexp_replace (
       METADATA$FILENAME,
       '.*\=(.*)\/.*',
       '\\1'), 
       '__HIVE_DEFAULT_PARTITION__'
     )                         as snapshot_date
   from @verificationsubmissionsnapshots/)
   pattern='.*/snapshot_date=.*/.*'
;

// Create teammember snapshot
// These are internal stages, that need to be dropped
// Will need to convert these to external stages for scheduled copying
CREATE STAGE IF NOT EXISTS teammembersnapshots
  file_format = (TYPE = PARQUET COMPRESSION = AUTO);
CREATE TABLE IF NOT EXISTS teammembersnapshots (
	snapshot_timestamp TIMESTAMP,
  change_timestamp TIMESTAMP,
  team_id NUMBER,
  member_id NUMBER,
  is_admin BOOLEAN,
	snapshot_date DATE
);

// Follow this blog https://www.snowflake.com/blog/how-to-load-terabytes-into-snowflake-speeds-feeds-and-techniques/#:~:text=Best%20Practices%20for%20Parquet%20and%20ORC
copy into teammembersnapshots from (
  select 
     $1:snapshot_timestamp as snapshot_timestamp,
     $1:change_timestamp as change_timestamp,
     $1:team_id as team_id,
     $1:member_id as member_id,
     $1:is_admin as is_admin,
     NULLIF(
       regexp_replace (
       METADATA$FILENAME,
       '.*\=(.*)\/.*',
       '\\1'), 
       '__HIVE_DEFAULT_PARTITION__'
     )                         as snapshot_date
   from @teammembersnapshots/)
   pattern='.*snapshot_date=.*/.*'
;

DROP STAGE teammembersnapshots;
// file upload records
CREATE STAGE IF NOT EXISTS fileupload
  file_format = (TYPE = PARQUET COMPRESSION = AUTO);
CREATE TABLE IF NOT EXISTS fileupload (
	timestamp TIMESTAMP,
  user_id NUMBER,
  project_id NUMBER,
  file_handle_id NUMBER,
  association_object_id NUMBER,
  association_object_type STRING,
  stack STRING,
  instance STRING,
	record_date DATE
);
// Follow this blog https://www.snowflake.com/blog/how-to-load-terabytes-into-snowflake-speeds-feeds-and-techniques/#:~:text=Best%20Practices%20for%20Parquet%20and%20ORC
copy into fileupload from (
  select 
     $1:timestamp as timestamp,
     $1:user_id as user_id,
     $1:project_id as project_id,
     $1:file_handle_id as file_handle_id,
     $1:association_object_id as association_object_id,
     $1:association_object_type as association_object_type,
     $1:stack as stack,
     $1:instance as instance,
     NULLIF(
       regexp_replace (
       METADATA$FILENAME,
       '.*\=(.*)\/.*',
       '\\1'), 
       '__HIVE_DEFAULT_PARTITION__'
     )                         as record_date
   from @fileupload/)
   pattern='.*record_date=.*/.*'
;
DROP STAGE fileupload;
//file snapshots
CREATE STAGE IF NOT EXISTS filesnapshots
  file_format = (TYPE = PARQUET COMPRESSION = AUTO);
CREATE TABLE IF NOT EXISTS filesnapshots (
	change_type STRING,
  change_timestamp TIMESTAMP,
  change_user_id NUMBER,
  snapshot_timestamp TIMESTAMP,
  id NUMBER,
  created_by NUMBER,
  created_on TIMESTAMP,
  modified_on TIMESTAMP,
	concrete_type STRING,
  content_md5 STRING,
  content_type STRING,
  file_name STRING,
  storage_location_id NUMBER,
  content_size NUMBER,
  bucket STRING,
  key STRING,
  preview_id NUMBER,
  is_preview BOOLEAN,
  status STRING,
  snapshot_date DATE
);
// Follow this blog https://www.snowflake.com/blog/how-to-load-terabytes-into-snowflake-speeds-feeds-and-techniques/#:~:text=Best%20Practices%20for%20Parquet%20and%20ORC
copy into filesnapshots from (
  select 
     $1:change_type as change_type,
     $1:change_timestamp as change_timestamp,
     $1:change_user_id as change_user_id,
     $1:snapshot_timestamp as snapshot_timestamp,
     $1:id as id,
     $1:created_by as created_by,
     $1:created_on as created_on,
     $1:modified_on as modified_on,
     $1:concrete_type as concrete_type,
     $1:content_md5 as content_md5,
     $1:content_type as content_type,
     $1:file_name as file_name,
     $1:storage_location_id as storage_location_id,
     $1:content_size as content_size,
     $1:bucket as bucket,
     $1:key as key,
     $1:preview_id as preview_id,
     $1:is_preview as is_preview,
     $1:status as status,
     NULLIF(
       regexp_replace (
       METADATA$FILENAME,
       '.*\=(.*)\/.*',
       '\\1'), 
       '__HIVE_DEFAULT_PARTITION__'
     )                         as snapshot_date
   from @filesnapshots/)
   pattern='.*snapshot_date=.*/.*'
;

// processed access records
CREATE STAGE IF NOT EXISTS processedaccess
  file_format = (TYPE = PARQUET COMPRESSION = AUTO);

CREATE TABLE IF NOT EXISTS processedaccess (
	session_id STRING,
    timestamp TIMESTAMP,
    user_id NUMBER,
    method STRING,
    request_url STRING,
    user_agent STRING,
    host STRING,
    origin STRING,
	  x_forwarded_for STRING,
    via STRING,
    thread_id NUMBER,
    elapse_ms NUMBER,
    success BOOLEAN,
    stack STRING,
    instance STRING,
    vm_id STRING,
    return_object_id STRING,
    query_string STRING,
    response_status NUMBER,
    oauth_client_id STRING,
    basic_auth_username STRING,
    auth_method STRING,
    normalized_method_signature STRING,
    client STRING,
    client_version STRING,
    entity_id NUMBER,
    record_date DATE
);

// Follow this blog https://www.snowflake.com/blog/how-to-load-terabytes-into-snowflake-speeds-feeds-and-techniques/#:~:text=Best%20Practices%20for%20Parquet%20and%20ORC
copy into processedaccess from (
  select 
     $1:session_id as session_id,
     $1:timestamp as timestamp,
     $1:user_id as user_id,
     $1:method as method,
     $1:request_url as request_url,
     $1:user_agent as user_agent,
     $1:host as host,
     $1:origin as origin,
     $1:x_forwarded_for as x_forwarded_for,
     $1:via as via,
     $1:thread_id as thread_id,
     $1:elapse_ms as elapse_ms,
     $1:success as success,
     $1:stack as stack,
     $1:instance as instance,
     $1:vm_id as vm_id,
     $1:return_object_id as return_object_id,
     $1:query_string as query_string,
     $1:response_status as response_status,
     $1:oauth_client_id as oauth_client_id,
     $1:basic_auth_username as basic_auth_username,
     $1:auth_method as auth_method,
     $1:normalized_method_signature as normalized_method_signature,
     $1:client as client,
     $1:client_version as client_version,
     $1:entity_id as entity_id,
     NULLIF(
       regexp_replace (
       METADATA$FILENAME,
       '.*\=(.*)\/.*',
       '\\1'), 
       '__HIVE_DEFAULT_PARTITION__'
     )                         as record_date
   from @processedaccess/)
   pattern='.*record_date=.*/.*'
;

CREATE TABLE IF NOT EXISTS synapse_data_warehouse.synapse.certified_question_information (
    question_index NUMBER,
    question_group_number NUMBER,
    version STRING,
    fre_q FLOAT,
    fre_help FLOAT,
    difference_fre FLOAT,
    fkgl_q NUMBER,
    fkgl_help FLOAT,
    difference_fkgl FLOAT,
    notes STRING,
    type STRING,
    question_text STRING
);
// Loaded the table manually...

// Create certified quiz question latest
CREATE TABLE IF NOT EXISTS synapse_data_warehouse.synapse.certifiedquizquestion_latest AS
    select distinct * from synapse_data_warehouse.synapse_raw.certifiedquizquestion
    where INSTANCE =
    (select max(INSTANCE) from synapse_data_warehouse.synapse_raw.certifiedquizquestion);

// Create certified quiz latest
CREATE TABLE IF NOT EXISTS synapse_data_warehouse.synapse.certifiedquiz_latest AS
    select distinct * from synapse_data_warehouse.synapse_raw.certifiedquiz
    where INSTANCE =
    (select max(INSTANCE) from synapse_data_warehouse.synapse_raw.certifiedquiz);


// Create View of user profile and cert join
CREATE VIEW IF NOT EXISTS synapse_data_warehouse.synapse.user_certified AS
  with user_cert_joined as (
    select *
    from synapse_data_warehouse.synapse.userprofile_latest user
    LEFT JOIN (
      select USER_ID, PASSED from synapse_data_warehouse.synapse.certifiedquiz_latest
    ) cert
    ON user.ID = cert.USER_ID
  )
  select ID, USER_NAME, FIRST_NAME, LAST_NAME, EMAIL, LOCATION, COMPANY, POSITION, PASSED
  from user_cert_joined
;

