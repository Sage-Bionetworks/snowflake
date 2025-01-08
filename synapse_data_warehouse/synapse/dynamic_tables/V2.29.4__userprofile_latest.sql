-- Introduce the dynamic table
USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP
CREATE OR REPLACE DYNAMIC TABLE USERPROFILE_LATEST
(
	CHANGE_TYPE VARCHAR(16777216) COMMENT 'The type of change that occurred to the user profile, e.g., CREATE, UPDATE (Snapshotting does not capture DELETE change).',
	CHANGE_TIMESTAMP TIMESTAMP_NTZ(9) COMMENT 'The time when any change to the user profile was made (e.g. create or update).',
	CHANGE_USER_ID NUMBER(38,0) COMMENT 'The unique identifier of the user who made the change to the user profile.',
	SNAPSHOT_TIMESTAMP TIMESTAMP_NTZ(9) COMMENT 'The time when the snapshot was taken (It is usually after the change happened).',
	ID NUMBER(38,0) COMMENT 'The unique identifier of the user.',
	USER_NAME VARCHAR(16777216) COMMENT 'The Synapse username.',
	FIRST_NAME VARCHAR(16777216) COMMENT 'The first name of the user.',
	LAST_NAME VARCHAR(16777216) COMMENT 'The last name of the user.',
	EMAIL VARCHAR(16777216) COMMENT 'The primary email of the user.',
	SNAPSHOT_DATE DATE COMMENT 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.',
	CREATED_ON TIMESTAMP_NTZ(9) COMMENT 'The creation time of the user profile.',
	IS_TWO_FACTOR_AUTH_ENABLED BOOLEAN COMMENT 'Indicates if the user had two factor authentication enabled when the snapshot was captured.',
    TOS_AGREEMENTS VARIANT COMMENT 'Contains the list of all the term of service that the user agreed to, with their agreed on date and version.',
    LOCATION VARCHAR(16777216) COMMENT 'The location of the user.',
	COMPANY VARCHAR(16777216) COMMENT 'The company where the user works.',
	POSITION VARCHAR(16777216) COMMENT 'The position of the user in the company.',
	INDUSTRY VARCHAR(16777216) COMMENT 'The industry/discipline that this person is associated with.'
) 
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    COMMENT='This dynamic table contain the latest snapshot of user-profiles during the past 14 days. Snapshots are taken when user profiles are created or modified. Note: Snapshots are also taken periodically and independently of the changes. The snapshot_timestamp records when the snapshot was taken.'
    AS 
    WITH dedup_userprofile AS (
        SELECT
            *,
            "row_number"()
                OVER (
                    PARTITION BY ID
                    ORDER BY CHANGE_TIMESTAMP DESC, SNAPSHOT_TIMESTAMP DESC
                )
                AS N
        FROM {{database_name}}.SYNAPSE_RAW.USERPROFILESNAPSHOT --noqa: TMP
        WHERE
            SNAPSHOT_DATE >= CURRENT_TIMESTAMP - INTERVAL '14 days'
        QUALIFY
            N=1
    )
    SELECT 
        * exclude (N, LOCATION, COMPANY, POSITION, INDUSTRY), 
        NULLIF(LOCATION, '') AS LOCATION, 
        NULLIF(COMPANY, '') AS COMPANY, 
        NULLIF(POSITION, '') AS POSITION, 
        NULLIF(INDUSTRY, '') AS INDUSTRY, 
    FROM 
     dedup_userprofile;
