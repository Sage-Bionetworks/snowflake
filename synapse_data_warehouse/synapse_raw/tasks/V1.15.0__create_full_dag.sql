use role accountadmin;
use schema {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- suspend all parent tasks first
alter task refresh_synapse_warehouse_s3_stage_task suspend;

-- unset schedule for child tasks
alter task certifiedquiz_task UNSET schedule;
alter task certifiedquiz_task ADD AFTER refresh_synapse_warehouse_s3_stage_task;

alter task certifiedquizquestion_task UNSET schedule;
alter task certifiedquizquestion_task AFTER refresh_synapse_warehouse_s3_stage_task;

alter task nodesnapshot_task UNSET schedule;
alter task nodesnapshot_task AFTER refresh_synapse_warehouse_s3_stage_task;

alter task filesnapshots_task UNSET schedule;
alter task filesnapshots_task AFTER refresh_synapse_warehouse_s3_stage_task;

alter task userprofilesnapshot_task UNSET schedule;
alter task userprofilesnapshot_task AFTER refresh_synapse_warehouse_s3_stage_task;

alter task teammembersnapshots_task UNSET schedule;
alter task teammembersnapshots_task AFTER refresh_synapse_warehouse_s3_stage_task;

alter task processedaccess_task UNSET schedule;
alter task processedaccess_task AFTER refresh_synapse_warehouse_s3_stage_task;

alter task filedownload_task UNSET schedule;
alter task filedownload_task AFTER refresh_synapse_warehouse_s3_stage_task;

alter task fileupload_task UNSET schedule;
alter task fileupload_task AFTER refresh_synapse_warehouse_s3_stage_task;

-- resume all tasks, from most downstream child to upstream parents
ALTER TASK remove_delete_nodes_task RESUME;
ALTER TASK remove_delete_files_task RESUME;
ALTER TASK upsert_to_certifiedquiz_latest_task RESUME;
ALTER TASK upsert_to_certifiedquizquestion_latest_task RESUME;
ALTER TASK upsert_to_node_latest_task RESUME;
ALTER TASK upsert_to_file_latest_task RESUME;
ALTER TASK upsert_to_userprofile_latest_task RESUME;
ALTER TASK upsert_to_teammember_latest_task RESUME;
ALTER TASK clone_process_access_task RESUME;
ALTER TASK clone_filedownload_task RESUME;
ALTER TASK clone_fileupload_task RESUME;
alter task certifiedquiz_task RESUME;
alter task certifiedquizquestion_task RESUME;
alter task nodesnapshot_task RESUME;
alter task filesnapshots_task RESUME;
alter task userprofilesnapshot_task RESUME;
alter task teammembersnapshots_task RESUME;
alter task processedaccess_task RESUME;
alter task filedownload_task RESUME;
alter task fileupload_task RESUME;
alter task refresh_synapse_warehouse_s3_stage_task RESUME;
