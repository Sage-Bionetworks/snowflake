USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
USE WAREHOUSE COMPUTE_MEDIUM;
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
    @{{stage_storage_integration}}_stage/aclsnapshots --noqa: TMP
  )
pattern='.*aclsnapshots/snapshot_date=.*/.*'
;

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
    @{{stage_storage_integration}}_stage/teamsnapshots --noqa: TMP
  )
pattern='.*teamsnapshots/snapshot_date=.*/.*'
;

copy into
    teammembersnapshots
from (
  select
    $1:change_type as change_type,
    $1:change_timestamp as change_timestamp,
    $1:change_user_id as change_user_id,
    $1:snapshot_timestamp as snapshot_timestamp,
    $1:team_id as team_id,
    $1:member_id as member_id,
    $1:is_admin as is_admin,
    NULLIF(
      regexp_replace (
      METADATA$FILENAME,
      '.*teammembersnapshots\/snapshot_date\=(.*)\/.*',
      '\\1'),
      '__HIVE_DEFAULT_PARTITION__'
    )                         as snapshot_date
  from
    @{{stage_storage_integration}}_stage/teammembersnapshots --noqa: TMP
  )
pattern='.*teammembersnapshots/snapshot_date=.*/.*'
;
