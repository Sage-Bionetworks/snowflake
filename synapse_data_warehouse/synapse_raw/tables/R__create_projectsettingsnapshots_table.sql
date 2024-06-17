USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

CREATE OR ALTER TABLE PROJECTSETTINGSNAPSHOTS (
    CHANGE_TIMESTAMP TIMESTAMP COMMENT 'The time when the a project settings change (created/updated/deleted) occured.',
    CHANGE_TYPE VARCHAR(16777216) COMMENT 'The type of change that occurred on the access requirement, e.g., CREATE, UPDATE, DELETE.',
    CHANGE_USER_ID NUMBER(38,0) COMMENT 'The id of the user that created, updated or deleted the project settings being snapshotted.',
    SNAPSHOT_TIMESTAMP TIMESTAMP COMMENT 'The time when the snapshot was taken. Snapshots are taken after each change event and periodically.',
    ID NUMBER(38,0) COMMENT 'The unique identifier of the project setting.',
    CONCRETE_TYPE VARCHAR(16777216) COMMENT 'The type of project settings. See https://rest-docs.synapse.org/rest/org/sagebionetworks/repo/model/ProjectSettings.html.',
    PROJECT_ID NUMBER(38,0) COMMENT 'The ID of the project to which the settings apply.',
    SETTINGS_TYPE VARCHAR(16777216) COMMENT 'The short type of the project settings. See https://rest-docs.synapse.org/rest/org/sagebionetworks/repo/model/ProjectSettings.html.',
    ETAG VARCHAR(16777216) COMMENT 'UUID issued each time the project settings changes.',
    LOCATIONS ARRAY COMMENT 'The storage location IDs associated with the project setting.',
    SNAPSHOT_DATE DATE COMMENT 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.'
)
CLUSTER BY (SNAPSHOT_DATE)
COMMENT="This table contain snapshots of projects settings. Snapshots are taken when a project setting is created, updated or deleted. Note: Snapshots are also taken periodically and independently of the changes. The snapshot_timestamp records when the snapshot was taken."
;