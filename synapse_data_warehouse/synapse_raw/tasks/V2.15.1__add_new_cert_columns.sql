USE ROLE accountadmin;
use schema {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP,CP01
ALTER TASK refresh_synapse_warehouse_s3_stage_task SUSPEND;
ALTER TASK APPEND_TO_CERTIFIEDQUIZSNAPSHOT_TASK SUSPEND;
ALTER TASK UPSERT_TO_CERTIFIEDQUIZ_LATEST_TASK SUSPEND;

alter task APPEND_TO_CERTIFIEDQUIZSNAPSHOT_TASK MODIFY AS
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
            ) as snapshot_date,
            $1:revoked as revoked,
            $1:revoked_on as revoked_on,
            $1:certified as certified
        from
            @synapse_prod_warehouse_s3_stage/certifiedquizsnapshots --noqa: TMP
        )
    pattern='.*certifiedquizsnapshots/snapshot_date=.*/.*';

alter task UPSERT_TO_CERTIFIEDQUIZ_LATEST_TASK MODIFY AS
	MERGE INTO SYNAPSE_DATA_WAREHOUSE.SYNAPSE.CERTIFIEDQUIZ_LATEST AS TARGET_TABLE --noqa: TMP
    USING (
        WITH CQQ_RANKED AS (
            SELECT
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY USER_ID
                    ORDER BY INSTANCE DESC, RESPONSE_ID DESC
                ) AS ROW_NUM
            FROM CERTIFIEDQUIZ_STREAM
        )

        SELECT * EXCLUDE ROW_NUM
        FROM CQQ_RANKED
        WHERE ROW_NUM = 1
    ) AS SOURCE_TABLE ON TARGET_TABLE.USER_ID = SOURCE_TABLE.USER_ID
    WHEN MATCHED THEN
        UPDATE SET
            TARGET_TABLE.CHANGE_TYPE = SOURCE_TABLE.CHANGE_TYPE,
            TARGET_TABLE.CHANGE_TIMESTAMP = SOURCE_TABLE.CHANGE_TIMESTAMP,
            TARGET_TABLE.SNAPSHOT_TIMESTAMP = SOURCE_TABLE.SNAPSHOT_TIMESTAMP,
            TARGET_TABLE.RESPONSE_ID = SOURCE_TABLE.RESPONSE_ID,
            TARGET_TABLE.PASSED = SOURCE_TABLE.PASSED,
            TARGET_TABLE.PASSED_ON = SOURCE_TABLE.PASSED_ON,
            TARGET_TABLE.STACK = SOURCE_TABLE.STACK,
            TARGET_TABLE.INSTANCE = SOURCE_TABLE.INSTANCE,
            TARGET_TABLE.SNAPSHOT_DATE = SOURCE_TABLE.SNAPSHOT_DATE
            TARGET_TABLE.REVOKED = SOURCE_TABLE.REVOKED,
            TARGET_TABLE.REVOKED_ON = SOURCE_TABLE.REVOKED_ON,
            TARGET_TABLE.CERTIFIED = SOURCE_TABLE.CERTIFIED
    WHEN NOT MATCHED THEN
        INSERT (
            CHANGE_TYPE,
            CHANGE_TIMESTAMP,
            SNAPSHOT_TIMESTAMP,
            RESPONSE_ID,
            USER_ID,
            PASSED,
            ASSED_ON,
            STACK,
            INSTANCE,
            SNAPSHOT_DATE,
            REVOKED,
            REVOKED_ON,
            CERTIFIED
        )
        VALUES (
            SOURCE_TABLE.CHANGE_TYPE,
            SOURCE_TABLE.CHANGE_TIMESTAMP,
            SOURCE_TABLE.SNAPSHOT_TIMESTAMP,
            SOURCE_TABLE.RESPONSE_ID,
            SOURCE_TABLE.USER_ID,
            SOURCE_TABLE.PASSED,
            SOURCE_TABLE.PASSED_ON,
            SOURCE_TABLE.STACK,
            SOURCE_TABLE.INSTANCE,
            SOURCE_TABLE.SNAPSHOT_DATE,
            SOURCE_TABLE.REVOKED,
            SOURCE_TABLE.REVOKED_ON,
            SOURCE_TABLE.CERTIFIED
        );

// https://docs.snowflake.com/en/sql-reference/functions/system_task_dependents_enable
SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('refresh_synapse_warehouse_s3_stage_task');
