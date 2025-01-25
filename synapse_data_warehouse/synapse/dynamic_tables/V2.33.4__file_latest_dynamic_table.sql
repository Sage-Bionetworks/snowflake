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
            SNAPSHOT_DATE >= CURRENT_TIMESTAMP - INTERVAL '30 days'
        QUALIFY
            ROW_NUMBER() OVER (
                PARTITION BY ID
                ORDER BY CHANGE_TIMESTAMP DESC, SNAPSHOT_TIMESTAMP DESC
            ) = 1
    )
    SELECT 
        * 
    FROM 
        dedup_filesnapshots
    WHERE
        STATUS = 'AVAILABLE' OR NOT IS_PREVIEW;
