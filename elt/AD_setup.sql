use role sysadmin;
use database SAGE;

create schema IF NOT EXISTS AD
    WITH MANAGED ACCESS;

use role securityadmin;
grant ALL PRIVILEGES on schema SAGE.AD to role ad_team;
grant ALL PRIVILEGES on future tables in schema SAGE.ad_team to role sysadmin;
-- grant all privileges on table sage_test.ad_team.diverse_cohorts_fileview to role sysadmin;
