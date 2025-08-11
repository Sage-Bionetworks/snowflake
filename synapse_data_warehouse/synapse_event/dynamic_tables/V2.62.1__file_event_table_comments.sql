USE SCHEMA {{database_name}}.synapse_event; --noqa: JJ01,PRS,TMP

-- Table comment
COMMENT ON DYNAMIC TABLE FILE_EVENT IS 'This table contains snapshots of file events. An event is determined by a unique combination of `id`, `modified_on`, `change_type`, and `change_timestamp` columns.

h2. Understanding file events

Most types of events will be indicated by a change in `modified_on`. For example, an updated `status` will be reflected by an updated `modified_on`.

||ID||MODIFIED_ON||STATUS||
|151325160|2025-03-05 12:42:55.000|ARCHIVED|
|151325160|2025-02-03 10:02:33.000|UNLINKED|
|151325160|2025-01-02 12:36:07.000|AVAILABLE|

Some records in this table are not events per se, but rather new information associated with a file. For example, a change to `change_timestamp` usually indicates a `preview_id` having been associated with this file.

||ID||CHANGE_TYPE||CHANGE_TIMESTAMP||PREVIEW_ID||
|151499163|UPDATE|2025-01-08 17:25:21.000|151499165|
|151499163|CREATE|2025-01-08 17:25:20.000|null|

h3. Understanding DELETE events

Records where `change_type` = DELETE have null values, except for these columns:

* `id`
* `change_type`
* `change_timestamp`
* `change_user_id`
* `concrete_type`
* `snapshot_date`
* `snapshot_timestamp`';
-- Column comments
COMMENT ON COLUMN FILE_EVENT.ID IS 'PRIMARY KEY (Composite). The unique identifier of the file handle.';
COMMENT ON COLUMN FILE_EVENT.MODIFIED_ON IS 'PRIMARY KEY (Composite). The most recent change time of the file handle.';
COMMENT ON COLUMN FILE_EVENT.CHANGE_TYPE IS 'PRIMARY KEY (Composite). The type of change that occurred on the file handle, e.g., CREATE, UPDATE, DELETE.';
COMMENT ON COLUMN FILE_EVENT.CHANGE_TIMESTAMP IS 'PRIMARY KEY (Composite). The time when the change (created/updated/deleted) on the file is pushed to the queue for snapshotting.';
COMMENT ON COLUMN FILE_EVENT.CHANGE_USER_ID IS 'The unique identifier of the user who made the change to the file.';
COMMENT ON COLUMN FILE_EVENT.SNAPSHOT_TIMESTAMP IS 'The time when the snapshot was taken (It is usually after the change happened).';
COMMENT ON COLUMN FILE_EVENT.CREATED_BY IS 'The unique identifier of the user who created the file handle.';
COMMENT ON COLUMN FILE_EVENT.CREATED_ON IS 'The creation timestamp of the file handle.';
COMMENT ON COLUMN FILE_EVENT.CONCRETE_TYPE IS 'The type of the file handle. Allowed file handles are: S3FileHandle, ProxyFileHandle, ExternalFileHandle, ExternalObjectStoreFileHandle, GoogleCloudFileHandle.';
COMMENT ON COLUMN FILE_EVENT.CONTENT_MD5 IS 'The md5 hash (using MD5 algorithm) of the file referenced by the file handle.';
COMMENT ON COLUMN FILE_EVENT.CONTENT_TYPE IS 'Metadata about the content of the file, e.g., application/json, application/zip, application/octet-stream.';
COMMENT ON COLUMN FILE_EVENT.FILE_NAME IS 'The name of the file referenced by the file handle.';
COMMENT ON COLUMN FILE_EVENT.STORAGE_LOCATION_ID IS 'The identifier of the environment, where the physical files are stored.';
COMMENT ON COLUMN FILE_EVENT.CONTENT_SIZE IS 'The size of the file referenced by the file handle.';
COMMENT ON COLUMN FILE_EVENT.BUCKET IS 'The bucket where the file is physically stored. Applicable for s3 and GCP, otherwise empty.';
COMMENT ON COLUMN FILE_EVENT.KEY IS 'The key name uniquely identifies the object (file) in the bucket.';
COMMENT ON COLUMN FILE_EVENT.PREVIEW_ID IS 'The identifier of the file handle that contains a preview of the file referenced by this file handle.';
COMMENT ON COLUMN FILE_EVENT.IS_PREVIEW IS 'If true, the file referenced by this file handle is a preview of another file.';
COMMENT ON COLUMN FILE_EVENT.STATUS IS 'The availability status of the file referenced by the file handle. AVAILABLE: accessible via Synapse; UNLINKED: not referenced by Synapse and therefore available for garbage collection; ARCHIVED: the file has been garbage collected.';
COMMENT ON COLUMN FILE_EVENT.SNAPSHOT_DATE IS 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';