use schema {{database_name}}.synapse; --noqa: JJ01,PRS,TMP,CP01

CREATE OR REPLACE DYNAMIC TABLE USERGROUP_LATEST
    TARGET_LAG = DOWNSTREAM
    WAREHOUSE = compute_xsmall
    AS
        WITH dedup_usergroup AS (
            SELECT
                *,
                "row_number"()
                    OVER (
                        PARTITION BY ID
                        ORDER BY CHANGE_TIMESTAMP DESC, SNAPSHOT_TIMESTAMP DESC
                    )
                    AS N
            FROM SYNAPSE_DATA_WAREHOUSE_DanLu_STAGE.SYNAPSE_RAW.USERGROUPSNAPSHOTS --noqa: TMP
            QUALIFY
                N=1
        )
        SELECT * EXCLUDE N
        FROM dedup_usergroup;
