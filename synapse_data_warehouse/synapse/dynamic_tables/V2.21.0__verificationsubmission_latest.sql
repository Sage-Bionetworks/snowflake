use schema {{database_name}}.synapse; --noqa: JJ01,PRS,TMP,CP01

CREATE OR REPLACE DYNAMIC TABLE VERIFICATIONSUBMISSION_LATEST
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    AS
    WITH latest_rows AS (
        SELECT
            verificationsubmissionsnapshots.id AS the_id,
            MAX(snapshot_timestamp) AS latest_timestamp
        FROM
            verificationsubmissionsnapshots
        GROUP BY
            verificationsubmissionsnapshots.id
    ),
    latest_unique_rows AS (
        SELECT
            verificationsubmissionsnapshots.*,
            ROW_NUMBER() OVER (
                PARTITION BY snapshot_timestamp
                ORDER BY snapshot_timestamp DESC
            ) AS row_num
        FROM
            verificationsubmissionsnapshots
        JOIN
            latest_rows
        ON
            verificationsubmissionsnapshots.id = latest_rows.the_id
            AND verificationsubmissionsnapshots.snapshot_timestamp = latest_rows.latest_timestamp
    )
    SELECT
        *
    FROM
        latest_unique_rows
    WHERE
        row_num = 1
    ORDER BY
        latest_unique_rows.id;
