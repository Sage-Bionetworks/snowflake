USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

create or replace dynamic table TEAM_LATEST(
	CHANGE_TYPE COMMENT 'The type of change that occurred to the team, e.g., CREATE, UPDATE.',
	CHANGE_TIMESTAMP COMMENT 'The time when any change to the team was made (e.g. create, update or a change to its members).',
	CHANGE_USER_ID COMMENT 'The unique identifier of the user who made the change to the team.',
	SNAPSHOT_TIMESTAMP COMMENT 'The time when the snapshot was taken (It is usually after the change happened).',
	ID COMMENT 'The unique identifier of the team.',
	NAME COMMENT 'The name of the team.',
	CAN_PUBLIC_JOIN COMMENT 'If true, a user can join the team without approval of a team manager.',
	CREATED_ON COMMENT 'The creation time of the team.',
	CREATED_BY COMMENT 'The unique identifier of the user who created the team.',
	MODIFIED_ON COMMENT 'The time when the team was last modified.',
	MODIFIED_BY COMMENT 'The unique identifier of the user who last modified the team.',
	SNAPSHOT_DATE COMMENT 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.'
) target_lag = '1 day' refresh_mode = AUTO initialize = ON_CREATE warehouse = COMPUTE_XSMALL
 COMMENT='This dynamic table, indexed by ID, contains the latest snapshot of Synapse teams. It is derived from TEAMSNAPSHOTS raw data and provides deduplicated team information. The table is refreshed daily and contains only the most recent team entries for each ID from the past 30 days. Each row represents a specific team with its current state and membership configuration.'
 as
        WITH RANKED_NODES AS (
            SELECT
                *,
                "row_number"()
                    OVER (
                        PARTITION BY ID
                        ORDER BY CHANGE_TIMESTAMP DESC, SNAPSHOT_TIMESTAMP DESC
                    )
                    AS N
            FROM {{database_name}}.SYNAPSE_RAW.TEAMSNAPSHOTS --noqa: TMP
            WHERE
                SNAPSHOT_DATE >= CURRENT_DATE - INTERVAL '30 DAYS'
            QUALIFY
                N=1
        )
        SELECT * EXCLUDE N
        FROM RANKED_NODES;