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
    WITH latest_unique_filehandles AS (
        SELECT
            filehandleid,
            associateid,
            max(timestamp) as latest_timestamp
        FROM
            synapse_data_warehouse_jmedina.synapse_raw.filehandleassociationsnapshots
        WHERE
            timestamp >= CURRENT_TIMESTAMP - INTERVAL '14 DAYS'
        GROUP BY
            filehandleid,
            associateid
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
        filehandleassociationsnapshots.associateid = latest_unique_filehandles.associateid
    AND
        filehandleassociationsnapshots.timestamp = latest_unique_filehandles.latest_timestamp;
