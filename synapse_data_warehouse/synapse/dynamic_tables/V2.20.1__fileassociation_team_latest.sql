use schema {{database_name}}.synapse; --noqa: JJ01,PRS,TMP,CP01

DROP TABLE IF EXISTS TEAM_LATEST;

CREATE DYNAMIC TABLE IF NOT EXISTS TEAM_LATEST
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    AS
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
                (SNAPSHOT_DATE >= CURRENT_TIMESTAMP - INTERVAL '30 DAYS')
            QUALIFY
                N=1
        )
        
        SELECT * EXCLUDE N
        FROM RANKED_NODES;


CREATE DYNAMIC TABLE IF NOT EXISTS filehandleassociation_latest
    TARGET_LAG = '7 days'
    WAREHOUSE = compute_xsmall
AS
latest_unique_filehandles AS (
    SELECT
        filehandleid,
        max(timestamp) as latest_timestamp
    FROM
        {{database_name}}.synapse_raw.filehandleassociationsnapshots  --noqa: TMP
    WHERE
        timestamp >= CURRENT_TIMESTAMP - INTERVAL '14 DAYS'
    GROUP BY
        filehandleid
)
SELECT
    filehandleassociationsnapshots.*
FROM
    {{database_name}}.synapse_raw.filehandleassociationsnapshots  --noqa: TMP
JOIN
    latest_unique_filehandles
ON
    filehandleassociationsnapshots.filehandleid = latest_unique_filehandles.filehandleid
AND
    filehandleassociationsnapshots.timestamp = latest_unique_filehandles.latest_timestamp;