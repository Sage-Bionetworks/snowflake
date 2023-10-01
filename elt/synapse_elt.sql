use role accountadmin;

CREATE OR REPLACE TASK refresh_synapse_stage_task
    SCHEDULE = 'USING CRON 0 23 * * * America/Los_Angeles'
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
ALTER STAGE IF EXISTS my_test_s3_stage REFRESH;
ALTER TASK refresh_synapse_stage_task RESUME;

CREATE OR REPLACE TASK userprofilesnapshot_task
    SCHEDULE = 'USING CRON 0 0 * * * America/Los_Angeles'
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
AS
COPY INTO userprofilesnapshot FROM (
    SELECT 
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
    FROM
        @my_test_s3_stage/userprofilesnapshots
)
PATTERN = '.*userprofilesnapshots/snapshot_date=.*/.*';
ALTER TASK userprofilesnapshot_task RESUME;

// zero copy clone of processed access records
CREATE OR REPLACE TABLE synapse_data_warehouse.synapse.processedaccess
CLONE synapse_data_warehouse.synapse_raw.processedaccess;

select count(*) from userprofilesnapshot;
//1883590

// 7975867
SHOW tasks;

select *
from table(information_schema.task_history())
order by scheduled_time;

// Get results from a query id
SELECT *
FROM TABLE(RESULT_SCAN('01af2764-0001-5c4a-0004-7c7a0006d10a'))
LIMIT 10;
