USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

create or replace dynamic table USERGROUP_LATEST(
	CHANGE_TYPE COMMENT 'The type of change that occurred to the user-group, e.g., CREATE, UPDATE.',
	CHANGE_TIMESTAMP COMMENT 'The time when the change (creation/update) to the user-group is pushed to the queue for snapshotting.',
	CHANGE_USER_ID COMMENT 'The unique identifier of the user who made the change to the user-group.',
	SNAPSHOT_TIMESTAMP COMMENT 'The time when the snapshot was taken (It is usually after the change happened).',
	ID COMMENT 'The unique identifier of user or group.',
	IS_INDIVIDUAL COMMENT 'If true, then this user group is an individual user not a team.',
	CREATED_ON COMMENT 'The creation time of the user or group.',
	SNAPSHOT_DATE COMMENT 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.'
) target_lag = '1 day' refresh_mode = AUTO initialize = ON_CREATE warehouse = COMPUTE_XSMALL
 COMMENT='This dynamic table, indexed by ID, contains the latest snapshot of Synapse principals (individual users and groups of users). It is derived from USERGROUPSNAPSHOTS raw data and provides deduplicated user group information. The table is refreshed daily and contains only the most recent entries for each ID from the past 14 days. Each row represents a specific principal (individual user or group) with its current state.'
 as
        WITH dedup_usergroup AS (
            SELECT
                *,
                "row_number"()
                    OVER (
                        PARTITION BY ID
                        ORDER BY CHANGE_TIMESTAMP DESC, SNAPSHOT_TIMESTAMP DESC
                    )
                    AS N
            FROM {{database_name}}.SYNAPSE_RAW.USERGROUPSNAPSHOTS --noqa: TMP
            WHERE 
                SNAPSHOT_DATE >= CURRENT_DATE - INTERVAL '14 days'
            QUALIFY
                N=1
        )
        SELECT * EXCLUDE N
        FROM dedup_usergroup;