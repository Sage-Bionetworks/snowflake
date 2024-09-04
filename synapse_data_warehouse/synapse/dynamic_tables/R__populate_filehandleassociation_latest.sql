use schema {{database_name}}.synapse; --noqa: JJ01,PRS,TMP,CP01

CREATE OR REPLACE DYNAMIC TABLE filehandleassociation_latest
TARGET_LAG = '7 days'
WAREHOUSE = compute_xsmall
AS
    WITH latest_filehandleassociations AS (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY filehandleid, associateid 
                ORDER BY timestamp DESC
            ) AS row_num
        FROM
            synapse_data_warehouse_jmedina.synapse_raw.filehandleassociationsnapshots
        WHERE
            timestamp >= CURRENT_TIMESTAMP - INTERVAL '14 DAYS'
        QUALIFY
            row_num = 1
    )
    SELECT
        *
    FROM
        latest_filehandleassociations;