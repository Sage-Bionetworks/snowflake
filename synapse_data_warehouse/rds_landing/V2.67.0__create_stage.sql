USE SCHEMA {{database_name}}.RDS_LANDING;
CREATE STAGE IF NOT EXISTS {{snapshots_stage_storage_integration}}_STAGE
    STORAGE_INTEGRATION = {{snapshots_stage_storage_integration}}
    URL = '{{snapshots_stage_url}}'
    FILE_FORMAT = (TYPE = PARQUET COMPRESSION = AUTO)
    DIRECTORY = (ENABLE = TRUE);
ALTER STAGE IF EXISTS {{snapshots_stage_storage_integration}}_STAGE REFRESH;