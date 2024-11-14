use schema {{database_name}}.synapse; --noqa: JJ01,PRS,TMP,CP01

CREATE DYNAMIC TABLE IF NOT EXISTS dynamic_city_table
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    REFRESH_MODE = INCREMENTAL
    AS
    SELECT 
        CITY,
        CURRENT_TIMESTAMP AS processing_time
    FROM 
        {{database_name}}.synapse_raw.experimental; --noqa: TMP
