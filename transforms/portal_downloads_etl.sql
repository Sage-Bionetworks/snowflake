USE ROLE SYSADMIN;
USE DATABASE SAGE;
USE SCHEMA PORTAL_DOWNLOADS;
-- Data up to October 18th for now

-- * Metrics for AD portal
CREATE TABLE IF NOT EXISTS AD_DOWNLOADS AS (
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
            AD."dataFileHandleId" = FD.FD_FILE_HANDLE_ID
);

-- * GENIE
CREATE TABLE IF NOT EXISTS GENIE_DOWNLOADS AS (
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
            GENIE."dataFileHandleId" = FD.FD_FILE_HANDLE_ID
);

-- * ELITE
CREATE TABLE IF NOT EXISTS ELITE_DOWNLOADS AS (
    WITH ELITE_TRANSFORM AS (
        SELECT
            *,
            cast(replace("id", 'syn', '') AS INTEGER) AS SYN_ID
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
            NODE_LATEST.*,
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
CREATE TABLE IF NOT EXISTS NF_DOWNLOADS AS (
    WITH NF_TRANSFORM AS (
        SELECT
            *,
            cast(replace("id", 'syn', '') AS INTEGER) AS SYN_ID
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
            NODE_LATEST.*,
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
CREATE TABLE IF NOT EXISTS PSYCHENCODE_DOWNLOADS AS (
    WITH PSYCHENCODE_TRANSFORM AS (
        SELECT
            *,
            cast(replace("id", 'syn', '') AS INTEGER) AS SYN_ID
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
            NODE_LATEST.*,
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

-- * HTAN
CREATE TABLE IF NOT EXISTS HTAN_DOWNLOADS AS (
    WITH HTAN_TRANSFORM AS (
        SELECT
            *,
            cast(replace("entityId", 'syn', '') AS INTEGER) AS SYN_ID
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
            NODE_LATEST.*,
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
