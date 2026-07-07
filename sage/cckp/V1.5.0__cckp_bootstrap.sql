USE SCHEMA {{ database_name }}.cckp;

-- Create objects directly as SAGE_CCKP_ADMIN so ownership is correct from the start
-- (avoids the ownership-transfer task auto-suspension problem)
USE ROLE SAGE_CCKP_ADMIN;

-- 1. Dynamic table: MC2 Center project list (upstream; refreshes weekly)
CREATE DYNAMIC TABLE IF NOT EXISTS MC2_PROJECTS (
	PROJECT_ID   COMMENT 'Project synID',
	PROJECT_NAME COMMENT 'Synapse project name'
)
	TARGET_LAG   = '7 days'
	REFRESH_MODE = AUTO
	INITIALIZE   = ON_SCHEDULE
	WAREHOUSE    = COMPUTE_XSMALL
	COMMENT      = 'List of project IDs associated with MC2 Center (scoped by syn69808225). This table will be used as the "anchor" for the dashboard.

Note: this table updates weekly'
	AS
	WITH
		flattened_scopes AS (
			SELECT
				scope_ids.value::integer AS synid
			FROM
				synapse_data_warehouse.synapse.node_latest AS nodes,
				LATERAL FLATTEN(input => nodes.scope_ids) AS scope_ids
			WHERE
				nodes.id = 69808225   -- MC2_All_Projects
		)
	SELECT
		fs.synid AS project_id,
		nodes2.name AS project_name
	FROM
		flattened_scopes AS fs
	INNER JOIN
		synapse_data_warehouse.synapse.node_latest AS nodes2
		ON fs.synid = nodes2.id
	WHERE
		nodes2.node_type = 'project';

-- 2. Dynamic table: MC2 Center nodes (downstream; refreshes against MC2_PROJECTS)
CREATE DYNAMIC TABLE IF NOT EXISTS MC2_NODES (
	ID               COMMENT 'Unique ID for the entity (like synID without the "syn" prefix)',
	NAME             COMMENT 'Name of the entity on Synapse',
	NODE_TYPE        COMMENT 'Type of Synapse entity (file, folder, project)',
	FILE_HANDLE_ID   COMMENT 'Unique identifier to the file stored on the cloud (`null` if not a file)',
	PARENT_ID        COMMENT 'ID of the immediate parent container (folder or project, can be the same as `PROJECT_ID`)',
	PROJECT_ID       COMMENT 'ID of the top-level project containing the entity',
	PROJECT_NAME     COMMENT 'Human-readable name of the MC2 Center project',
	CREATED_BY       COMMENT 'User ID of the original uploader',
	MODIFIED_BY      COMMENT 'User ID who created this specific version',
	CHANGE_TYPE      COMMENT 'Type of change (CREATE, UPDATE, DELETE)',
	CHANGE_TIMESTAMP COMMENT 'Datetime of change',
	IS_PUBLIC        COMMENT 'boolean: TRUE if the file is accessible by the "All Registered Synapse Users" group',
	IS_CONTROLLED    COMMENT 'boolean: TRUE if the file requires an approved Data Access Request (ACT)',
	IS_RESTRICTED    COMMENT 'boolean: TRUE if the file has specific Terms of Use or clickwrap restrictions',
	ANNOTATIONS      COMMENT 'JSON object containing custom metadata for the entity'
)
	TARGET_LAG   = '7 days'
	REFRESH_MODE = AUTO
	INITIALIZE   = ON_SCHEDULE
	WAREHOUSE    = COMPUTE_XSMALL
	COMMENT      = 'This dynamic table derives from `synapse_data_warehouse.synapse.node_latest` and contains the latest snapshot of Synapse nodes across the MC2 Center projects.

Note: this table updates in sync with its upstream table'
	AS
		SELECT
			nodes.id,
			nodes.name,
			nodes.node_type,
			nodes.file_handle_id,
			nodes.parent_id,
			mc2.project_id,
			mc2.project_name,
			nodes.created_by,
			nodes.modified_by,
			nodes.change_type,
			nodes.change_timestamp,
			nodes.is_public,
			nodes.is_controlled,
			nodes.is_restricted,
			nodes.annotations
		FROM
			synapse_data_warehouse.synapse.node_latest AS nodes
		JOIN
			sage.cckp.mc2_projects AS mc2
			ON nodes.project_id = mc2.project_id;
