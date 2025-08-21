USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

create or replace dynamic table TEAMMEMBER_LATEST(
	CHANGE_TYPE COMMENT 'The type of change that occurred to the member of team, e.g., CREATE, UPDATE (Snapshotting does not capture DELETE change).',
	CHANGE_TIMESTAMP COMMENT 'The time when any change to the team was made (e.g. update of the team or a change to its members).',
	CHANGE_USER_ID COMMENT 'The unique identifier of the user who made the change to the team member.',
	SNAPSHOT_TIMESTAMP COMMENT 'The time when the snapshot was taken (It is usually after the change happened).',
	TEAM_ID COMMENT 'The unique identifier of the team.',
	MEMBER_ID COMMENT 'The unique identifier of the member of the team. The member is a Synapse user.',
	IS_ADMIN COMMENT 'If true, then the member is manager of the team.',
	SNAPSHOT_DATE COMMENT 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.'
) target_lag = '1 day' refresh_mode = AUTO initialize = ON_CREATE warehouse = COMPUTE_XSMALL
 COMMENT='This dynamic table, indexed by the TEAM_ID and MEMBER_ID columns, contains the most recent snapshot of team members. Since snapshotting does not capture DELETE events, records may still be retained if a team member was deleted within the past 14 days.'
 as 
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
            SNAPSHOT_DATE >= CURRENT_DATE - INTERVAL '14 days'
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