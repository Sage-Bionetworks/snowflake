use schema {{database_name}}.synapse; --noqa: JJ01,PRS,TMP,CP01

CREATE OR REPLACE DYNAMIC TABLE filehandleassociation_latest
TARGET_LAG = '7 days'
WAREHOUSE = compute_xsmall
AS
    WITH latest_unique_filehandles AS (
        SELECT
            filehandleid,
            associateid,
            MAX(timestamp) AS latest_timestamp
        FROM
            {{database_name}}.synapse_raw.filehandleassociationsnapshots --noqa: TMP
        WHERE
            timestamp >= CURRENT_TIMESTAMP - INTERVAL '14 DAYS'
        GROUP BY
            filehandleid,
            associateid
    )
    SELECT
        filehandleassociationsnapshots.*
    FROM
        {{database_name}}.synapse_raw.filehandleassociationsnapshots --noqa: TMP
    JOIN
        latest_unique_filehandles
    ON
        filehandleassociationsnapshots.filehandleid = latest_unique_filehandles.filehandleid
    AND
        filehandleassociationsnapshots.timestamp = latest_unique_filehandles.latest_timestamp
    AND
        filehandleassociationsnapshots.associateid = latest_unique_filehandles.associateid;
