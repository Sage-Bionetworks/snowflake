USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

CREATE DYNAMIC TABLE IF NOT EXISTS CERTIFIEDQUIZQUESTION_LATEST
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    AS
        WITH latest_unique_rows AS (
            SELECT
                *
            FROM
                {{database_name}}.synapse_raw.certifiedquizquestionsnapshots --noqa: TMP
            WHERE
                SNAPSHOT_TIMESTAMP >= CURRENT_TIMESTAMP - INTERVAL '14 DAYS'
            QUALIFY ROW_NUMBER() OVER (
                    PARTITION BY id
                    ORDER BY change_timestamp DESC, snapshot_timestamp DESC
                ) = 1
        )
        SELECT
            *
        FROM
            latest_unique_rows
        ORDER BY
            latest_unique_rows.id ASC;
