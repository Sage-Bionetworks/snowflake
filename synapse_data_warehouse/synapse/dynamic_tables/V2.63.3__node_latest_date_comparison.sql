USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

create or replace dynamic table NODE_LATEST(
	CHANGE_TYPE COMMENT 'The type of change that occurred on the node, e.g., CREATE, UPDATE.',
	CHANGE_TIMESTAMP COMMENT 'The time when the change (created/updated) on the node is pushed to the queue for snapshotting.',
	CHANGE_USER_ID COMMENT 'The unique identifier of the user who made the change to the node.',
	SNAPSHOT_TIMESTAMP COMMENT 'The time when the snapshot was taken. (It is usually after the change happened).',
	ID COMMENT 'The unique identifier of the node.',
	BENEFACTOR_ID COMMENT 'The identifier of the (ancestor) node which provides the permissions that apply to this node. Can be the id of the node itself.',
	PROJECT_ID COMMENT 'The project where the node resides.',
	PARENT_ID COMMENT 'The unique identifier of the parent in the node hierarchy.',
	NODE_TYPE COMMENT 'The type of the node. Allowed node types are: project, folder, file, table, link, entityview, dockerrepo, submissionview, dataset, datasetcollection, materializedview, virtualtable.',
	CREATED_ON COMMENT 'The creation time of the node.',
	CREATED_BY COMMENT 'The unique identifier of the user who created the node.',
	MODIFIED_ON COMMENT 'The most recent change time of the node.',
	MODIFIED_BY COMMENT 'The unique identifier of the user who last modified the node.',
	VERSION_NUMBER COMMENT 'The version of the node on which the change occurred, if applicable.',
	FILE_HANDLE_ID COMMENT 'The unique identifier of the file handle if the node is a file, null otherwise.',
	NAME COMMENT 'The name of the node.',
	IS_PUBLIC COMMENT 'If true, READ permission is granted to all the Synapse users, including the anonymous user, at the time of the snapshot.',
	IS_CONTROLLED COMMENT 'If true, an access requirement managed by the ACT is set on the node.',
	IS_RESTRICTED COMMENT 'If true, a terms-of-use access requirement is set on the node.',
	SNAPSHOT_DATE COMMENT 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.',
	EFFECTIVE_ARS COMMENT 'The list of access requirement ids that apply to the entity at the time the snapshot was taken.',
	ANNOTATIONS COMMENT 'The json representation of the entity annotations assigned by the user.',
	DERIVED_ANNOTATIONS COMMENT 'The json representation of the entity annotations that were derived by the schema of the entity.',
	VERSION_COMMENT COMMENT 'A short description assigned to this node version.',
	VERSION_LABEL COMMENT 'A short label assigned to this node version.',
	ALIAS COMMENT 'An alias assigned to a project entity if present.',
	ACTIVITY_ID COMMENT 'The reference to the id of an activity assigned to the node.',
	COLUMN_MODEL_IDS COMMENT 'For entities that define a table schema (e.g. table, views etc), the list of column ids assigned to the schema.',
	SCOPE_IDS COMMENT 'For entities that define a scope (e.g. entity views, submission views etc), the list of entity ids included in the scope.',
	ITEMS COMMENT 'For entities that define a fixed list of entity references (e.g. dataset, dataset collections), the list of entity references included in the scope.',
	REFERENCE COMMENT 'For Link entities, the reference to the linked target.',
	IS_SEARCH_ENABLED COMMENT 'For Table like entities (e.g. EntityView, MaterializedView etc), defines if full text search is enabled on those entities.',
	DEFINING_SQL COMMENT 'For tables that are driven by a synapse SQL query (e.g. MaterializedView, VirtualTable), defines the underlying SQL query.',
	INTERNAL_ANNOTATIONS COMMENT 'The json representation of the entity internal annotations that are used to store additional data about different types of entity (e.g. dataset checksum, size, count).',
	VERSION_HISTORY COMMENT 'The list of entity versions, at the time of the snapshot.',
	PROJECT_STORAGE_USAGE COMMENT 'The storage usage information for the project, including size and count metrics.'
) target_lag = '1 day' refresh_mode = AUTO initialize = ON_CREATE warehouse = COMPUTE_XSMALL
 COMMENT='This dynamic table, indexed by ID, contains the latest snapshot of Synapse nodes (projects, files, folders, tables, etc.). It is derived from NODESNAPSHOTS raw data and provides deduplicated node information. The table is refreshed daily and contains only the most recent node entries for each ID from the past 30 days. Each row represents a specific Synapse node with its current state and metadata.'
 as
        WITH latest_unique_rows AS (
            SELECT
                CHANGE_TYPE,
                CHANGE_TIMESTAMP,
                CHANGE_USER_ID,
                SNAPSHOT_TIMESTAMP,
                ID,
                BENEFACTOR_ID,
                PROJECT_ID,
                PARENT_ID,
                NODE_TYPE,
                CREATED_ON,
                CREATED_BY,
                MODIFIED_ON,
                MODIFIED_BY,
                VERSION_NUMBER,
                FILE_HANDLE_ID,
                NAME,
                IS_PUBLIC,
                IS_CONTROLLED,
                IS_RESTRICTED,
                SNAPSHOT_DATE,
                EFFECTIVE_ARS,
                ANNOTATIONS,
                DERIVED_ANNOTATIONS,
                VERSION_COMMENT,
                VERSION_LABEL,
                ALIAS,
                ACTIVITY_ID,
                COLUMN_MODEL_IDS,
                SCOPE_IDS,
                ITEMS,
                REFERENCE,
                IS_SEARCH_ENABLED,
                DEFINING_SQL,
                INTERNAL_ANNOTATIONS,
                VERSION_HISTORY,
                PROJECT_STORAGE_USAGE
            FROM
                {{database_name}}.synapse_raw.nodesnapshots --noqa: TMP
            WHERE
                SNAPSHOT_DATE >= CURRENT_DATE - INTERVAL '30 DAYS'
            QUALIFY ROW_NUMBER() OVER (
                    PARTITION BY id
                    ORDER BY change_timestamp DESC, snapshot_timestamp DESC
                ) = 1
        )
        SELECT
            *
        FROM
            latest_unique_rows
        WHERE
            NOT (CHANGE_TYPE = 'DELETE' OR BENEFACTOR_ID = '1681355' OR PARENT_ID = '1681355') -- 1681355 is the synID of the trash can on Synapse
        ORDER BY
            latest_unique_rows.id ASC;