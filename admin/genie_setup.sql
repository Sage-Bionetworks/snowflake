use role sysadmin;
CREATE DATABASE IF NOT EXISTS genie;
use role useradmin;
create role IF NOT EXISTS genie_admin;

use role securityadmin;
grant role genie_admin
to role useradmin;
grant role genie_admin
to user xguo;
grant role genie_admin
to user cnayan;
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
