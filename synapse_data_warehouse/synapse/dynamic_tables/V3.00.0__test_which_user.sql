USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

select id
from node_latest
limit 1;
