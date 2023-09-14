use role sysadmin;
CREATE DATABASE IF NOT EXISTS genie;

use role securityadmin;
grant USAGE on database genie
to role genie_admin;
GRANT SELECT ON FUTURE TABLES IN DATABASE GENIE
TO ROLE genie_admin;


-- use database genie;
-- use schema public_13_1;

-- CREATE TABLE IF NOT EXISTS "sample" (
--     PATIENT_ID STRING,
--     SAMPLE_ID STRING,
--     AGE_AT_SEQ_REPORT STRING,
--     ONCOTREE_CODE STRING,
--     SAMPLE_TYPE STRING,
--     SEQ_ASSAY_ID STRING,
--     CANCER_TYPE STRING,
--     CANCER_TYPE_DETAILED STRING,
--     SAMPLE_TYPE_DETAILED STRING
-- );
