use schema {{database_name}}.synapse; --noqa: JJ01,PRS,TMP,CP01

CREATE DYNAMIC TABLE IF NOT EXISTS ACCESSREQUIREMENT_LATEST
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    AS
        WITH latest_unique_rows AS (
            SELECT
                *
            FROM
                {{database_name}}.synapse_raw.accessrequirementsnapshots --noqa: TMP
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
        WHERE
            CHANGE_TYPE != 'DELETE'
        ORDER BY
            latest_unique_rows.id ASC;