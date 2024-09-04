use schema {{database_name}}.synapse; --noqa: JJ01,PRS,TMP,CP01

CREATE OR REPLACE DYNAMIC TABLE ACL_LATEST
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    AS
        WITH acl_expanded AS (
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
                {{database_name}}.synapse_raw.aclsnapshots,
                LATERAL FLATTEN(input => parse_json(resource_access), outer => TRUE)
        ),
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
                acl_expanded
            QUALIFY row_num = 1
        )
        SELECT
            owner_id, 
            change_timestamp, 
            access_type, 
            principal_id
        FROM
            dedup_acl_expanded;
