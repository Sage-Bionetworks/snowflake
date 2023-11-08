use role accountadmin;
use schema {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
alter task refresh_synapse_warehouse_s3_stage_task suspend;
alter task userprofilesnapshot_task suspend;
alter task upsert_to_userprofile_latest_task suspend;
alter task userprofilesnapshot_task MODIFY AS
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
            REGEXP_REPLACE($1:email, '.+\@', '*****@') as email,
            $1:location as location,
            $1:company as company,
            $1:position as position,
            NULLIF(
                REGEXP_REPLACE(
                    metadata$filename,
                    '.*userprofilesnapshots\/snapshot_date\=(.*)\/.*', '\\1'
                ),
                '__HIVE_DEFAULT_PARTITION__'
            ) as snapshot_date,
            $1:created_on as created_on
        from
            @{{stage_storage_integration}}_stage/userprofilesnapshots --noqa: TMP
    )
    pattern = '.*userprofilesnapshots/snapshot_date=.*/.*';

alter task upsert_to_userprofile_latest_task modify as
    MERGE INTO {{database_name}}.SYNAPSE.USERPROFILE_LATEST AS TARGET_TABLE --noqa: TMP
    USING (
        WITH RANKED_NODES AS (
            SELECT
                *,
                "row_number"()
                    OVER (
                        PARTITION BY ID
                        ORDER BY CHANGE_TIMESTAMP DESC, SNAPSHOT_TIMESTAMP DESC
                    )
                    AS N
            FROM
                USERPROFILESNAPSHOT_STREAM
        )

        SELECT * EXCLUDE N
        FROM RANKED_NODES
        WHERE N = 1
    ) AS SOURCE_TABLE ON TARGET_TABLE.ID = SOURCE_TABLE.ID
    WHEN MATCHED THEN
        UPDATE SET
            TARGET_TABLE.CHANGE_TYPE = SOURCE_TABLE.CHANGE_TYPE,
            TARGET_TABLE.CHANGE_TIMESTAMP = SOURCE_TABLE.CHANGE_TIMESTAMP,
            TARGET_TABLE.CHANGE_USER_ID = SOURCE_TABLE.CHANGE_USER_ID,
            TARGET_TABLE.SNAPSHOT_TIMESTAMP = SOURCE_TABLE.SNAPSHOT_TIMESTAMP,
            TARGET_TABLE.ID = SOURCE_TABLE.ID,
            TARGET_TABLE.USER_NAME = SOURCE_TABLE.USER_NAME,
            TARGET_TABLE.FIRST_NAME = SOURCE_TABLE.FIRST_NAME,
            TARGET_TABLE.LAST_NAME = SOURCE_TABLE.LAST_NAME,
            TARGET_TABLE.EMAIL = SOURCE_TABLE.EMAIL,
            TARGET_TABLE.LOCATION = SOURCE_TABLE.LOCATION,
            TARGET_TABLE.COMPANY = SOURCE_TABLE.COMPANY,
            TARGET_TABLE.POSITION = SOURCE_TABLE.POSITION,
            TARGET_TABLE.SNAPSHOT_DATE = SOURCE_TABLE.SNAPSHOT_DATE,
            TARGET_TABLE.CREATED_ON = SOURCE_TABLE.CREATED_ON
    WHEN NOT MATCHED THEN
        INSERT (CHANGE_TYPE, CHANGE_TIMESTAMP, CHANGE_USER_ID, SNAPSHOT_TIMESTAMP, ID, USER_NAME, FIRST_NAME, LAST_NAME, EMAIL, LOCATION, COMPANY, POSITION, SNAPSHOT_DATE, CREATED_ON)
        VALUES (SOURCE_TABLE.CHANGE_TYPE, SOURCE_TABLE.CHANGE_TIMESTAMP, SOURCE_TABLE.CHANGE_USER_ID, SOURCE_TABLE.SNAPSHOT_TIMESTAMP, SOURCE_TABLE.ID, SOURCE_TABLE.USER_NAME, SOURCE_TABLE.FIRST_NAME, SOURCE_TABLE.LAST_NAME, SOURCE_TABLE.EMAIL, SOURCE_TABLE.LOCATION, SOURCE_TABLE.COMPANY, SOURCE_TABLE.POSITION, SOURCE_TABLE.SNAPSHOT_DATE, SOURCE_TABLE.CREATED_ON);

alter task upsert_to_userprofile_latest_task resume;
alter task userprofilesnapshot_task resume;
alter task refresh_synapse_warehouse_s3_stage_task resume;
