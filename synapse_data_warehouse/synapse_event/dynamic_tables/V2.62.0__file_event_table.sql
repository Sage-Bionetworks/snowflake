USE SCHEMA {{database_name}}.synapse_event; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE DYNAMIC TABLE FILE_EVENT
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_medium
    AS 
    WITH dedup_filesnapshots AS (
        SELECT
            ID,
            CHANGE_TYPE,
            CHANGE_TIMESTAMP,
            MODIFIED_ON,
            CHANGE_USER_ID,
            CREATED_BY,
            CREATED_ON,
            CONCRETE_TYPE,
            CONTENT_MD5,
            CONTENT_TYPE,
            FILE_NAME,
            STORAGE_LOCATION_ID,
            CONTENT_SIZE,
            BUCKET,
            KEY,
            PREVIEW_ID,
            IS_PREVIEW,
            STATUS,
            SNAPSHOT_DATE,
            SNAPSHOT_TIMESTAMP,
        FROM {{database_name}}.SYNAPSE_RAW.FILESNAPSHOTS --noqa: TMP
        QUALIFY
            ROW_NUMBER() OVER (
                PARTITION BY ID, CHANGE_TYPE, MODIFIED_ON, CHANGE_TIMESTAMP
                ORDER BY SNAPSHOT_TIMESTAMP DESC
            ) = 1
    )
    SELECT 
        *
    FROM 
        dedup_filesnapshots;
