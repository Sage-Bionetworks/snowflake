use schema {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP,CP01

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
            FROM synapse_data_warehouse_dev.SYNAPSE_RAW.TEAMSNAPSHOTS --noqa: TMP
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
    with latest_instance as (
        SELECT
            max(instance) as max_instance
        FROM
            synapse_data_warehouse.synapse_raw.filehandleassociationsnapshots
        where
            timestamp >= CURRENT_TIMESTAMP - INTERVAL '14 DAYS'
    )
    SELECT
        filehandleassociationsnapshots.*
    FROM
        synapse_data_warehouse.synapse_raw.filehandleassociationsnapshots
    inner JOIN
        latest_instance
        ON filehandleassociationsnapshots.instance = latest_instance.max_instance;
            where
            timestamp >= CURRENT_TIMESTAMP - INTERVAL '14 DAYS'
