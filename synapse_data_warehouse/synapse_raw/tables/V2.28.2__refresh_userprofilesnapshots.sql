-- Configure environment
USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP,CP02

-- Drop all records from this table but keep structure and permissions intact
TRUNCATE TABLE userprofilesnapshot;

-- 
COPY INTO
        userprofilesnapshot
FROM (
    SELECT
        $1:change_type as change_type,
        $1:change_timestamp as change_timestamp,
        $1:change_user_id as change_user_id,
        $1:snapshot_timestamp as snapshot_timestamp,
        $1:id as id,
        $1:user_name as user_name,
        $1:first_name as first_name,
        $1:last_name as last_name,
        $1:email as email,
        $1:location as location,
        $1:company as company,
        $1:position as position,
        NULLIF(
            REGEXP_REPLACE(
                metadata$filename,
                '.*userprofilesnapshots\/snapshot_date\=(.*)\/.*', '\\1'
            ),
            '__HIVE_DEFAULT_PARTITION__'
        ) as snapshot_date,
        $1:created_on as created_on,
        $1:is_two_factor_auth_enabled as is_two_factor_auth_enabled,
        $1:industry as industry,
        $1:tos_agreements as tos_agreements
    from
        @{{stage_storage_integration}}/userprofilesnapshots --noqa: TMP
)
pattern = '.*userprofilesnapshots/snapshot_date=.*/.*';
