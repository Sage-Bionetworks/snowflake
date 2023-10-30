USE DATABASE {{database_name}};
CREATE STAGE IF NOT EXISTS {{stage_storage_integration}}_STAGE
    STORAGE_INTEGRATION = {{stage_storage_integration}}
    URL = '{{stage_url}}'
    FILE_FORMAT = (TYPE = PARQUET COMPRESSION = AUTO)
    DIRECTORY = (ENABLE = TRUE);
ALTER STAGE IF EXISTS {{stage_storage_integration}}_STAGE REFRESH;
