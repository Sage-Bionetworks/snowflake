USE ROLE accountadmin;
use schema {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP,CP01
ALTER TASK refresh_synapse_warehouse_s3_stage_task SUSPEND;
ALTER TASK aclsnapshots_task UNSET schedule;
ALTER TASK aclsnapshots_task ADD AFTER refresh_synapse_warehouse_s3_stage_task;
ALTER TASK TEAMSNAPSHOTS_TASK UNSET schedule;
ALTER TASK TEAMSNAPSHOTS_TASK ADD AFTER refresh_synapse_warehouse_s3_stage_task;
ALTER TASK VERIFICATIONSUBMISSIONSNAPSHOTS_TASK UNSET schedule;
ALTER TASK VERIFICATIONSUBMISSIONSNAPSHOTS_TASK ADD AFTER refresh_synapse_warehouse_s3_stage_task;
ALTER TASK USERGROUPSNAPSHOTS_TASK UNSET schedule;
ALTER TASK USERGROUPSNAPSHOTS_TASK ADD AFTER refresh_synapse_warehouse_s3_stage_task;
// clean up unused tasks
DROP TASK CERTIFIEDQUIZ_TASK;
DROP TASK CERTIFIEDQUIZQUESTION_TASK;
-- ALTER TASK aclsnapshots_task RESUME;
-- ALTER TASK TEAMSNAPSHOTS_TASK RESUME;
-- ALTER TASK VERIFICATIONSUBMISSIONSNAPSHOTS_TASK RESUME;
-- ALTER TASK USERGROUPSNAPSHOTS_TASK RESUME;
-- ALTER TASK refresh_synapse_warehouse_s3_stage_task RESUME;
// https://docs.snowflake.com/en/sql-reference/functions/system_task_dependents_enable
SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('refresh_synapse_warehouse_s3_stage_task');
