USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
USE WAREHOUSE COMPUTE_MEDIUM;
copy into verificationsubmissionsnapshots from (
  select
    $1:change_timestamp as change_timestamp,
    $1:change_type as change_type,
    $1:snapshot_timestamp as snapshot_timestamp,
    $1:id as id,
    $1:created_on as created_on,
    $1:created_by as created_by,
    $1:state_history as state_history,
    NULLIF(
      regexp_replace (
      METADATA$FILENAME,
      '.*verificationsubmissionsnapshots\/snapshot_date\=(.*)\/.*',
      '\\1'),
      '__HIVE_DEFAULT_PARTITION__'
    )                         as snapshot_date
  from
    @{{stage_storage_integration}}_stage/verificationsubmissionsnapshots --noqa: TMP
  )
pattern='.*verificationsubmissionsnapshots/snapshot_date=.*/.*'
;

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
    @{{stage_storage_integration}}_stage/usergroupsnapshots --noqa: TMP
  )
pattern='.*usergroupsnapshots/snapshot_date=.*/.*'
;
