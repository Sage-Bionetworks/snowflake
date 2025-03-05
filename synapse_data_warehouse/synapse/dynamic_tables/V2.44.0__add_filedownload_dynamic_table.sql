-- Introduce the dynamic table
USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE DYNAMIC TABLE SYNAPSE_DATA_WAREHOUSE_DanLu_STAGE.SYNAPSE.FILEDOWNLOAD_LATEST
    (
        TIMESTAMP TIMESTAMP_NTZ(9) COMMENT 'The time when the file download event is pushed to the queue for recording, after generating the pre-signed url.',
	    USER_ID NUMBER(38,0) COMMENT 'The id of the user who downloaded the file.',
	    PROJECT_ID NUMBER(38,0) COMMENT 'The unique identifier of the project where the downloaded entity resides. Applicable only for FileEntity and TableEntity.',
	    FILE_HANDLE_ID NUMBER(38,0) COMMENT 'The unique identifier of the file handle.',
	    DOWNLOADED_FILE_HANDLE_ID NUMBER(38,0) COMMENT 'The unique identifier of the zip file handle containing the downloaded file when the download is requested as zip/package, otherwise the id of the file handle itself.',
	    ASSOCIATION_OBJECT_ID NUMBER(38,0) COMMENT 'The unique identifier of the Synapse object (without ''syn'' prefix) that wraps the file.',
	    ASSOCIATION_OBJECT_TYPE VARCHAR(16777216) COMMENT 'The type of the Synapse object that wraps the file, e.g., FileEntity, TableEntity, WikiAttachment, WikiMarkdown, UserProfileAttachment, MessageAttachment, TeamAttachment.',
	    STACK VARCHAR(16777216) COMMENT 'The stack (prod, dev) on which the download request was processed.',
	    INSTANCE VARCHAR(16777216) COMMENT 'The version of the stack that processed the download request.',
	    RECORD_DATE DATE COMMENT 'The data is partitioned for fast and cost effective queries. The timestamp field is converted into a date and stored in the record_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.',
	    SESSION_ID VARCHAR(16777216) COMMENT 'The UUID assigned to the API request that triggered this download.  By joining this table with the processedaccessrecord on session_id, more information about the call that triggered this download can be found.'
    )
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    COMMENT = 'This dynamic table contains the latest direct and zip/package file handle download attempts. A file handle will either be downloaded via zip/package or by itself, but not both.'
    AS
    WITH dedup_filedownload AS (
        SELECT
            TIMESTAMP,
            USER_ID,
            PROJECT_ID,
            FILE_HANDLE_ID,
            DOWNLOADED_FILE_HANDLE_ID,
            ASSOCIATION_OBJECT_ID,
            ASSOCIATION_OBJECT_TYPE,
            STACK,
            INSTANCE,
            RECORD_DATE,
            SESSION_ID
        FROM {{database_name}}.SYNAPSE_RAW.FILEDOWNLOAD --noqa: TMP
        QUALIFY
            ROW_NUMBER() OVER (
                PARTITION BY USER_ID, FILE_HANDLE_ID, DOWNLOADED_FILE_HANDLE_ID, RECORD_DATE
                ORDER BY TIMESTAMP DESC, RECORD_DATE DESC
            ) = 1
    ),
    zip_download AS ( -- Assume that each user downloads a zip/package only once per day.
        SELECT
            *
        FROM dedup_filedownload --noqa: TMP
        WHERE
            file_handle_id != downloaded_file_handle_id
        QUALIFY
            ROW_NUMBER() OVER (
                PARTITION BY USER_ID, DOWNLOADED_FILE_HANDLE_ID, RECORD_DATE
                ORDER BY TIMESTAMP DESC, RECORD_DATE DESC
            ) = 1
    ),
    direct_download AS ( -- Assume that if a file handle is obtained through a zip/package download, direct download is not implemented.
        SELECT
            *
        FROM
            dedup_filedownload
        WHERE
            file_handle_id = downloaded_file_handle_id
        AND file_handle_id not in (
            SELECT
                file_handle_id
            FROM
                dedup_filedownload
            WHERE
                file_handle_id != downloaded_file_handle_id
        )
    )
    SELECT 
        *
    FROM
        zip_download
    UNION ALL
    
    SELECT 
        *
    FROM
        direct_download
    ORDER BY 
        USER_ID, 
        FILE_HANDLE_ID, 
        DOWNLOADED_FILE_HANDLE_ID, 
        RECORD_DATE;
