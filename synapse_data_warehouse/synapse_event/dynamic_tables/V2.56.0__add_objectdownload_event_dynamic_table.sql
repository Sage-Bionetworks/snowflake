-- Introduce the dynamic table
USE SCHEMA {{database_name}}.SYNAPSE_EVENT; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE DYNAMIC TABLE OBJECTDOWNLOAD_EVENT
    (
        TIMESTAMP TIMESTAMP_NTZ(9) COMMENT 'The time when the file download event is pushed to the queue for recording, after generating the pre-signed url.',
	USER_ID NUMBER(38,0) COMMENT 'PRIMARY KEY (Composite). The id of the user who downloaded the file.',
	PROJECT_ID NUMBER(38,0) COMMENT 'The unique identifier of the project where the downloaded entity resides. Applicable only for FileEntity and TableEntity.',
	FILE_HANDLE_ID NUMBER(38,0) COMMENT 'The unique identifier of the file handle.',
	DOWNLOADED_FILE_HANDLE_ID NUMBER(38,0) COMMENT 'The unique identifier of the zip file handle containing the downloaded file when the download is requested as zip/package, otherwise the id of the file handle itself.',
	ASSOCIATION_OBJECT_ID NUMBER(38,0) COMMENT 'PRIMARY KEY (Composite). The unique identifier of the Synapse object (without ''syn'' prefix) that wraps the file.',
	ASSOCIATION_OBJECT_TYPE VARCHAR(16777216) COMMENT 'PRIMARY KEY (Composite). The type of the Synapse object that wraps the file, e.g., FileEntity, TableEntity, WikiAttachment, WikiMarkdown, UserProfileAttachment, MessageAttachment, TeamAttachment.',
	STACK VARCHAR(16777216) COMMENT 'The stack (prod, dev) on which the download request was processed.',
	INSTANCE VARCHAR(16777216) COMMENT 'The version of the stack that processed the download request.',
	RECORD_DATE DATE COMMENT 'PRIMARY KEY (Composite). The data is partitioned for fast and cost effective queries. The timestamp field is converted into a date and stored in the record_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.',
	SESSION_ID VARCHAR(16777216) COMMENT 'The UUID assigned to the API request that triggered this download.  By joining this table with the processedaccessrecord on session_id, more information about the call that triggered this download can be found.'
    )
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    COMMENT = 'This dynamic table, indexed by the USER_ID, ASSOCIATION_OBJECT_ID, ASSOCIATION_OBJECT_TYPE and RECORD_DATE columns, contains the most recent file download events.'
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
        FROM 
            {{database_name}}.SYNAPSE_RAW.FILEDOWNLOAD --noqa: TMP
        WHERE
            ASSOCIATION_OBJECT_ID IS NOT NULL 
	    AND USER_ID IS NOT NULL 
	    AND ASSOCIATION_OBJECT_TYPE IS NOT NULL 
	    AND RECORD_DATE IS NOT NULL
        QUALIFY
            ROW_NUMBER() OVER (
                PARTITION BY USER_ID, ASSOCIATION_OBJECT_ID, ASSOCIATION_OBJECT_TYPE, RECORD_DATE
                ORDER BY TIMESTAMP DESC
            ) = 1
    )
    SELECT 
    *
    FROM 
        dedup_filedownload;


-- Add the primary key constraint
ALTER TABLE OBJECTDOWNLOAD_EVENT 
  ADD CONSTRAINT composite_primary_keys 
  PRIMARY KEY (USER_ID, ASSOCIATION_OBJECT_ID, ASSOCIATION_OBJECT_TYPE, RECORD_DATE);
