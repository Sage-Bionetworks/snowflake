use schema {{database_name}}.synapse; --noqa: JJ01,PRS,TMP,CP01

DROP TABLE IF EXISTS TEAM_LATEST;

CREATE OR REPLACE DYNAMIC TABLE TEAM_LATEST
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
