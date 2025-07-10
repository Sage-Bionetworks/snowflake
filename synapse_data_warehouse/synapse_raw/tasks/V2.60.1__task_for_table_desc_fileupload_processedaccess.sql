use database {{database_name}}; --noqa: JJ01,PRS,TMP

-- Step 1) Pause the upstream tasks
alter task synapse_raw.refresh_synapse_warehouse_s3_stage_task suspend;
alter task synapse_raw.clone_fileupload_task suspend;
alter task synapse_raw.clone_process_access_task suspend;

-- Step 2) Create the tasks of interest
---- Task to alter fileupload table comment
create or replace task synapse_raw.alter_fileupload_comment_task
  after synapse_raw.clone_fileupload_task
as
  alter table synapse.fileupload
  set comment =
  '[DEPRECATION NOTICE] This table is being deprecated, and therefore is no longer actively updated. It will be replaced by ``synapse_event.fileupload_event`` in the near future. Please transition any dependencies accordingly.
  
  This table contains upload records for FileEntity (e.g. a new file creation, upload or update to an existing file) and TableEntity (e.g. an appended row set to an existing table, uploaded file to an existing table). The events are recorded only after the file or change to a table is successfully uploaded.';

---- Task to alter processedaccess table comment
create or replace task synapse_raw.alter_processedaccess_comment_task
  after synapse_raw.clone_process_access_task
as
  alter table synapse.processedaccess
  set comment =
  '[DEPRECATION NOTICE] This table is being deprecated, and therefore is no longer actively updated. It will be replaced by ``synapse_event.access_event`` in the near future. Please transition any dependencies accordingly.
  
  The table contains access records. Each record reflects a single API request received by the Synapse server. The recorded data is useful for audits and to analyse API performance such as delays, errors or success rates.';

-- Step 3) Resume the parent tasks + the tasks of interest
alter task synapse_raw.refresh_synapse_warehouse_s3_stage_task resume;
alter task synapse_raw.clone_fileupload_task resume;
alter task synapse_raw.clone_process_access_task resume;
alter task synapse_raw.alter_fileupload_comment_task resume;
alter task synapse_raw.alter_processedaccess_comment_task resume;