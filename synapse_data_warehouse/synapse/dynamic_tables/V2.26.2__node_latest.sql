USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

CREATE DYNAMIC TABLE IF NOT EXISTS NODE_LATEST
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    AS
        WITH latest_unique_rows AS (
            SELECT
                *
            FROM
                {{database_name}}.synapse_raw.nodesnapshots --noqa: TMP
            WHERE
                SNAPSHOT_TIMESTAMP >= CURRENT_TIMESTAMP - INTERVAL '14 DAYS'
            QUALIFY ROW_NUMBER() OVER (
                    PARTITION BY id
                    ORDER BY change_timestamp DESC, snapshot_timestamp DESC
                ) = 1
        ),
        processed_latest_unique_rows AS (
            SELECT
                * EXCLUDE (annotations, reference),
                PARSE_JSON(annotations):annotations::OBJECT AS annotations,
                PARSE_JSON(annotations):etag::STRING AS etag,
                PARSE_JSON(reference):targetId::STRING as reference_target_id,
                PARSE_JSON(reference):targetVersionNumber::STRING as reference_target_version_number
            FROM
                latest_unique_rows
            WHERE
                CHANGE_TYPE != 'DELETE'
        )
        SELECT
            *
        FROM
            processed_latest_unique_rows
        ORDER BY
            processed_latest_unique_rows.id ASC;
