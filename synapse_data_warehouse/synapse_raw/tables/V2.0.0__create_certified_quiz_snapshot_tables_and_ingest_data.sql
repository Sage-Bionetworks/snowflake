USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
USE WAREHOUSE COMPUTE_MEDIUM;
-- Create new tables
CREATE TABLE IF NOT EXISTS certifiedquizsnapshots (
    change_type STRING,
    change_timestamp TIMESTAMP,
    snapshot_timestamp TIMESTAMP,
    response_id NUMBER,
    user_id NUMBER,
    passed BOOLEAN,
    passed_on TIMESTAMP,
    stack STRING,
    instance STRING,
    snapshot_date DATE
)
CLUSTER BY (snapshot_date);

CREATE TABLE IF NOT EXISTS certifiedquizquestionsnapshots (
    change_type STRING,
    change_timestamp TIMESTAMP,
    change_user_id NUMBER,
    snapshot_timestamp TIMESTAMP,
    response_id NUMBER,
    question_index NUMBER,
    is_correct BOOLEAN,
    stack STRING,
    instance STRING,
    snapshot_date DATE
)
CLUSTER BY (snapshot_date);

-- initial load of data

copy into
  certifiedquizsnapshots
from (
  select
    $1:change_type as change_type,
    $1:change_timestamp as change_timestamp,
    $1:snapshot_timestamp as snapshot_timestamp,
    $1:response_id as response_id,
    $1:user_id as user_id,
    $1:passed as passed,
    $1:passed_on as passed_on,
    $1:stack as stack,
    $1:instance as instance,
    NULLIF(
      regexp_replace(
      METADATA$FILENAME,
      '.*certifiedquizsnapshots\/snapshot_date\=(.*)\/.*',
      '\\1'),
      '__HIVE_DEFAULT_PARTITION__'
    ) as snapshot_date
  from
    @{{stage_storage_integration}}_stage/certifiedquizsnapshots --noqa: TMP
  )
pattern='.*certifiedquizsnapshots/snapshot_date=.*/.*'
;

copy into
  certifiedquizquestionsnapshots
from (
  select
    $1:change_type as change_type,
    $1:change_timestamp as change_timestamp,
    $1:change_user_id as change_user_id,
    $1:snapshot_timestamp as snapshot_timestamp,
    $1:response_id as response_id,
    $1:question_index as question_index,
    $1:is_correct as is_correct,
    $1:stack as stack,
    $1:instance as instance,
    NULLIF(
      regexp_replace(
      METADATA$FILENAME,
      '.*certifiedquizquestionsnapshots\/snapshot_date\=(.*)\/.*',
      '\\1'),
      '__HIVE_DEFAULT_PARTITION__'
    ) as snapshot_date
  from
    @{{stage_storage_integration}}_stage/certifiedquizquestionsnapshots --noqa: TMP
  )
pattern='.*certifiedquizquestionsnapshots/snapshot_date=.*/.*'
;
