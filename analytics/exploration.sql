USE ROLE SYSADMIN;
use database synapse_data_warehouse;
use schema synapse_raw;
select *
from certifiedquiz
order by RESPONSE_ID DESC
limit 10;

select sum(num_times_quiz)
from 
    (select user_id, count(*) as num_times_quiz from certifiedquiz group by user_id) s
where num_times_quiz > 1;



select *
from
certifiedquizquestion
limit 10;

select *
from certifiedquiz
limit 10;

select *
from
synapse_data_warehouse.synapse.userprofile_latest
limit 10;

// Explore certified quiz
select distinct INSTANCE
from certifiedquiz;
select count(*)
from certifiedquiz;

select *
from certifiedquizquestionrecords
limit 10;

select count(*)
from nodesnapshots;

// Look for whether or not certain API calls are still used
select distinct USER_AGENT
from processedaccess
where request_url like '%/table/sql/transform' ;



select RESPONSE_ID, INSTANCE, count(*)
from synapse_data_warehouse.synapse_raw.certifiedquizquestion
group by RESPONSE_ID, INSTANCE
order by RESPONSE_ID ASC;

select *
from synapse_data_warehouse.synapse_raw.certifiedquizquestion
where RESPONSE_ID = 1
order by QUESTION_INDEX ASC;


with no_dups as (
    select distinct * from synapse_data_warehouse.synapse_raw.certifiedquizquestion
)
select count(*)
from no_dups;
