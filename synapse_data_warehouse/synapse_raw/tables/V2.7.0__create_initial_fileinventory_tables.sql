USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
USE WAREHOUSE COMPUTE_MEDIUM;
-- Create new tables
CREATE TABLE IF NOT EXISTS fileinventory (
    bucket STRING,
    e_tag STRING,
    encryption_status STRING,
    intelligent_tiering_access_tier STRING,
    is_delete_marker BOOLEAN,
    is_latest BOOLEAN,
    is_multipart_uploaded BOOLEAN,
    key STRING,
    last_modified_date TIMESTAMP,
    object_owner STRING,
    size NUMBER,
    storage_class STRING
);

-- initial load of data

copy into
  fileinventory
from (
  select
    $1:bucket as bucket,
    $1:e_tag as e_tag,
    $1:encryption_status as encryption_status,
    $1:intelligent_tiering_access_tier as intelligent_tiering_access_tier,
    $1:is_delete_marker as is_delete_marker,
    $1:is_latest as is_latest,
    $1:is_multipart_uploaded as is_multipart_uploaded,
    $1:key as key,
    $1:last_modified_date as last_modified_date,
    $1:object_owner as object_owner,
    $1:size as size,
    $1:storage_class as storage_class
  from
    @{{stage_storage_integration}}_stage/inventory --noqa: TMP
  )
pattern='.*defaultInventory/data/.*'
;
