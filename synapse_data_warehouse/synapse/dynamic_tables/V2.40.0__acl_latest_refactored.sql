USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP


CREATE OR REPLACE DYNAMIC TABLE ACL_LATEST
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    AS 
    -- 1. Deduplicate the snapshots table based on each
    -- entry's OWNER_ID, and select only the last 14 days'
    -- worth of snapshots that have a non-empty RESOURCE_ACCESS column
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
        FROM {{ database_name }}.SYNAPSE_RAW.ACLSNAPSHOTS --noqa: TMP
        WHERE
            SNAPSHOT_DATE >= CURRENT_TIMESTAMP - INTERVAL '14 days'
        AND
            RESOURCE_ACCESS != '[]'
        QUALIFY
            ROW_NUMBER() OVER (
                PARTITION BY OWNER_ID
                ORDER BY CHANGE_TIMESTAMP DESC, SNAPSHOT_TIMESTAMP DESC
            ) = 1
            ),
    -- 2. Unpack each element within the RESOURCE_ACCESSS VARIANT, with each
    -- element being a JSON object describing privilege(s) assigned to a particular principal.
    dedup_acl_level1_unpack AS (
        SELECT
            CHANGE_TIMESTAMP,
            CHANGE_TYPE,
            CREATED_ON,
            OWNER_ID,
            OWNER_TYPE,
            SNAPSHOT_DATE,
            SNAPSHOT_TIMESTAMP,
            RESOURCE_ACCESS,
            flattened_resource_access.value AS ACL_ENTRY
        FROM 
            dedup_acl, 
            LATERAL FLATTEN(INPUT => PARSE_JSON(dedup_acl.RESOURCE_ACCESS)) AS flattened_resource_access
            ),
    -- 3. Unpacks each key-value pair in the JSON objects programmatically.
    -- The fields are: access type & principal ID, but are named differently in each entry, so we
    -- extract them programmatically using case-insensitive ILIKE and wildcards (%) in the string.
    dedup_acl_level2_unpack AS (
        SELECT
            CHANGE_TIMESTAMP,
            CHANGE_TYPE,
            CREATED_ON,
            OWNER_ID,
            OWNER_TYPE,
            SNAPSHOT_DATE,
            SNAPSHOT_TIMESTAMP,
            ARRAY_SORT(MAX(
                CASE 
                    WHEN key ILIKE '%access%' THEN value::variant
                END
            )) AS access_type, -- Grab the access type VARIANT programmatically regardless of field name
            MAX(
                CASE 
                    WHEN key ILIKE '%principal%' THEN value::number
                END
            ) AS principal_id -- Grab the principal ID NUMBER programmatically regardless of field name
        FROM 
            dedup_acl_level1_unpack,
            LATERAL FLATTEN(INPUT => ACL_ENTRY)
        GROUP BY
            CHANGE_TIMESTAMP,
            CHANGE_TYPE,
            CREATED_ON,
            OWNER_ID,
            OWNER_TYPE,
            SNAPSHOT_DATE,
            SNAPSHOT_TIMESTAMP,
            ACL_ENTRY -- This is how we make sure the access types go with the right principal IDs (1 ACL entry per access type & pid pair)
            )
    SELECT *
    FROM dedup_acl_level2_unpack;
