USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

create or replace dynamic table FILE_LATEST(
	CHANGE_TYPE COMMENT 'The type of change that occurred on the file handle, e.g., CREATE, UPDATE, DELETE.',
	CHANGE_TIMESTAMP COMMENT 'The time when the change (created/updated/deleted) on the file is pushed to the queue for snapshotting.',
	CHANGE_USER_ID COMMENT 'The unique identifier of the user who made the change to the file.',
	SNAPSHOT_TIMESTAMP COMMENT 'The time when the snapshot was taken (It is usually after the change happened).',
	ID COMMENT 'The unique identifier of the file handle.',
	CREATED_BY COMMENT 'The unique identifier of the user who created the file handle.',
	CREATED_ON COMMENT 'The creation timestamp of the file handle.',
	MODIFIED_ON COMMENT 'The most recent change time of the file handle.',
	CONCRETE_TYPE COMMENT 'The type of the file handle. Allowed file handles are: S3FileHandle, ProxyFileHandle, ExternalFileHandle, ExternalObjectStoreFileHandle, GoogleCloudFileHandle.',
	CONTENT_MD5 COMMENT 'The md5 hash (using MD5 algorithm) of the file referenced by the file handle.',
	CONTENT_TYPE COMMENT 'Metadata about the content of the file, e.g., application/json, application/zip, application/octet-stream.',
	FILE_NAME COMMENT 'The name of the file referenced by the file handle.',
	STORAGE_LOCATION_ID COMMENT 'The identifier of the environment, where the physical files are stored.',
	CONTENT_SIZE COMMENT 'The size of the file referenced by the file handle.',
	BUCKET COMMENT 'The bucket where the file is physically stored. Applicable for s3 and GCP, otherwise empty.',
	KEY COMMENT 'The key name uniquely identifies the object (file) in the bucket.',
	PREVIEW_ID COMMENT 'The identifier of the file handle that contains a preview of the file referenced by this file handle.',
	IS_PREVIEW COMMENT 'If true, the file referenced by this file handle is a preview of another file.',
	STATUS COMMENT 'The availability status of the file referenced by the file handle. AVAILABLE: accessible via Synapse; UNLINKED: not referenced by Synapse and therefore available for garbage collection; ARCHIVED: the file has been garbage collected.',
	SNAPSHOT_DATE COMMENT 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.'
) target_lag = '1 day' refresh_mode = AUTO initialize = ON_CREATE warehouse = COMPUTE_XSMALL
 COMMENT='This dynamic table, indexed by the ID column, contains the most recent snapshot of file handles.'
 as 
    WITH dedup_filesnapshots AS (
        SELECT
            *
        FROM {{database_name}}.SYNAPSE_RAW.FILESNAPSHOTS --noqa: TMP
        WHERE
            SNAPSHOT_DATE >= CURRENT_DATE - INTERVAL '30 days' AND NOT IS_PREVIEW
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