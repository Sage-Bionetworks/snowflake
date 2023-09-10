USE ROLE SYSADMIN;
use database synapse_data_warehouse;
use schema synapse;
use role securityadmin;
// GRANT SELECT ON ALL TABLES IN SCHEMA synapse_data_warehouse.synapse TO ROLE PUBLIC;
// GRANT SELECT ON ALL TABLES IN SCHEMA synapse_data_warehouse.synapse_raw TO ROLE PUBLIC;

GRANT SELECT ON FUTURE TABLES IN SCHEMA synapse_data_warehouse.synapse TO ROLE PUBLIC;
// Create certified quiz question latest
CREATE TABLE IF NOT EXISTS synapse_data_warehouse.synapse.certifiedquizquestion_latest AS
    select distinct * from synapse_data_warehouse.synapse_raw.certifiedquizquestion
    where INSTANCE =
    (select max(INSTANCE) from synapse_data_warehouse.synapse_raw.certifiedquizquestion);

// Create certified quiz latest
CREATE TABLE IF NOT EXISTS synapse_data_warehouse.synapse.certifiedquiz_latest AS
    select distinct * from synapse_data_warehouse.synapse_raw.certifiedquiz
    where INSTANCE =
    (select max(INSTANCE) from synapse_data_warehouse.synapse_raw.certifiedquiz);


// Create View of user profile and cert join
CREATE VIEW IF NOT EXISTS synapse_data_warehouse.synapse.user_certified AS
  with user_cert_joined as (
    select *
    from synapse_data_warehouse.synapse.userprofile_latest user
    LEFT JOIN (
      select USER_ID, PASSED from synapse_data_warehouse.synapse.certifiedquiz_latest
    ) cert
    ON user.ID = cert.USER_ID
  )
  select ID, USER_NAME, FIRST_NAME, LAST_NAME, EMAIL, LOCATION, COMPANY, POSITION, PASSED
  from user_cert_joined
;

// Use a window function to get the latest user profile snapshot and create a table
CREATE TABLE IF NOT EXISTS synapse_data_warehouse.synapse.userprofile_latest as WITH
  RANKED_NODES AS (
   SELECT
     s.*
   , "row_number"() OVER (PARTITION BY s.id ORDER BY change_timestamp DESC, snapshot_timestamp DESC) n
   FROM
     synapse_data_warehouse.synapse_raw.userprofilesnapshot s
   WHERE (s.snapshot_date >= current_timestamp - INTERVAL '60 DAYS')
) 
SELECT *
FROM
  RANKED_NODES where n = 1;

SELECT *
FROM synapse_data_warehouse.synapse_raw.teamsnapshots
LIMIT 10;
CREATE TABLE IF NOT EXISTS synapse_data_warehouse.synapse.teammember_latest as WITH
  RANKED_NODES AS (
   SELECT
     s.*
   , "row_number"() OVER (PARTITION BY s.member_id ORDER BY change_timestamp DESC, snapshot_timestamp DESC) n
   FROM
     synapse_data_warehouse.synapse_raw.teammembersnapshots s
   WHERE (s.snapshot_date >= current_timestamp - INTERVAL '60 DAYS')
)
SELECT *
FROM
  RANKED_NODES where n = 1;

CREATE TABLE IF NOT EXISTS synapse_data_warehouse.synapse.team_latest as WITH
  RANKED_NODES AS (
   SELECT
     s.*
   , "row_number"() OVER (PARTITION BY s.id ORDER BY change_timestamp DESC, snapshot_timestamp DESC) n
   FROM
     synapse_data_warehouse.synapse_raw.teamsnapshots s
   WHERE (s.snapshot_date >= current_timestamp - INTERVAL '60 DAYS')
)
SELECT *
FROM
  RANKED_NODES where n = 1;
