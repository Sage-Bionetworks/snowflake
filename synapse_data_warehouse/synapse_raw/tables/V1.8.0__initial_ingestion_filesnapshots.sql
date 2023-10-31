USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
USE WAREHOUSE COMPUTE_MEDIUM;

copy into
    filesnapshots
from (
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
    MD5($1:file_name) as file_name,
    $1:storage_location_id as storage_location_id,
    $1:content_size as content_size,
    $1:bucket as bucket,
    REGEXP_REPLACE($1:key, '^(.*)/(.*)/.*', '\\1/\\2') as key,
    $1:preview_id as preview_id,
    $1:is_preview as is_preview,
    $1:status as status,
    NULLIF(
       regexp_replace (
       metadata$filename,
       '.*filesnapshots\/snapshot_date\=(.*)\/.*',
       '\\1'),
       '__HIVE_DEFAULT_PARTITION__'
    ) as snapshot_date
  from
    @{{stage_storage_integration}}_stage/filesnapshots --noqa: TMP
  )
pattern='.*filesnapshots/snapshot_date=.*/.*'
;
