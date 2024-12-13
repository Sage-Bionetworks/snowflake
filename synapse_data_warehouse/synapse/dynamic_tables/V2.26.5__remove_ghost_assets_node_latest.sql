USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE DYNAMIC TABLE NODE_LATEST
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    AS
        WITH latest_unique_rows AS (
            SELECT
                *
            FROM
                {{database_name}}.synapse_raw.nodesnapshots --noqa: TMP
            WHERE
                SNAPSHOT_TIMESTAMP >= CURRENT_TIMESTAMP - INTERVAL '30 DAYS'
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
            NOT (CHANGE_TYPE = 'DELETE' OR BENEFACTOR_ID = '1681355' OR PARENT_ID = '1681355') -- 1681355 is the synID of the trash can on Synapse
        ORDER BY
            latest_unique_rows.id ASC;
