USE ROLE SYSADMIN;
USE DATABASE SAGE;
USE SCHEMA PORTAL_DOWNLOADS;
-- Data up to October 18th for now

-- TODO: join file_latest to get the content size!
-- * Metrics for AD portal
-- Based on a writeup by platform linked from PLFM-7934
-- downloads can be estimated by taking the unique of the following:
-- user_id, file_handle_id, record_date
-- Join the AD fileview with the file download table on file_handle_id
CREATE OR REPLACE TABLE AD_DOWNLOADS AS (
    WITH DEDUP_FILEDOWNLOAD AS (
        SELECT DISTINCT
            USER_ID,
            FILE_HANDLE_ID AS FD_FILE_HANDLE_ID,
            RECORD_DATE
        FROM
            SYNAPSE_DATA_WAREHOUSE.SYNAPSE.FILEDOWNLOAD
    )

    SELECT
        AD.*,
        FD.*
    FROM
        SAGE.PORTAL_RAW.AD
    LEFT JOIN
        DEDUP_FILEDOWNLOAD AS FD
        ON
            AD.DATAFILEHANDLEID = FD.FD_FILE_HANDLE_ID
);

-- * GENIE
-- Join the GENIE fileview with the file download table on file_handle_id
CREATE OR REPLACE TABLE GENIE_DOWNLOADS AS (
    WITH DEDUP_FILEDOWNLOAD AS (
        SELECT DISTINCT
            USER_ID,
            FILE_HANDLE_ID AS FD_FILE_HANDLE_ID,
            RECORD_DATE
        FROM
            SYNAPSE_DATA_WAREHOUSE.SYNAPSE.FILEDOWNLOAD
    )

    SELECT
        GENIE.*,
        FD.*
    FROM
        SAGE.PORTAL_RAW.GENIE AS GENIE
    LEFT JOIN
        DEDUP_FILEDOWNLOAD AS FD
        ON
            GENIE.DATAFILEHANDLEID = FD.FD_FILE_HANDLE_ID
);

-- * ELITE
-- The elite fileview doesn't have a file handle id
-- so we need to update the synapse id column to be an integer withou the syn prefix
-- and join on the latest version of the node table then on the file handle
CREATE OR REPLACE TABLE ELITE_DOWNLOADS AS (
    WITH ELITE_TRANSFORM AS (
        SELECT
            *,
            cast(replace(ID, 'syn', '') AS INTEGER) AS SYN_ID
        FROM
            SAGE.PORTAL_RAW.ELITE
    ),

    DEDUP_FILEDOWNLOAD AS (
        SELECT DISTINCT
            USER_ID,
            FILE_HANDLE_ID AS FD_FILE_HANDLE_ID,
            RECORD_DATE
        FROM
            SYNAPSE_DATA_WAREHOUSE.SYNAPSE.FILEDOWNLOAD
    ),

    DOWNLOAD_COUNT AS (
        SELECT
            ELITE_TRANSFORM.*,
            FD.*
        FROM ELITE_TRANSFORM
        LEFT JOIN
            SYNAPSE_DATA_WAREHOUSE.SYNAPSE.NODE_LATEST AS NODE_LATEST
            ON
                ELITE_TRANSFORM.SYN_ID = NODE_LATEST.ID
        INNER JOIN
            DEDUP_FILEDOWNLOAD AS FD
            ON
                NODE_LATEST.FILE_HANDLE_ID = FD.FD_FILE_HANDLE_ID
    )

    SELECT *
    FROM
        DOWNLOAD_COUNT
);

