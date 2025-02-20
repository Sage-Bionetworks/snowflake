-- Introduce the dynamic table
USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE DYNAMIC TABLE TEAMMEMBER_LATEST
    (
	    CHANGE_TYPE VARCHAR(16777216) COMMENT 'The type of change that occurred to the member of team, e.g., CREATE, UPDATE (Snapshotting does not capture DELETE change).',
	    CHANGE_TIMESTAMP TIMESTAMP_NTZ(9) COMMENT 'The time when any change to the team was made (e.g. update of the team or a change to its members).',
	    CHANGE_USER_ID NUMBER(38,0) COMMENT 'The unique identifier of the user who made the change to the team member.',
	    SNAPSHOT_TIMESTAMP TIMESTAMP_NTZ(9) COMMENT 'The time when the snapshot was taken (It is usually after the change happened).',
	    TEAM_ID NUMBER(38,0) COMMENT 'The unique identifier of the team.',
	    MEMBER_ID NUMBER(38,0) COMMENT 'The unique identifier of the member of the team. The member is a Synapse user.',
	    IS_ADMIN BOOLEAN COMMENT 'If true, then the member is manager of the team.',
	    SNAPSHOT_DATE DATE COMMENT 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.'
    )
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    COMMENT = 'This table contain snapshots of team-members during the past 14 days. Snapshots are captured when a team and/or its members are modified. Note: Snapshots are also taken periodically and independently of the changes. The snapshot_timestamp records when the snapshot was taken.'
    AS 
    WITH dedup_teammembers AS (
        SELECT
	    CHANGE_TYPE,
	    CHANGE_TIMESTAMP,
	    CHANGE_USER_ID, 
	    SNAPSHOT_TIMESTAMP, 
	    TEAM_ID, 
	    MEMBER_ID, 
	    IS_ADMIN, 
	    SNAPSHOT_DATE 
        FROM {{database_name}}.SYNAPSE_RAW.teammembersnapshots --noqa: TMP
        WHERE
            SNAPSHOT_DATE >= CURRENT_TIMESTAMP - INTERVAL '14 days'
        QUALIFY
            ROW_NUMBER() OVER (
                PARTITION BY TEAM_ID, MEMBER_ID
                ORDER BY CHANGE_TIMESTAMP DESC, SNAPSHOT_TIMESTAMP DESC
            ) = 1
    )
    SELECT 
	*
    FROM 
        dedup_teammembers;
