USE SCHEMA {{database_name}}.synapse_raw;  -- noqa: JJ01,PRS,TMP

-- Step 1) Pause the entire task tree
ALTER TASK refresh_synapse_warehouse_s3_stage_task SUSPEND;
ALTER TASK fileupload_task SUSPEND;
ALTER TASK processedaccess_task SUSPEND;
ALTER TASK clone_fileupload_task SUSPEND;
ALTER TASK clone_process_access_task SUSPEND;

-- Step 2) Add deprecation notice to clone_fileupload_task
CREATE OR REPLACE TASK clone_fileupload_task
  AFTER fileupload_task
AS
  EXECUTE IMMEDIATE $$
    CREATE OR REPLACE TABLE {{database_name}}.synapse.fileupload -- noqa: JJ01,PRS,TMP
      CLONE fileupload;
    
    ALTER TABLE {{database_name}}.synapse.fileupload -- noqa: JJ01,PRS,TMP
      SET COMMENT =
      '[DEPRECATION NOTICE] This table is being deprecated, and therefore is no longer actively updated. It will be replaced by ``synapse_event.fileupload_event`` in the near future. Please transition any dependencies accordingly.

      This table contains upload records for FileEntity (e.g. a new file creation, upload or update to an existing file) and TableEntity (e.g. an appended row set to an existing table, uploaded file to an existing table). The events are recorded only after the file or change to a table is successfully uploaded.';
  $$;

-- Step 3) Add deprecation notice to clone_process_access_task
CREATE OR REPLACE TASK clone_process_access_task
  AFTER processedaccess_task
AS
  EXECUTE IMMEDIATE $$
    CREATE OR REPLACE TABLE {{database_name}}.synapse.processedaccess -- noqa: JJ01,PRS,TMP
      CLONE processedaccess;
    
    ALTER TABLE {{database_name}}.synapse.processedaccess -- noqa: JJ01,PRS,TMP
      SET COMMENT =
      '[DEPRECATION NOTICE] This table is being deprecated, and therefore is no longer actively updated. It will be replaced by ``synapse_event.access_event`` in the near future. Please transition any dependencies accordingly.

      The table contains access records. Each record reflects a single API request received by the Synapse server. The recorded data is useful for audits and to analyse API performance such as delays, errors or success rates.';
  $$;

-- Step 4) Resume everything
ALTER TASK clone_process_access_task RESUME;
ALTER TASK clone_fileupload_task RESUME;
ALTER TASK processedaccess_task RESUME;
ALTER TASK fileupload_task RESUME;
ALTER TASK refresh_synapse_warehouse_s3_stage_task RESUME;