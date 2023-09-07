use role sysadmin;
create database sage_test;
use database sage_test;

use role useradmin;
create role ad_team;
grant role ad_team to role useradmin;
grant role ad_team to user avlinden;

use role sysadmin;
create or replace schema ad_team
    WITH MANAGED ACCESS;

use role securityadmin;
grant USAGE on database sage_test to role ad_team;
grant ALL PRIVILEGES on schema sage_test.ad_team to role ad_team;
grant ALL PRIVILEGES on future tables in schema sage_test.ad_team to role sysadmin;
-- grant all privileges on table sage_test.ad_team.diverse_cohorts_fileview to role sysadmin;

use role ad_team;
use database sage_test;
use schema ad_team;
create table test_me (
    foo STRING
    );
drop table test_me;

