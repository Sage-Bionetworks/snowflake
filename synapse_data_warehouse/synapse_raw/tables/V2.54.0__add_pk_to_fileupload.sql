use schema {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Add the composite primary key & column commments to the fileupload table
alter table fileupload
add constraint fileupload_pk
primary key (user_id, file_handle_id, timestamp);

COMMENT ON COLUMN fileupload.user_id IS 'PRIMARY KEY (Composite). The id of the user who requested the upload.';
COMMENT ON COLUMN fileupload.file_handle_id IS 'PRIMARY KEY (Composite). The unique identifier of the file handle.';
COMMENT ON COLUMN fileupload.timestamp IS 'PRIMARY KEY (Composite). The time when the upload event is pushed to the queue, after a successful upload of a file or change in the existing table.';
