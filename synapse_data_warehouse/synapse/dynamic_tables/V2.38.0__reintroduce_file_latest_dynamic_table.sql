-- Introduce the dynamic table
USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP
CREATE OR REPLACE DYNAMIC TABLE FILE_LATEST
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    AS 
    WITH dedup_filesnapshots AS (
        SELECT
            *
        FROM {{database_name}}.SYNAPSE_RAW.FILESNAPSHOTS --noqa: TMP
        WHERE
            SNAPSHOT_DATE >= CURRENT_TIMESTAMP - INTERVAL '30 days' AND NOT IS_PREVIEW
        QUALIFY
            ROW_NUMBER() OVER (
                PARTITION BY ID
                ORDER BY CHANGE_TIMESTAMP DESC, SNAPSHOT_TIMESTAMP DESC
            ) = 1
    )
    SELECT 
        CHANGE_TYPE,
        CHANGE_TIMESTAMP,
        CHANGE_USER_ID,
        SNAPSHOT_TIMESTAMP,
        ID,
        CREATED_BY,
        CREATED_ON,
        MODIFIED_ON,
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
        SNAPSHOT_DATE
    FROM 
        dedup_filesnapshots
    WHERE
        CHANGE_TYPE != 'DELETE';
