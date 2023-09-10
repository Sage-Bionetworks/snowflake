USE ROLE PUBLIC;
USE WAREHOUSE compute_org;
use database synapse_data_warehouse;
use schema synapse_raw;

// Explore certified quiz / certified quiz questions
select *
from certifiedquiz
limit 10;

select sum(num_times_quiz)
from 
    (select user_id, count(*) as num_times_quiz from certifiedquiz group by user_id) s
where num_times_quiz > 1;

select *
from
certifiedquizquestion
limit 10;

select distinct INSTANCE
from certifiedquiz;
select count(*)
from certifiedquiz;

select *
from certifiedquizquestionrecords
limit 10;

select RESPONSE_ID, INSTANCE, count(*)
from certifiedquizquestion
group by RESPONSE_ID, INSTANCE
order by RESPONSE_ID ASC;

select *
from certifiedquizquestion
where RESPONSE_ID = 1
order by QUESTION_INDEX ASC;

with no_dups as (
    select distinct * from certifiedquizquestion
)
select count(*)
from no_dups;

// Look for whether or not certain API calls are still used
select distinct USER_AGENT
from processedaccess
where request_url like '%/table/sql/transform' ;

//110486
select count(*)
from synapse_data_warehouse.synapse.user_certified
where PASSED is null;

select PASSED, count(*)
from synapse_data_warehouse.synapse.user_certified
group by PASSED;

// This doesn't have me...
select *
from synapse_data_warehouse.synapse_raw.certifiedquiz
where USER_ID = 3324230;
