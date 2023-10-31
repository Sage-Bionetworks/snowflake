USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
USE WAREHOUSE COMPUTE_MEDIUM;
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
    @{{stage_storage_integration}}_stage/filedownloadrecords --noqa: TMP
  )
pattern='.*filedownloadrecords/record_date=.*/.*'
;

copy into
  fileupload
from (
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
      '.*fileuploadrecords\/record_date\=(.*)\/.*',
      '\\1'),
      '__HIVE_DEFAULT_PARTITION__'
    )                         as record_date
  from
    @{{stage_storage_integration}}_stage/fileuploadrecords --noqa: TMP
  )
pattern='.*fileuploadrecords/record_date=.*/.*'
;
