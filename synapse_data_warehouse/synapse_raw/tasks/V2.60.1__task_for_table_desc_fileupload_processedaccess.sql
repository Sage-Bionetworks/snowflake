USE DATABASE {{database_name}};  -- noqa: JJ01,PRS,TMP

-- Step 1) Pause the entire task tree
ALTER TASK synapse_raw.refresh_synapse_warehouse_s3_stage_task SUSPEND;
ALTER TASK synapse_raw.fileupload_task SUSPEND;
ALTER TASK synapse_raw.processedaccess_task SUSPEND;
ALTER TASK synapse_raw.clone_fileupload_task SUSPEND;
ALTER TASK synapse_raw.clone_process_access_task SUSPEND;

-- Step 2) Add deprecation notice to clone_fileupload_task
CREATE OR REPLACE TASK synapse_raw.clone_fileupload_task
  AFTER synapse_raw.fileupload_task
AS
BEGIN
    CREATE OR REPLACE TABLE synapse.fileupload
        CLONE synapse_raw.fileupload;
    
    ALTER TABLE synapse.fileupload
        SET COMMENT = '[DEPRECATION NOTICE] This table is being deprecated, and therefore is no longer actively updated. It will be replaced by ``synapse_event.fileupload_event`` in the near future. Please transition any dependencies accordingly.

                        This table contains upload records for FileEntity (e.g. a new file creation, upload or update to an existing file) and TableEntity (e.g. an appended row set to an existing table, uploaded file to an existing table). The events are recorded only after the file or change to a table is successfully uploaded.';
END;

-- Step 3) Add deprecation notice to clone_process_access_task
CREATE OR REPLACE TASK synapse_raw.clone_process_access_task
  AFTER synapse_raw.processedaccess_task
AS
BEGIN
    CREATE OR REPLACE TABLE synapse.processedaccess
        CLONE synapse_raw.processedaccess;
    
    ALTER TABLE synapse.processedaccess
        SET COMMENT = '[DEPRECATION NOTICE] This table is being deprecated, and therefore is no longer actively updated. It will be replaced by ``synapse_event.access_event`` in the near future. Please transition any dependencies accordingly.

                       The table contains access records. Each record reflects a single API request received by the Synapse server. The recorded data is useful for audits and to analyse API performance such as delays, errors or success rates.';
END;

-- Step 4) Resume everything
ALTER TASK synapse_raw.clone_process_access_task RESUME;
ALTER TASK synapse_raw.clone_fileupload_task RESUME;
ALTER TASK synapse_raw.processedaccess_task RESUME;
ALTER TASK synapse_raw.fileupload_task RESUME;
ALTER TASK synapse_raw.refresh_synapse_warehouse_s3_stage_task RESUME;

-- Step 5) Manually execute the root task to ensure the table comment gets updated accordingly...
EXECUTE TASK synapse_raw.refresh_synapse_warehouse_s3_stage_task;