USE SCHEMA {{database_name}}.RDS_LANDING; --noqa: JJ01,PRS,TMP

-- access_approval
CREATE TABLE IF NOT EXISTS lan_synapse_access_approval
USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(
        INFER_SCHEMA(
            LOCATION => '@{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE/rds-snapshot/prod-589-db-2026-05-19/prod589.ACCESS_APPROVAL/1/',
            FILE_FORMAT => '{{database_name}}.RDS_LANDING.parquet_ff'
        )
    )
);

-- acl
CREATE TABLE IF NOT EXISTS lan_synapse_acl
USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(
        INFER_SCHEMA(
            LOCATION => '@{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE/rds-snapshot/prod-589-db-2026-05-19/prod589.ACL/1/',
            FILE_FORMAT => '{{database_name}}.RDS_LANDING.parquet_ff'
        )
    )
);

-- acl_resource_access
CREATE TABLE IF NOT EXISTS lan_synapse_acl_resource_access
USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(
        INFER_SCHEMA(
            LOCATION => '@{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE/rds-snapshot/prod-589-db-2026-05-19/prod589.ACL_RESOURCE_ACCESS/1/',
            FILE_FORMAT => '{{database_name}}.RDS_LANDING.parquet_ff'
        )
    )
);

-- acl_resource_access_type
CREATE TABLE IF NOT EXISTS lan_synapse_acl_resource_access_type
USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(
        INFER_SCHEMA(
            LOCATION => '@{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE/rds-snapshot/prod-589-db-2026-05-19/prod589.ACL_RESOURCE_ACCESS_TYPE/1/',
            FILE_FORMAT => '{{database_name}}.RDS_LANDING.parquet_ff'
        )
    )
);

-- data_access_submission
CREATE TABLE IF NOT EXISTS lan_synapse_data_access_submission
USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(
        INFER_SCHEMA(
            LOCATION => '@{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE/rds-snapshot/prod-589-db-2026-05-19/prod589.DATA_ACCESS_SUBMISSION/1/',
            FILE_FORMAT => '{{database_name}}.RDS_LANDING.parquet_ff'
        )
    )
);

-- data_access_submission_accessor_change
CREATE TABLE IF NOT EXISTS lan_synapse_data_access_submission_accessor_change
USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(
        INFER_SCHEMA(
            LOCATION => '@{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE/rds-snapshot/prod-589-db-2026-05-19/prod589.DATA_ACCESS_SUBMISSION_ACCESSOR_CHANGE/1/',
            FILE_FORMAT => '{{database_name}}.RDS_LANDING.parquet_ff'
        )
    )
);

-- data_access_submission_status
CREATE TABLE IF NOT EXISTS lan_synapse_data_access_submission_status
USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(
        INFER_SCHEMA(
            LOCATION => '@{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE/rds-snapshot/prod-589-db-2026-05-19/prod589.DATA_ACCESS_SUBMISSION_STATUS/1/',
            FILE_FORMAT => '{{database_name}}.RDS_LANDING.parquet_ff'
        )
    )
);

-- data_access_submission_submitter
CREATE TABLE IF NOT EXISTS lan_synapse_data_access_submission_submitter
USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(
        INFER_SCHEMA(
            LOCATION => '@{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE/rds-snapshot/prod-589-db-2026-05-19/prod589.DATA_ACCESS_SUBMISSION_SUBMITTER/1/',
            FILE_FORMAT => '{{database_name}}.RDS_LANDING.parquet_ff'
        )
    )
);

-- data_access_request
CREATE TABLE IF NOT EXISTS lan_synapse_data_access_request
USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(
        INFER_SCHEMA(
            LOCATION => '@{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE/rds-snapshot/prod-589-db-2026-05-19/prod589.DATA_ACCESS_REQUEST/1/',
            FILE_FORMAT => '{{database_name}}.RDS_LANDING.parquet_ff'
        )
    )
);

-- access_requirement
CREATE TABLE IF NOT EXISTS lan_synapse_access_requirement
USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(
        INFER_SCHEMA(
            LOCATION => '@{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE/rds-snapshot/prod-589-db-2026-05-19/prod589.ACCESS_REQUIREMENT/1/',
            FILE_FORMAT => '{{database_name}}.RDS_LANDING.parquet_ff'
        )
    )
);

-- access_requirement_project
CREATE TABLE IF NOT EXISTS lan_synapse_access_requirement_project
USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(
        INFER_SCHEMA(
            LOCATION => '@{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE/rds-snapshot/prod-589-db-2026-05-19/prod589.ACCESS_REQUIREMENT_PROJECT/1/',
            FILE_FORMAT => '{{database_name}}.RDS_LANDING.parquet_ff'
        )
    )
);

-- access_requirement_revision
CREATE TABLE IF NOT EXISTS lan_synapse_access_requirement_revision
USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(
        INFER_SCHEMA(
            LOCATION => '@{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE/rds-snapshot/prod-589-db-2026-05-19/prod589.ACCESS_REQUIREMENT_REVISION/1/',
            FILE_FORMAT => '{{database_name}}.RDS_LANDING.parquet_ff'
        )
    )
);

-- data_access_notification
CREATE TABLE IF NOT EXISTS lan_synapse_data_access_notification
USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(
        INFER_SCHEMA(
            LOCATION => '@{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE/rds-snapshot/prod-589-db-2026-05-19/prod589.DATA_ACCESS_NOTIFICATION/1/',
            FILE_FORMAT => '{{database_name}}.RDS_LANDING.parquet_ff'
        )
    )
);

-- principal_alias
CREATE TABLE IF NOT EXISTS lan_synapse_principal_alias
USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(
        INFER_SCHEMA(
            LOCATION => '@{{database_name}}.RDS_LANDING.RDS_SNAPSHOTS_STAGE/rds-snapshot/prod-589-db-2026-05-19/prod589.PRINCIPAL_ALIAS/1/',
            FILE_FORMAT => '{{database_name}}.RDS_LANDING.parquet_ff'
        )
    )
);