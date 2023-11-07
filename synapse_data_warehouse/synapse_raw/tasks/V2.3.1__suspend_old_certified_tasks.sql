use role accountadmin;
use schema {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
alter task certifiedquiz_task suspend;
alter task certifiedquizquestion_task suspend;
