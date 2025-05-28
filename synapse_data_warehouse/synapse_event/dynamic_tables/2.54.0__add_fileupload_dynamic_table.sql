USE SCHEMA {{database_name}}.SYNAPSE_EVENT; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE DYNAMIC TABLE FILEUPLOAD
    (
        TIMESTAMP TIMESTAMP_NTZ(9) COMMENT 'The time when the file upload event is pushed to the queue, after a successful upload of a file or change in the existing table.',
	    USER_ID NUMBER(38,0) COMMENT 'The id of the user who requested the upload.',
	    PROJECT_ID NUMBER(38,0) COMMENT 'The unique identifier of the project where the uploaded entity resides. Applicable only for FileEntity and TableEntity.',
	    FILE_HANDLE_ID NUMBER(38,0) COMMENT 'The unique identifier of the file handle.',
	    ASSOCIATION_OBJECT_ID NUMBER(38,0) COMMENT 'The unique identifier of the Synapse object (without ''syn'' prefix) that wraps the file.',
	    ASSOCIATION_OBJECT_TYPE VARCHAR(16777216) COMMENT 'The type of the Synapse object that wraps the file, e.g., FileEntity, TableEntity, WikiAttachment, WikiMarkdown, UserProfileAttachment, MessageAttachment, TeamAttachment.',
	    STACK VARCHAR(16777216) COMMENT 'The stack (prod, dev) on which the upload request was processed.',
	    INSTANCE VARCHAR(16777216) COMMENT 'The version of the stack that processed the upload request.',
	    RECORD_DATE DATE COMMENT 'The data is partitioned for fast and cost effective queries. The timestamp field is converted into a date and stored in the record_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.',
    )
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    COMMENT = 'This dynamic table, indexed by the <> columns, contains a history of file upload events on Synapse.'
    AS
    WITH dedup_fileupload AS (
        SELECT
            TIMESTAMP,
            USER_ID,
            PROJECT_ID,
            FILE_HANDLE_ID,
            ASSOCIATION_OBJECT_ID,
            ASSOCIATION_OBJECT_TYPE,
            STACK,
            INSTANCE,
            RECORD_DATE
        FROM {{database_name}}.SYNAPSE_RAW.FILEUPLOAD --noqa: TMP
        QUALIFY
            ROW_NUMBER() OVER (
                PARTITION BY USER_ID, ASSOCIATION_OBJECT_ID, RECORD_DATE
                ORDER BY TIMESTAMP DESC, RECORD_DATE DESC
            ) = 1
    )
    SELECT 
        *
    FROM 
        dedup_fileupload;
