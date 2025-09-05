USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

create or replace dynamic table PROJECTSETTING_LATEST(
	CHANGE_TIMESTAMP COMMENT 'The time when a project settings change (created/updated) occurred.',
	CHANGE_TYPE COMMENT 'The type of change that occurred on the project settings, e.g., CREATE, UPDATE, DELETE.',
	CHANGE_USER_ID COMMENT 'The id of the user that created, updated the project settings being snapshotted.',
	SNAPSHOT_TIMESTAMP COMMENT 'The time when the snapshot was taken. Snapshots are taken after each change event and periodically.',
	ID COMMENT 'The unique identifier of the project setting.',
	CONCRETE_TYPE COMMENT 'The type of project settings. See https://rest-docs.synapse.org/rest/org/sagebionetworks/repo/model/project/ProjectSetting.html.',
	PROJECT_ID COMMENT 'The ID of the project to which the settings apply.',
	SETTINGS_TYPE COMMENT 'The short type of the project settings. See https://rest-docs.synapse.org/rest/org/sagebionetworks/repo/model/project/ProjectSetting.html.',
	ETAG COMMENT 'UUID issued each time the project settings changes.',
	LOCATIONS COMMENT 'The storage location IDs associated with the project setting.',
	SNAPSHOT_DATE COMMENT 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.'
) target_lag = '1 day' refresh_mode = AUTO initialize = ON_CREATE warehouse = COMPUTE_XSMALL
 COMMENT='This dynamic table, indexed by ID, contains the latest snapshot of project settings for Synapse projects. It is derived from PROJECTSETTINGSNAPSHOTS raw data and provides deduplicated project settings information. The table is refreshed daily and contains only the most recent settings entries for each project ID from the past 14 days. Each row represents a specific project setting with its current configuration.'
 as
        WITH latest_unique_rows AS (
            SELECT
                *
            FROM
                {{database_name}}.synapse_raw.projectsettingsnapshots --noqa: TMP
            WHERE
                SNAPSHOT_DATE >= CURRENT_DATE - INTERVAL '14 DAYS'
            QUALIFY ROW_NUMBER() OVER (
                    PARTITION BY id
                    ORDER BY change_timestamp DESC, snapshot_timestamp DESC
                ) = 1
        )
        SELECT
            *
        FROM
            latest_unique_rows
        ORDER BY
            latest_unique_rows.id ASC;