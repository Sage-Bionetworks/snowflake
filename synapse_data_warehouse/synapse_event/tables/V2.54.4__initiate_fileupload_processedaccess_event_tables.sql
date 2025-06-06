use database {{database_name}}; --noqa: JJ01,PRS,TMP

-- Initialize the table that will then be updated by its task
create or replace table synapse_event.fileupload_event clone synapse_raw.fileupload;
create or replace table synapse_event.processedaccess_event clone synapse_raw.processedaccess;