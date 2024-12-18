USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Add table comment
COMMENT ON TABLE nodesnapshots IS 'This table contain snapshots of nodes (Nodes are project, file, folders...). Snapshots are taken when nodes are created, updated or deleted. Note: Snapshots are also taken periodically and independently of the changes. The snapshot_timestamp is the time when the snapshot was taken.';

-- Add column comments
COMMENT ON COLUMN nodesnapshots.change_type IS 'The type of change that occurred on the node, e.g., CREATE, UPDATE, DELETE.';
COMMENT ON COLUMN nodesnapshots.change_timestamp IS 'The time when the change (created/updated/deleted) on the node is pushed to the queue for snapshotting.';
COMMENT ON COLUMN nodesnapshots.change_user_id IS 'The unique identifier of the user who made the change to the node.';
COMMENT ON COLUMN nodesnapshots.snapshot_timestamp IS 'The time when the snapshot was taken. (It is usually after the change happened).';
COMMENT ON COLUMN nodesnapshots.id IS 'The unique identifier of the node.';
COMMENT ON COLUMN nodesnapshots.benefactor_id IS 'The identifier of the (ancestor) node which provides the permissions that apply to this node. Can be the id of the node itself.';
COMMENT ON COLUMN nodesnapshots.project_id IS 'The project where the node resides. It will be empty for the change type DELETE.';
COMMENT ON COLUMN nodesnapshots.parent_id IS 'The unique identifier of the parent in the node hierarchy.';
COMMENT ON COLUMN nodesnapshots.node_type IS 'The type of the node. Allowed node types are : project, folder, file, table, link, entityview, dockerrepo, submissionview, dataset, datasetcollection, materializedview, virtualtable.';
COMMENT ON COLUMN nodesnapshots.created_on IS 'The creation time of the node.';
COMMENT ON COLUMN nodesnapshots.created_by IS 'The unique identifier of the user who created the node.';
COMMENT ON COLUMN nodesnapshots.modified_on IS 'The most recent change time of the node.';
COMMENT ON COLUMN nodesnapshots.modified_by IS 'The unique identifier of the user who last modified the node.';
COMMENT ON COLUMN nodesnapshots.version_number IS 'The version of the node on which the change occurred, if applicable.';
COMMENT ON COLUMN nodesnapshots.file_handle_id IS 'The unique identifier of the file handle if the node is a file, null otherwise.';
COMMENT ON COLUMN nodesnapshots.name IS 'The name of the node.';
COMMENT ON COLUMN nodesnapshots.version_comment IS 'A short description assigned to this node version.';
COMMENT ON COLUMN nodesnapshots.version_label IS 'A short label assigned to this node version.';
COMMENT ON COLUMN nodesnapshots.alias IS 'An alias assigned to a project entity if present.';
COMMENT ON COLUMN nodesnapshots.activity_id IS 'The reference to the id of an activity assigned to the node.';
COMMENT ON COLUMN nodesnapshots.column_model_ids IS 'For entities that define a table schema (e.g. table, views etc), the list of column ids assigned to the schema.';
COMMENT ON COLUMN nodesnapshots.scope_ids IS 'For entities that define a scope (e.g. entity views, subsmission views etc), the list of entity ids included in the scope.';
COMMENT ON COLUMN nodesnapshots.items IS 'For entities that define a fixed list of entity references (e.g. dataset, dataset collections), the list of entity references included in the scope.';
COMMENT ON COLUMN nodesnapshots.reference IS 'For Link entities, the reference to the linked target.';
COMMENT ON COLUMN nodesnapshots.is_search_enabled IS 'For Table like entities (e.g. EntityView, MaterializedView etc), defines if full text search is enabled on those entities.';
COMMENT ON COLUMN nodesnapshots.defining_sql IS 'For tables that are driven by a synapse SQL query (e.g. MaterializedView, VirtualTable), defines the underlying SQL query.';
COMMENT ON COLUMN nodesnapshots.is_public IS 'If true, READ permission is granted to all the Synapse users, including the anonymous user, at the time of the snapshot.';
COMMENT ON COLUMN nodesnapshots.is_controlled IS 'If true, an access requirement managed by the ACT is set on the node.';
COMMENT ON COLUMN nodesnapshots.is_restricted IS 'If true, a terms-of-use access requirement is set on the node.';
COMMENT ON COLUMN nodesnapshots.effective_ars IS 'The list of access requirement ids that apply to the entity at the time the snapshot was taken.';
COMMENT ON COLUMN nodesnapshots.annotations IS 'The json representation of the entity annotations assigned by the user.';
COMMENT ON COLUMN nodesnapshots.derived_annotations IS 'The json representation of the entity annotations that were derived by the schema of the entity.';
COMMENT ON COLUMN nodesnapshots.internal_annotations IS 'The json representation of the entity internal annotations that are used to store additional data about different types of entity (e.g. dataset checksum, size, count).';
COMMENT ON COLUMN nodesnapshots.version_history IS 'The list of entity versions, at the time of the snapshot.';
COMMENT ON COLUMN nodesnapshots.snapshot_date IS 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';
