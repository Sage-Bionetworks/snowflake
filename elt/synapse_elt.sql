use role accountadmin;
USE DATABASE SYNAPSE_DATA_WAREHOUSE;
USE SCHEMA SYNAPSE_RAW;

CREATE OR REPLACE TASK refresh_synapse_prod_stage_task
    SCHEDULE = 'USING CRON 0 23 * * * America/Los_Angeles'
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
ALTER STAGE IF EXISTS SYNAPSE_PROD_WAREHOUSE_S3_STAGE REFRESH;
ALTER TASK refresh_synapse_stage_task RESUME;

CREATE OR REPLACE TASK userprofilesnapshot_task
    SCHEDULE = 'USING CRON 0 0 * * * America/Los_Angeles'
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
copy into
  userprofilesnapshot
from (
  select
    $1:change_type as change_type,
    $1:change_timestamp as change_timestamp,
    $1:change_user_id as change_user_id,
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
          '.*userprofilesnapshots\/snapshot_date\=(.*)\/.*', '\\1'
        ),
        '__HIVE_DEFAULT_PARTITION__'
      ) as snapshot_date
  from
    @synapse_prod_warehouse_s3_stage/userprofilesnapshots
  )
pattern='.*userprofilesnapshots/snapshot_date=.*/.*';

ALTER TASK userprofilesnapshot_task RESUME;

CREATE OR REPLACE TASK nodesnapshot_task
    SCHEDULE = 'USING CRON 0 0 * * * America/Los_Angeles'
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
copy into
  NODESNAPSHOTS
from (
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
      '.*nodesnapshots\/snapshot_date\=(.*)\/.*',
      '\\1'),
      '__HIVE_DEFAULT_PARTITION__'
    )                         as snapshot_date
  from @synapse_prod_warehouse_s3_stage/nodesnapshots/)
pattern='.*nodesnapshots/snapshot_date=.*/.*'
;

ALTER TASK nodesnapshot_task RESUME;

CREATE OR REPLACE TASK certifiedquiz_task
    SCHEDULE = 'USING CRON 0 0 * * * America/Los_Angeles'
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
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
       '.*certifiedquizrecords\/record_date\=(.*)\/.*',
       '\\1'),
       '__HIVE_DEFAULT_PARTITION__'
     )                         as record_date
  from
    @synapse_prod_warehouse_s3_stage/certifiedquizrecords
  )
pattern='.*certifiedquizrecords/record_date=.*/.*'
;
ALTER TASK certifiedquiz_task RESUME;

CREATE OR REPLACE TASK certifiedquizquestion_task
    SCHEDULE = 'USING CRON 0 0 * * * America/Los_Angeles'
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
copy into
  certifiedquizquestion
from (
  select
     $1:response_id as response_id,
     $1:question_index as question_index,
     $1:is_correct as is_correct,
     $1:stack as stack,
     $1:instance as instance,
     NULLIF(
       regexp_replace (
       METADATA$FILENAME,
       '.*certifiedquizquestionrecords\/record_date\=(.*)\/.*',
       '\\1'),
       '__HIVE_DEFAULT_PARTITION__'
     )                         as record_date
  from
    @synapse_prod_warehouse_s3_stage/certifiedquizquestionrecords
  )
pattern='.*certifiedquizquestionrecords/record_date=.*/.*'
;
ALTER TASK certifiedquizquestion_task RESUME;

CREATE OR REPLACE TASK filedownload_task
    SCHEDULE = 'USING CRON 0 0 * * * America/Los_Angeles'
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
copy into
  filedownload
from (
  select
     $1:timestamp as timestamp,
     $1:user_id as user_id,
     $1:project_id as project_id,
     $1:file_handle_id as file_handle_id,
     $1:downloaded_file_handle_id as downloaded_file_handle_id,
     $1:association_object_id as association_object_id,
     $1:association_object_type as association_object_type,
     $1:stack as stack,
     $1:instance as instance,
     NULLIF(
       regexp_replace (
       METADATA$FILENAME,
       '.*filedownloadrecords\/record_date\=(.*)\/.*',
       '\\1'),
       '__HIVE_DEFAULT_PARTITION__'
     )                         as record_date
  from
    @synapse_prod_warehouse_s3_stage/filedownloadrecords
  )
pattern='.*filedownloadrecords/record_date=.*/.*'
;
ALTER TASK filedownload_task RESUME;

CREATE OR REPLACE TASK aclsnapshots_task
    SCHEDULE = 'USING CRON 0 0 * * * America/Los_Angeles'
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
copy into
  aclsnapshots
from (
  select
    $1:change_timestamp as change_timestamp,
    $1:change_type as change_type,
    $1:snapshot_timestamp as snapshot_timestamp,
    $1:owner_id as owner_id,
    $1:owner_type as owner_type,
    $1:created_on as created_on,
    $1:resource_access as resource_access,
    NULLIF(
       regexp_replace (
       METADATA$FILENAME,
       '.*aclsnapshots\/snapshot_date\=(.*)\/.*',
       '\\1'),
       '__HIVE_DEFAULT_PARTITION__'
    )                         as snapshot_date
  from
    @synapse_prod_warehouse_s3_stage/aclsnapshots
  )
pattern='.*aclsnapshots/snapshot_date=.*/.*'
;
ALTER TASK aclsnapshots_task RESUME;

CREATE OR REPLACE TASK teamsnapshots_task
    SCHEDULE = 'USING CRON 0 0 * * * America/Los_Angeles'
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
copy into
  teamsnapshots
from (
  select
    $1:change_type as change_type,
    $1:change_timestamp as change_timestamp,
    $1:change_user_id as change_user_id,
    $1:snapshot_timestamp as snapshot_timestamp,
    $1:id as id,
    $1:name as name,
    $1:can_public_join as can_public_join,
    $1:created_on as created_on,
    $1:created_by as created_by,
    $1:modified_on as modified_on,
    $1:modified_by as modified_by,
    NULLIF(
       regexp_replace (
       METADATA$FILENAME,
       '.*teamsnapshots\/snapshot_date\=(.*)\/.*',
       '\\1'),
       '__HIVE_DEFAULT_PARTITION__'
    )                         as snapshot_date
  from
    @synapse_prod_warehouse_s3_stage/teamsnapshots
  )
pattern='.*teamsnapshots/snapshot_date=.*/.*'
;
ALTER TASK teamsnapshots_task RESUME;

CREATE OR REPLACE TASK usergroupsnapshots_task
    SCHEDULE = 'USING CRON 0 0 * * * America/Los_Angeles'
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
copy into
  usergroupsnapshots
from (
  select
    $1:change_type as change_type,
    $1:change_timestamp as change_timestamp,
    $1:change_user_id as change_user_id,
    $1:snapshot_timestamp as snapshot_timestamp,
    $1:id as id,
    $1:is_individual as is_individual,
    $1:created_on as created_on,
    NULLIF(
       regexp_replace (
       METADATA$FILENAME,
       '.*usergroupsnapshots\/snapshot_date\=(.*)\/.*',
       '\\1'),
       '__HIVE_DEFAULT_PARTITION__'
    )                         as snapshot_date
  from
    @synapse_prod_warehouse_s3_stage/usergroupsnapshots
  )
pattern='.*usergroupsnapshots/snapshot_date=.*/.*'
;
ALTER TASK usergroupsnapshots_task RESUME;

-- ! Task tracking
SHOW tasks;

select *
from table(information_schema.task_history())
order by scheduled_time;

// Get results from a query id
SELECT *
FROM TABLE(RESULT_SCAN('01af2764-0001-5c4a-0004-7c7a0006d10a'))
LIMIT 10;
