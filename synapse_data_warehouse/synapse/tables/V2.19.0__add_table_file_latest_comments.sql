USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

ALTER TABLE FILE_LATEST SET COMMENT = 'The latest snapshot of the file.';  

COMMENT ON COLUMN FILE_LATEST.change_type IS 'The type of change that occurred on the file, e.g., CREATE, UPDATE, DELETE.';
COMMENT ON COLUMN FILE_LATEST.change_timestamp IS 'The time when the change (created/updated/deleted) on the file is pushed to the queue for snapshotting.';
COMMENT ON COLUMN FILE_LATEST.change_user_id IS 'The unique identifier of the user who made the change to the file.';
COMMENT ON COLUMN FILE_LATEST.snapshot_timestamp IS 'The time when the snapshot was taken. (It is usually after the change happened).';
COMMENT ON COLUMN FILE_LATEST.id IS 'The unique identifier of the file.';
COMMENT ON COLUMN FILE_LATEST.benefactor_id IS 'The identifier of the (ancestor) node which provides the permissions that apply to this file. Can be the id of the file itself.';
COMMENT ON COLUMN FILE_LATEST.project_id IS 'The project where the file resides. It will be empty for the change type DELETE.';
COMMENT ON COLUMN FILE_LATEST.parent_id IS 'The unique identifier of the parent in the node hierarchy.';
COMMENT ON COLUMN FILE_LATEST.node_type IS 'The type of the node. Allowed node types are : project, folder, file, table, link, entityview, dockerrepo, submissionview, dataset, datasetcollection, materializedview, virtualtable.';
COMMENT ON COLUMN FILE_LATEST.created_on IS 'The creation time of the file.';
COMMENT ON COLUMN FILE_LATEST.created_by IS 'The unique identifier of the user who created the file.';
COMMENT ON COLUMN FILE_LATEST.modified_on IS 'The most recent change time of the file.';
COMMENT ON COLUMN FILE_LATEST.modified_by IS 'The unique identifier of the user who last modified the file.';
COMMENT ON COLUMN FILE_LATEST.version_number IS 'The version of the file on which the change occurred, if applicable.';
COMMENT ON COLUMN FILE_LATEST.file_handle_id IS 'The unique identifier of the file handle.';
COMMENT ON COLUMN FILE_LATEST.name IS 'The name of the file.';
COMMENT ON COLUMN FILE_LATEST.is_public IS 'If true, READ permission is granted to all the Synapse users, including the anonymous user, at the time of the snapshot.';
COMMENT ON COLUMN FILE_LATEST.is_controlled IS 'If true, an access requirement managed by the ACT is set on the file.';
COMMENT ON COLUMN FILE_LATEST.is_restricted IS 'If true, a terms-of-use access requirement is set on the file.';
COMMENT ON COLUMN FILE_LATEST.effective_ars IS 'The list of access requirement ids that apply to the entity at the time the snapshot was taken.';
COMMENT ON COLUMN FILE_LATEST.annotations IS 'The json representation of the entity annotations assigned by the user.';
COMMENT ON COLUMN FILE_LATEST.derived_annotations IS 'The json representation of the entity annotations that were derived by the schema of the entity.';