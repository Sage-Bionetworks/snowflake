use schema {{database_name}}.synapse; --noqa: JJ01,PRS,TMP,CP01

CREATE DYNAMIC TABLE IF NOT EXISTS VERIFICATIONSUBMISSION_LATEST
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    AS
    WITH latest_unique_rows AS (
        SELECT
            verificationsubmissionsnapshots.*,
        FROM
            {{database_name}}.synapse_raw.verificationsubmissionsnapshots --noqa: TMP
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
        latest_unique_rows.id ASC;
