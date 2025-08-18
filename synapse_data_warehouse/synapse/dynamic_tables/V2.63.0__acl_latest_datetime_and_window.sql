USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

create or replace dynamic table ACL_LATEST(
	CHANGE_TIMESTAMP COMMENT 'The timestamp when the change (created/updated) on an access control list was pushed to the queue for snapshotting.',
	CHANGE_TYPE COMMENT 'The type of change that occurred on the access control list, e.g., CREATE, UPDATE.',
	CREATED_ON COMMENT 'The original creation timestamp of the access control list. This represents when the ACL was first created in Synapse.',
	OWNER_ID COMMENT 'The unique identifier of the Synapse object to which the access control list is applied.',
	OWNER_TYPE COMMENT 'The type of the Synapse object that the access control list is affecting, e.g., ENTITY, FILE, SUBMISSION, MESSAGE, TEAM.',
	SNAPSHOT_DATE COMMENT 'The date when the snapshot was taken, used for data partitioning. This field is derived from SNAPSHOT_TIMESTAMP and should be used in WHERE clauses for efficient querying.',
	SNAPSHOT_TIMESTAMP COMMENT 'The timestamp when the snapshot was taken. This is usually after the change happened and represents when the ACL state was captured.',
	ACCESS_TYPE COMMENT 'The specific type of access permission granted to the principal. This is extracted from the RESOURCE_ACCESS JSON and represents what actions the principal can perform on the object (e.g., READ, UPDATE, DELETE, ADMIN).',
	PRINCIPAL_ID COMMENT 'The unique identifier of the principal (user or team) that has been granted the specified access type on the object. This is extracted from the RESOURCE_ACCESS JSON and represents who has the permission.'
) target_lag = '1 day' refresh_mode = AUTO initialize = ON_CREATE warehouse = COMPUTE_XSMALL
 COMMENT='This dynamic table, indexed by OWNER_ID, contains the latest snapshot of access control lists (ACLs) for Synapse objects. It is derived from ACLSNAPSHOTS raw data and provides deduplicated, flattened access control information. The table is refreshed daily and contains only the most recent ACL entries for each owner_id from the past 14 days. Each row represents a specific access permission granted to a principal (user or team) on a Synapse object.'
 as 
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
        FROM {{database_name}}.SYNAPSE_RAW.ACLSNAPSHOTS --noqa: TMP
        WHERE
            SNAPSHOT_DATE >= CURRENT_DATE - INTERVAL '14 days'
        AND
            RESOURCE_ACCESS != '[]' -- An empty RESOURCE_ACCESS means no ACL was captured for the owner_id
        QUALIFY
            ROW_NUMBER() OVER (
                PARTITION BY OWNER_ID, OWNER_TYPE
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