use schema {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

drop task if exists clone_fileupload_task;
drop task if exists clone_process_access_task;