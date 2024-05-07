USE SCHEMA {{database_name}}.synapse_raw;  --noqa: PRS,TMP
CREATE STAGE IF NOT EXISTS synapse_filehandles_stage
    STORAGE_INTEGRATION = {{stage_storage_integration}}  --noqa: TMP
    URL = 's3://{{stack}}.filehandles.sagebase.org/fileHandleAssociations/records/'  --noqa: TMP
    FILE_FORMAT = (TYPE = PARQUET COMPRESSION = AUTO)
    DIRECTORY = (ENABLE = TRUE);
ALTER STAGE IF EXISTS synapse_filehandles_stage REFRESH;
