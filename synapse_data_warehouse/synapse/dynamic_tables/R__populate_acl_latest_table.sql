-- 1. Initialize the schema that the dynamic table will live under
USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP,CP01

-- 2. Create the dynamic table ACL_LATEST to be refreshed every 1 day(s)
CREATE OR REPLACE DYNAMIC TABLE ACL_LATEST
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    AS
    -- 3. Create the first CTE which unpacks the resource_access column
    --    and extracts the access type and principal ID as new columns
    WITH
    acl_expanded as (
        SELECT
            owner_id,
            change_timestamp,
            COALESCE(
                array_sort(value:"accesstype"::variant),
                array_sort(value:"accessType"::variant),
                array_sort(value:"accesstype#1"::variant),
                array_sort(value:"accesstype#2"::variant),
                array_sort(value:"accesstype#3"::variant)
            ) AS access_type,
            COALESCE(
                value:"principalId"::number,
                value:"principalid"::number,
                value:"principalid#1"::number
            ) AS principal_id
        FROM 
            {{database_name}}.synapse_raw.aclsnapshots,  --noqa: TMP
            LATERAL FLATTEN(input => parse_json(resource_access), outer => TRUE)
    ),
    -- 4. Create the second CTE which deduplicates the data from the CTE output
    --    in the previous step based on owner_id, access_type, and principal_id
    dedup_acl_expanded AS (
        SELECT
            owner_id, 
            change_timestamp, 
            access_type, 
            principal_id,
            ROW_NUMBER() OVER (
                PARTITION BY owner_id, access_type, principal_id
                ORDER BY change_timestamp DESC
            ) AS row_num
        FROM
            acl_expanded_temp
        QUALIFY row_num = 1
    )
    -- 5. Select the data from the CTE output in step 4.
    SELECT
        owner_id,
        change_timestamp,
        access_type,
        principal_id
    FROM
        dedup_acl_expanded;
