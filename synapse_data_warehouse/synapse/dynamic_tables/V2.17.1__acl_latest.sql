use schema {{database_name}}.synapse; --noqa: JJ01,PRS,TMP,CP01

CREATE DYNAMIC TABLE IF NOT EXISTS ACL_LATEST
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    AS
        with de_dup_acl as (
            select
                owner_id,
                change_timestamp,
                parse_json(resource_access) as acl,
                ROW_NUMBER() OVER (
                    PARTITION BY OWNER_ID, CHANGE_TIMESTAMP
                    ORDER BY CHANGE_TIMESTAMP ASC
                ) AS ROW_NUM
            from
                {{database_name}}.synapse_raw.aclsnapshots  --noqa: TMP
            QUALIFY ROW_NUM = 1
        ), acl_expanded as (
            select
                owner_id,
                change_timestamp,
                value,
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
            from 
                de_dup_acl,
                LATERAL FLATTEN(acl, outer=>TRUE)
        )
        select
            owner_id, change_timestamp, access_type, principal_id
        from
            acl_expanded