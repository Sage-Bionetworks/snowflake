USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP


CREATE OR REPLACE DYNAMIC TABLE ACL_LATEST
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    AS 
    WITH dedup_acl AS (
        SELECT
            CHANGE_TIMESTAMP,
            CHANGE_TYPE,
            CREATED_ON,
            OWNER_ID,
            OWNER_TYPE,
            SNAPSHOT_DATE,
            SNAPSHOT_TIMESTAMP,
            RESOURCE_ACCESS
        FROM {{database_name}}.SYNAPSE_RAW.ACLSNAPSHOTS --noqa: TMP
        WHERE
            SNAPSHOT_DATE >= CURRENT_TIMESTAMP - INTERVAL '14 days'
        AND
            RESOURCE_ACCESS != '[]'
        QUALIFY
            ROW_NUMBER() OVER (
                PARTITION BY OWNER_ID
                ORDER BY CHANGE_TIMESTAMP DESC, SNAPSHOT_TIMESTAMP DESC
            ) = 1
    )
    SELECT
        CHANGE_TIMESTAMP,
        CHANGE_TYPE,
        CREATED_ON,
        OWNER_ID,
        OWNER_TYPE,
        SNAPSHOT_DATE,
        SNAPSHOT_TIMESTAMP,
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
        dedup_acl,
        LATERAL FLATTEN(PARSE_JSON(RESOURCE_ACCESS));