-- * NF
-- The NF fileview doesn't have a file handle id
-- so we need to update the synapse id column to be an integer withou the syn prefix
-- and join on the latest version of the node table then on the file handle
CREATE OR REPLACE TABLE NF_DOWNLOADS AS (
    WITH NF_TRANSFORM AS (
        SELECT
            *,
            cast(replace(ID, 'syn', '') AS INTEGER) AS SYN_ID
        FROM
            SAGE.PORTAL_RAW.NF
    ),

    DEDUP_FILEDOWNLOAD AS (
        SELECT DISTINCT
            USER_ID,
            FILE_HANDLE_ID AS FD_FILE_HANDLE_ID,
            RECORD_DATE
        FROM
            SYNAPSE_DATA_WAREHOUSE.SYNAPSE.FILEDOWNLOAD
    ),

    DOWNLOAD_COUNT AS (
        SELECT
            NF_TRANSFORM.*,
            FD.*
        FROM
            NF_TRANSFORM
        LEFT JOIN
            SYNAPSE_DATA_WAREHOUSE.SYNAPSE.NODE_LATEST AS NODE_LATEST
            ON
                NF_TRANSFORM.SYN_ID = NODE_LATEST.ID
        INNER JOIN
            DEDUP_FILEDOWNLOAD AS FD
            ON
                NODE_LATEST.FILE_HANDLE_ID = FD.FD_FILE_HANDLE_ID
    )

    SELECT *
    FROM
        DOWNLOAD_COUNT
);

-- * psychencode
-- The psychencode fileview doesn't have a file handle id
-- so we need to update the synapse id column to be an integer withou the syn prefix
-- and join on the latest version of the node table then on the file handle
CREATE OR REPLACE TABLE PSYCHENCODE_DOWNLOADS AS (
    WITH PSYCHENCODE_TRANSFORM AS (
        SELECT
            *,
            cast(replace(ID, 'syn', '') AS INTEGER) AS SYN_ID
        FROM
            SAGE.PORTAL_RAW.PSYCHENCODE
    ),

    DEDUP_FILEDOWNLOAD AS (
        SELECT DISTINCT
            USER_ID,
            FILE_HANDLE_ID AS FD_FILE_HANDLE_ID,
            RECORD_DATE
        FROM
            SYNAPSE_DATA_WAREHOUSE.SYNAPSE.FILEDOWNLOAD
    ),

    DOWNLOAD_COUNT AS (
        SELECT
            PSYCHENCODE_TRANSFORM.*,
            FD.*
        FROM
            PSYCHENCODE_TRANSFORM
        LEFT JOIN
            SYNAPSE_DATA_WAREHOUSE.SYNAPSE.NODE_LATEST AS NODE_LATEST
            ON
                PSYCHENCODE_TRANSFORM.SYN_ID = NODE_LATEST.ID
        INNER JOIN
            DEDUP_FILEDOWNLOAD AS FD
            ON
                NODE_LATEST.FILE_HANDLE_ID = FD.FD_FILE_HANDLE_ID
    )

    SELECT *
    FROM
        DOWNLOAD_COUNT
);

-- * HTAN level 3/4 data
-- The htan fileview doesn't have a file handle id
-- so we need to update the synapse id column to be an integer withou the syn prefix
-- and join on the latest version of the node table then on the file handle
CREATE OR REPLACE TABLE HTAN_DOWNLOADS AS (
    WITH HTAN_TRANSFORM AS (
        SELECT
            *,
            cast(replace(ENTITYID, 'syn', '') AS INTEGER) AS SYN_ID
        FROM
            SAGE.PORTAL_RAW.HTAN
    ),

    DEDUP_FILEDOWNLOAD AS (
        SELECT DISTINCT
            USER_ID,
            FILE_HANDLE_ID AS FD_FILE_HANDLE_ID,
            RECORD_DATE
        FROM
            SYNAPSE_DATA_WAREHOUSE.SYNAPSE.FILEDOWNLOAD
    ),

    DOWNLOAD_COUNT AS (
        SELECT
            HTAN_TRANSFORM.*,
            FD.*
        FROM
            HTAN_TRANSFORM
        LEFT JOIN
            SYNAPSE_DATA_WAREHOUSE.SYNAPSE.NODE_LATEST AS NODE_LATEST
            ON
                HTAN_TRANSFORM.SYN_ID = NODE_LATEST.ID
        INNER JOIN
            DEDUP_FILEDOWNLOAD AS FD
            ON
                NODE_LATEST.FILE_HANDLE_ID = FD.FD_FILE_HANDLE_ID
    )

    SELECT *
    FROM
        DOWNLOAD_COUNT
);

-- number of downloads per user
SELECT
    USER_ID,
    count(RECORD_DATE) AS NUMBER_OF_DOWNLOADS
FROM
    SAGE.PORTAL_DOWNLOADS.HTAN_DOWNLOADS
GROUP BY
    USER_ID
ORDER BY
    NUMBER_OF_DOWNLOADS DESC;
