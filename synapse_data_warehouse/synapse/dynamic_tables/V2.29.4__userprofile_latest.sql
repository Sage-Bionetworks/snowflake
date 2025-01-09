-- Introduce the dynamic table
USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP
CREATE OR REPLACE DYNAMIC TABLE USERPROFILE_LATEST
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    AS 
    WITH dedup_userprofile AS (
        SELECT
            *
        FROM {{database_name}}.SYNAPSE_RAW.USERPROFILESNAPSHOT --noqa: TMP
        WHERE
            SNAPSHOT_DATE >= CURRENT_TIMESTAMP - INTERVAL '14 days'
        QUALIFY
            ROW_NUMBER() OVER (
                PARTITION BY ID
                ORDER BY CHANGE_TIMESTAMP DESC, SNAPSHOT_TIMESTAMP DESC
            ) = 1
    )
    SELECT 
        * exclude (LOCATION, COMPANY, POSITION, INDUSTRY), 
        NULLIF(LOCATION, '') AS LOCATION, 
        NULLIF(COMPANY, '') AS COMPANY, 
        NULLIF(POSITION, '') AS POSITION, 
        NULLIF(INDUSTRY, '') AS INDUSTRY, 
    FROM 
     dedup_userprofile;