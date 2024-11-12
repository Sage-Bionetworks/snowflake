use schema {{database_name}}.synapse; --noqa: JJ01,PRS,TMP,CP01

CREATE DYNAMIC TABLE IF NOT EXISTS VERIFICATIONSUBMISSION_LATEST
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    AS
    WITH latest_rows AS (
        SELECT
            id AS latest_id,
            MAX(snapshot_timestamp) AS latest_timestamp
        FROM
            verificationsubmissionsnapshots
        GROUP BY
            latest_id
    ),
    latest_unique_rows AS (
        SELECT
            verificationsubmissionsnapshots.*,
        FROM
            verificationsubmissionsnapshots
        JOIN
            latest_rows
        ON
            verificationsubmissionsnapshots.id = latest_rows.latest_id
            AND verificationsubmissionsnapshots.snapshot_timestamp = latest_rows.latest_timestamp
        QUALIFY ROW_NUMBER() OVER (
                PARTITION BY id
                ORDER BY snapshot_timestamp DESC
            ) = 1
    )
    SELECT
        *
    FROM
        latest_unique_rows
    ORDER BY
        latest_unique_rows.id;
