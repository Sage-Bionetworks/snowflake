USE ROLE SYSADMIN;
use database synapse_data_warehouse;
use schema synapse;

// Create certified quiz question latest
CREATE OR REPLACE TABLE synapse_data_warehouse.synapse.certifiedquizquestion_latest AS
  WITH cqq_ranked AS (
    SELECT *,
      ROW_NUMBER() OVER (
        PARTITION BY RESPONSE_ID, QUESTION_INDEX
        ORDER BY IS_CORRECT DESC, INSTANCE DESC
      ) AS row_num
    FROM synapse_data_warehouse.synapse_raw.certifiedquizquestion
  )
  SELECT * EXCLUDE row_num
  FROM cqq_ranked
  WHERE row_num = 1
  ORDER BY RESPONSE_ID DESC, QUESTION_INDEX ASC;


// Create certified quiz latest
CREATE TABLE IF NOT EXISTS synapse_data_warehouse.synapse.certifiedquiz_latest AS
    select distinct * from synapse_data_warehouse.synapse_raw.certifiedquiz
    where INSTANCE =
    (select max(INSTANCE) from synapse_data_warehouse.synapse_raw.certifiedquiz);

-- // Create View of user profile and cert join
-- CREATE VIEW IF NOT EXISTS synapse_data_warehouse.synapse.user_certified AS
--   with user_cert_joined as (
--     select *
--     from synapse_data_warehouse.synapse.userprofile_latest user
--     LEFT JOIN (
--       select USER_ID, PASSED from synapse_data_warehouse.synapse.certifiedquiz_latest
--     ) cert
--     ON user.ID = cert.USER_ID
--   )
--   select ID, USER_NAME, FIRST_NAME, LAST_NAME, EMAIL, LOCATION, COMPANY, POSITION, PASSED
--   from user_cert_joined
-- ;

// Use a window function to get the latest user profile snapshot and create a table
CREATE OR REPLACE TABLE synapse_data_warehouse.synapse.userprofile_latest as WITH
  RANKED_NODES AS (
   SELECT
    s.*
    , "row_number"() OVER (PARTITION BY s.id ORDER BY change_timestamp DESC, snapshot_timestamp DESC) n
   FROM
    synapse_data_warehouse.synapse_raw.userprofilesnapshot s
   WHERE
    (s.snapshot_date >= current_timestamp - INTERVAL '60 DAYS')
) 
SELECT * EXCLUDE n
FROM RANKED_NODES
where n = 1;
use role masking_admin;
USE SCHEMA synapse_data_warehouse.synapse;
ALTER TABLE IF EXISTS userprofile_latest
MODIFY COLUMN email
SET MASKING POLICY email_mask;
USE ROLE SYSADMIN;
CREATE TABLE IF NOT EXISTS synapse_data_warehouse.synapse.teammember_latest as WITH
  RANKED_NODES AS (
   SELECT
     s.*
   , "row_number"() OVER (PARTITION BY s.member_id ORDER BY change_timestamp DESC, snapshot_timestamp DESC) n
   FROM
     synapse_data_warehouse.synapse_raw.teammembersnapshots s
)
SELECT *
FROM RANKED_NODES
where n = 1;

CREATE TABLE IF NOT EXISTS synapse_data_warehouse.synapse.team_latest as WITH
  RANKED_NODES AS (
   SELECT
     s.*
   , "row_number"() OVER (PARTITION BY s.id ORDER BY change_timestamp DESC, snapshot_timestamp DESC) n
   FROM synapse_data_warehouse.synapse_raw.teamsnapshots s
)
SELECT *
FROM RANKED_NODES
where n = 1;

// filesnapshots
USE ROLE SYSADMIN;

CREATE OR REPLACE TABLE synapse_data_warehouse.synapse.file_latest as WITH
  RANKED_NODES AS (
   SELECT
     s.*,
     "row_number"() OVER (PARTITION BY s.id ORDER BY change_timestamp DESC, snapshot_timestamp DESC) n
   FROM synapse_data_warehouse.synapse_raw.filesnapshots s
   WHERE
    (s.snapshot_date >= current_timestamp - INTERVAL '60 DAYS') AND
    NOT IS_PREVIEW AND
    CHANGE_TYPE != 'DELETE'
)
SELECT *
FROM RANKED_NODES
where n = 1
;


CREATE TABLE IF NOT EXISTS synapse_data_warehouse.synapse.certified_question_information (
    question_index NUMBER,
    question_group_number NUMBER,
    version STRING,
    fre_q FLOAT,
    fre_help FLOAT,
    difference_fre FLOAT,
    fkgl_q NUMBER,
    fkgl_help FLOAT,
    difference_fkgl FLOAT,
    notes STRING,
    type STRING,
    question_text STRING
);
// Loaded the table manually...

// Create certified quiz question latest
CREATE TABLE IF NOT EXISTS synapse_data_warehouse.synapse.certifiedquizquestion_latest AS
    select distinct * from synapse_data_warehouse.synapse_raw.certifiedquizquestion
    where INSTANCE =
    (select max(INSTANCE) from synapse_data_warehouse.synapse_raw.certifiedquizquestion);

// Create certified quiz latest
CREATE OR REPLACE TABLE synapse_data_warehouse.synapse.certifiedquiz_latest as WITH
  RANKED_NODES AS (
  SELECT
     s.*,
     "row_number"() OVER (PARTITION BY s.USER_ID ORDER BY RESPONSE_ID DESC) n
  FROM synapse_data_warehouse.synapse_raw.certifiedquiz s
  WHERE
    INSTANCE =
    (select max(INSTANCE) from synapse_data_warehouse.synapse_raw.certifiedquiz)
)
SELECT *
FROM RANKED_NODES
where n = 1
;


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
