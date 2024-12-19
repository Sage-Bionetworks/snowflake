USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Add table comment
COMMENT ON TABLE filesnapshots IS 'This table contain snapshots of file handles. Snapshots are taken when file handles are created, updated or deleted. Note: Snapshots are also taken periodically and independently of the changes. The snapshot_timestamp records when the snapshot was taken.';

-- Add column comments
COMMENT ON COLUMN filesnapshots.change_type IS 'The type of change that occurred on the file handle, e.g., CREATE, UPDATE, DELETE.';
COMMENT ON COLUMN filesnapshots.change_timestamp IS 'The time when the change (created/updated/deleted) on the file is pushed to the queue for snapshotting.';
COMMENT ON COLUMN filesnapshots.change_user_id IS 'The unique identifier of the user who made the change to the file.';
COMMENT ON COLUMN filesnapshots.snapshot_timestamp IS 'The time when the snapshot was taken (It is usually after the change happened).';
COMMENT ON COLUMN filesnapshots.id IS 'The unique identifier of the file handle.';
COMMENT ON COLUMN filesnapshots.created_by IS 'The unique identifier of the user who created the file handle.';
COMMENT ON COLUMN filesnapshots.created_on IS 'The creation timestamp of the file handle.';
COMMENT ON COLUMN filesnapshots.modified_on IS 'The most recent change time of the file handle.';
COMMENT ON COLUMN filesnapshots.concrete_type IS 'The type of the file handle. Allowed file handles are: S3FileHandle, ProxyFileHandle, ExternalFileHandle, ExternalObjectStoreFileHandle, GoogleCloudFileHandle.';
COMMENT ON COLUMN filesnapshots.content_md5 IS 'The md5 hash (using MD5 algorithm) of the file referenced by the file handle.';
COMMENT ON COLUMN filesnapshots.content_type IS 'Metadata about the content of the file, e.g., application/json, application/zip, application/octet-stream.';
COMMENT ON COLUMN filesnapshots.file_name IS 'The name of the file referenced by the file handle.';
COMMENT ON COLUMN filesnapshots.storage_location_id IS 'The identifier of the environment, where the physical files are stored.';
COMMENT ON COLUMN filesnapshots.content_size IS 'The size of the file referenced by the file handle.';
COMMENT ON COLUMN filesnapshots.bucket IS 'The bucket where the file is physically stored. Applicable for s3 and GCP, otherwise empty.';
COMMENT ON COLUMN filesnapshots.key IS 'The key name uniquely identifies the object (file) in the bucket.';
COMMENT ON COLUMN filesnapshots.preview_id IS 'The identifier of the file handle that contains a preview of the file referenced by this file handle.';
COMMENT ON COLUMN filesnapshots.is_preview IS 'If true, the file referenced by this file handle is a preview of another file';
COMMENT ON COLUMN filesnapshots.status IS 'The availability status of the file referenced by the file handle. AVAILABLE:  accessible via Synapse; UNLINKED: not referenced by Synapse and therefore available for garbage collection; ARCHIVED: the file has been garbage collected.';
COMMENT ON COLUMN filesnapshots.snapshot_date IS 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';
