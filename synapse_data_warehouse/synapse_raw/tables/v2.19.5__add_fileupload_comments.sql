USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
ALTER TABLE FILEUPLOAD SET COMMENT = 'This table contains upload records for FileEntity (e.g. a new file creation, upload or update to an existing file) and TableEntity (e.g. an appended row set to an existing table, uploaded file to an existing table). The events are recorded only after the file or change to a table is successfully uploaded.';

COMMENT ON COLUMN FILEUPLOAD.timestamp IS 'The time when the upload event is pushed to the queue, after a successful upload of a file or change in the existing table.';
COMMENT ON COLUMN FILEUPLOAD.user_id IS 'The id of the user who requested the upload.';
COMMENT ON COLUMN FILEUPLOAD.project_id IS 'The unique identifier of the project where the uploaded entity resides. Applicable only for FileEntity and TableEntity.';
COMMENT ON COLUMN FILEUPLOAD.file_handle_id IS 'The unique identifier of the file handle.'
COMMENT ON COLUMN FILEUPLOAD.association_object_id IS 'The unique identifier of the related FileEntity or TableEntity (without the ``syn`` prefix).'
COMMENT ON COLUMN FILEUPLOAD.association_object_type IS 'The type of Synapse object that wraps the file, e.g., FileEntity, TableEntity.'
COMMENT ON COLUMN FILEUPLOAD.stack IS 'The stack (prod, dev) on which the upload request was processed.'
COMMENT ON COLUMN FILEUPLOAD.instance IS 'The version of the stack that processed the upload request.'
COMMENT ON COLUMN FILEUPLOAD.record_date IS 'The data is partitioned for fast and cost effective queries. The timestamp field is converted into a date and stored in the record_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';
