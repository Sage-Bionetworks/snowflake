USE ROLE ACCOUNTADMIN;

-- ============================================================
-- SYNAPSE_RAW stages
-- ============================================================

USE SCHEMA {{ database_name }}.SYNAPSE_RAW;

-- Main warehouse S3 stage for snapshot ingestion
CREATE STAGE IF NOT EXISTS {{ stage_storage_integration }}_stage
    STORAGE_INTEGRATION = {{ stage_storage_integration }}
    URL = '{{ stage_url }}'
    FILE_FORMAT = (TYPE = PARQUET COMPRESSION = AUTO)
    DIRECTORY = (ENABLE = TRUE);

-- Dedicated stage for file handle association records
CREATE STAGE IF NOT EXISTS synapse_filehandles_stage
    STORAGE_INTEGRATION = {{ stage_storage_integration }}
    URL = 's3://{{ stack }}.filehandles.sagebase.org/fileHandleAssociations/records/'
    FILE_FORMAT = (TYPE = PARQUET COMPRESSION = AUTO)
    DIRECTORY = (ENABLE = TRUE);

-- ============================================================
-- RDS_LANDING stages
-- ============================================================

USE SCHEMA {{ database_name }}.RDS_LANDING;

CREATE STAGE IF NOT EXISTS RDS_SNAPSHOTS_STAGE
    STORAGE_INTEGRATION = {{ snapshots_stage_storage_integration }}
    URL = '{{ snapshots_stage_url }}'
    FILE_FORMAT = (TYPE = PARQUET COMPRESSION = AUTO)
    DIRECTORY = (ENABLE = TRUE);
