-- Add table and column comments to userprofile_latest dynamic table
USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP
-- Table comments
COMMENT ON DYNAMIC TABLE FILE_LATEST IS 'This dynamic table contains the latest snapshot of files during the past 30 days. Snapshots are taken when files are created or modified. Note: Snapshots are also taken periodically and independently of the changes. The snapshot_timestamp records when the snapshot was taken.';
-- Column comments
COMMENT ON COLUMN FILE_LATEST.CHANGE_TYPE IS 'The type of change that occurred on the file handle, e.g., CREATE, UPDATE, DELETE.';
COMMENT ON COLUMN FILE_LATEST.CHANGE_TIMESTAMP IS 'The time when the change (created/updated/deleted) on the file is pushed to the queue for snapshotting.';
COMMENT ON COLUMN FILE_LATEST.CHANGE_USER_ID IS 'The unique identifier of the user who made the change to the file.';
COMMENT ON COLUMN FILE_LATEST.SNAPSHOT_TIMESTAMP IS 'The time when the snapshot was taken (It is usually after the change happened).';
COMMENT ON COLUMN FILE_LATEST.ID IS 'The unique identifier of the file handle.';
COMMENT ON COLUMN FILE_LATEST.CREATED_BY IS 'The unique identifier of the user who created the file handle.';
COMMENT ON COLUMN FILE_LATEST.CREATED_ON IS 'The creation timestamp of the file handle.';
COMMENT ON COLUMN FILE_LATEST.MODIFIED_ON IS 'The most recent change time of the file handle.';
COMMENT ON COLUMN FILE_LATEST.CONCRETE_TYPE IS 'The type of the file handle. Allowed file handles are: S3FileHandle, ProxyFileHandle, ExternalFileHandle, ExternalObjectStoreFileHandle, GoogleCloudFileHandle.';
COMMENT ON COLUMN FILE_LATEST.CONTENT_MD5 IS 'The md5 hash (using MD5 algorithm) of the file referenced by the file handle.';
COMMENT ON COLUMN FILE_LATEST.CONTENT_TYPE IS 'Metadata about the content of the file, e.g., application/json, application/zip, application/octet-stream.';
COMMENT ON COLUMN FILE_LATEST.FILE_NAME IS 'The name of the file referenced by the file handle.';
COMMENT ON COLUMN FILE_LATEST.STORAGE_LOCATION_ID IS 'The identifier of the environment, where the physical files are stored.';
COMMENT ON COLUMN FILE_LATEST.CONTENT_SIZE IS 'The size of the file referenced by the file handle.';
COMMENT ON COLUMN FILE_LATEST.BUCKET IS 'The bucket where the file is physically stored. Applicable for s3 and GCP, otherwise empty.';
COMMENT ON COLUMN FILE_LATEST.KEY IS 'The key name uniquely identifies the object (file) in the bucket.';
COMMENT ON COLUMN FILE_LATEST.PREVIEW_ID IS 'The identifier of the file handle that contains a preview of the file referenced by this file handle.';
COMMENT ON COLUMN FILE_LATEST.IS_PREVIEW IS 'If true, the file referenced by this file handle is a preview of another file.';
COMMENT ON COLUMN FILE_LATEST.STATUS IS 'The availability status of the file referenced by the file handle. AVAILABLE: accessible via Synapse; UNLINKED: not referenced by Synapse and therefore available for garbage collection; ARCHIVED: the file has been garbage collected.';
COMMENT ON COLUMN FILE_LATEST.SNAPSHOT_DATE IS 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';