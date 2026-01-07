USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

create or replace dynamic table USERPROFILE_LATEST(
	CHANGE_TYPE COMMENT 'The type of change that occurred to the user profile, e.g., CREATE, UPDATE (Snapshotting does not capture DELETE change).',
	CHANGE_TIMESTAMP COMMENT 'The time when any change to the user profile was made (e.g. create or update).',
	CHANGE_USER_ID COMMENT 'The unique identifier of the user who made the change to the user profile.',
	SNAPSHOT_TIMESTAMP COMMENT 'The time when the snapshot was taken (It is usually after the change happened).',
	ID COMMENT 'The unique identifier of the user.',
	USER_NAME COMMENT 'The Synapse username.',
	FIRST_NAME COMMENT 'The first name of the user.',
	LAST_NAME COMMENT 'The last name of the user.',
	EMAIL COMMENT 'The primary email of the user.',
	SNAPSHOT_DATE COMMENT 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.',
	CREATED_ON COMMENT 'The creation time of the user profile.',
	IS_TWO_FACTOR_AUTH_ENABLED COMMENT 'Indicates if the user had two factor authentication enabled when the snapshot was captured.',
	TOS_AGREEMENTS COMMENT 'Contains the list of all the term of service that the user agreed to, with their agreed on date and version.',
	LOCATION COMMENT 'The location of the user.',
	COMPANY COMMENT 'The company where the user works.',
	POSITION COMMENT 'The position of the user in the company.',
	INDUSTRY COMMENT 'The industry/discipline that this person is associated with.'
) target_lag = '1 day' refresh_mode = AUTO initialize = ON_CREATE warehouse = COMPUTE_XSMALL
 COMMENT='This dynamic table, indexed by the ID column, contains the most recent snapshot of user profiles. Since snapshotting does not capture DELETE events, records may still be retained if a user was deleted within the past 14 days.'
 as 
    WITH dedup_userprofile AS (
        SELECT
            *
        FROM {{database_name}}.SYNAPSE_RAW.USERPROFILESNAPSHOT --noqa: TMP
        WHERE
            SNAPSHOT_DATE >= CURRENT_DATE - INTERVAL '30 days'
        QUALIFY
            ROW_NUMBER() OVER (
                PARTITION BY ID
                ORDER BY CHANGE_TIMESTAMP DESC, SNAPSHOT_TIMESTAMP DESC
            ) = 1
    )
    SELECT 
        * exclude (LOCATION, COMPANY, POSITION, INDUSTRY), 
        -- TODO: Need to revisit this section after the mixture of NULL and empty strings issue being resolved in https://sagebionetworks.jira.com/browse/SWC-7215
        NULLIF(LOCATION, '') AS LOCATION, 
        NULLIF(COMPANY, '') AS COMPANY, 
        NULLIF(POSITION, '') AS POSITION, 
        NULLIF(INDUSTRY, '') AS INDUSTRY, 
    FROM 
     dedup_userprofile;