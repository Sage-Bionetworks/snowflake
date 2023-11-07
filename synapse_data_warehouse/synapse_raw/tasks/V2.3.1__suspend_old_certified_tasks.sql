use role accountadmin;
use schema {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
alter task refresh_synapse_warehouse_s3_stage_task suspend;
alter task certifiedquiz_task suspend;
alter task certifiedquizquestion_task suspend;
alter task refresh_synapse_warehouse_s3_stage_task resume;
