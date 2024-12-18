USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Add table comment
COMMENT ON TABLE filedownload IS 'The table contain records of all the downloads of the Synapse, e.g., file, zip/package, attachments. The events are recorded only after the pre-signed url for requested download entity is generated.';

-- Add column comments
COMMENT ON COLUMN filedownload.timestamp IS 'The time when the file download event is pushed to the queue for recording, after generating the pre-signed url.';
COMMENT ON COLUMN filedownload.user_id IS 'The id of the user who downloaded the file.';
COMMENT ON COLUMN filedownload.project_id IS 'The unique identifier of the project where the downloaded entity resides. Applicable only for FileEntity and TableEntity.';
COMMENT ON COLUMN filedownload.file_handle_id IS 'The unique identifier of the file handle.';
COMMENT ON COLUMN filedownload.downloaded_file_handle_id IS 'The unique identifier of the zip file handle containing the downloaded file when the download is requested as zip/package, otherwise the id of the file handle itself.';
COMMENT ON COLUMN filedownload.association_object_id IS 'The unique identifier of the Synapse object (without ''syn'' prefix) that wraps the file.';
COMMENT ON COLUMN filedownload.association_object_type IS 'The type of the Synapse object that wraps the file, e.g., FileEntity, TableEntity, WikiAttachment, WikiMarkdown, UserProfileAttachment, MessageAttachment, TeamAttachment.';
COMMENT ON COLUMN filedownload.stack IS 'The stack (prod, dev) on which the download request was processed.';
COMMENT ON COLUMN filedownload.instance IS 'The version of the stack that processed the download request.';
COMMENT ON COLUMN filedownload.session_id IS 'The UUID assigned to the API request that triggered this download.  By joining this table with the processedaccessrecord on session_id, more information about the call that triggered this download can be found.';
COMMENT ON COLUMN filedownload.record_date IS 'The data is partitioned for fast and cost effective queries. The timestamp field is converted into a date and stored in the record_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';
