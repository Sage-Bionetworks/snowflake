USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP
-- * Use window functions to get the latest information per snapshot table
CREATE TABLE IF NOT EXISTS CERTIFIEDQUIZQUESTION_LATEST AS
WITH CQQ_RANKED AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY RESPONSE_ID, QUESTION_INDEX
            ORDER BY IS_CORRECT DESC, INSTANCE DESC
        ) AS ROW_NUM
    FROM {{database_name}}.SYNAPSE_RAW.CERTIFIEDQUIZQUESTION --noqa: TMP
)

SELECT * EXCLUDE ROW_NUM
FROM CQQ_RANKED
WHERE ROW_NUM = 1
ORDER BY RESPONSE_ID DESC, QUESTION_INDEX ASC;

-- Create certified quiz latest
CREATE TABLE IF NOT EXISTS CERTIFIEDQUIZ_LATEST AS
WITH CQQ_RANKED AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY USER_ID
            ORDER BY INSTANCE DESC, RESPONSE_ID DESC
        ) AS ROW_NUM
    FROM {{database_name}}.SYNAPSE_RAW.CERTIFIEDQUIZ --noqa: TMP
)

SELECT * EXCLUDE ROW_NUM
FROM CQQ_RANKED
WHERE ROW_NUM = 1;

-- Create user profile latest
CREATE TABLE IF NOT EXISTS USERPROFILE_LATEST AS WITH
RANKED_NODES AS (
    SELECT
        *,
        "row_number"()
            OVER (
                PARTITION BY ID
                ORDER BY CHANGE_TIMESTAMP DESC, SNAPSHOT_TIMESTAMP DESC
            )
            AS N
    FROM
        {{database_name}}.SYNAPSE_RAW.USERPROFILESNAPSHOT --noqa: TMP
    WHERE
        (SNAPSHOT_DATE >= CURRENT_TIMESTAMP - INTERVAL '30 DAYS')
)

SELECT * EXCLUDE N
FROM RANKED_NODES
WHERE N = 1;
CREATE TABLE IF NOT EXISTS TEAMMEMBER_LATEST AS WITH
RANKED_NODES AS (
    SELECT
        *,
        "row_number"()
            OVER (
                PARTITION BY MEMBER_ID, TEAM_ID
                ORDER BY CHANGE_TIMESTAMP DESC, SNAPSHOT_TIMESTAMP DESC
            )
            AS N
    FROM
        {{database_name}}.SYNAPSE_RAW.TEAMMEMBERSNAPSHOTS --noqa: TMP
    WHERE
        (SNAPSHOT_DATE >= CURRENT_TIMESTAMP - INTERVAL '30 DAYS')
)

SELECT * EXCLUDE N
FROM RANKED_NODES
WHERE N = 1;

CREATE TABLE IF NOT EXISTS TEAM_LATEST AS WITH
RANKED_NODES AS (
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
        (SNAPSHOT_DATE >= CURRENT_TIMESTAMP - INTERVAL '30 DAYS')
)

SELECT * EXCLUDE N
FROM RANKED_NODES
WHERE N = 1;

-- filesnapshots
CREATE TABLE IF NOT EXISTS FILE_LATEST AS WITH
RANKED_NODES AS (
    SELECT
        *,
        "row_number"()
            OVER (
                PARTITION BY ID
                ORDER BY CHANGE_TIMESTAMP DESC, SNAPSHOT_TIMESTAMP DESC
            )
            AS N
    FROM {{database_name}}.SYNAPSE_RAW.FILESNAPSHOTS --noqa: TMP
    WHERE
        (SNAPSHOT_DATE >= CURRENT_TIMESTAMP - INTERVAL '30 DAYS')
        AND NOT IS_PREVIEW
        AND CHANGE_TYPE != 'DELETE'
)

SELECT * EXCLUDE N
FROM RANKED_NODES
WHERE N = 1;

-- node snapshot latest
CREATE TABLE IF NOT EXISTS NODE_LATEST AS WITH
RANKED_NODES AS (
    SELECT
        *,
        "row_number"()
            OVER (
                PARTITION BY ID
                ORDER BY CHANGE_TIMESTAMP DESC, SNAPSHOT_TIMESTAMP DESC
            )
            AS N
    FROM {{database_name}}.SYNAPSE_RAW.NODESNAPSHOTS --noqa: TMP
    WHERE
        (SNAPSHOT_DATE >= CURRENT_TIMESTAMP - INTERVAL '30 DAYS')
        AND CHANGE_TYPE != 'DELETE'
)

SELECT * EXCLUDE N
FROM RANKED_NODES
WHERE N = 1;

-- zero copy clone record tables.
CREATE OR REPLACE TABLE PROCESSEDACCESS
CLONE
{{database_name}}.SYNAPSE_RAW.PROCESSEDACCESS; --noqa: TMP

CREATE OR REPLACE TABLE FILEDOWNLOAD
CLONE
{{database_name}}.SYNAPSE_RAW.FILEDOWNLOAD; --noqa: TMP

CREATE OR REPLACE TABLE FILEUPLOAD
CLONE
{{database_name}}.SYNAPSE_RAW.FILEUPLOAD; --noqa: TMP
