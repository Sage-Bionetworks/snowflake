use role sysadmin;
use database sage;

create or replace schema ad_team
    WITH MANAGED ACCESS;

use role securityadmin;
grant ALL PRIVILEGES on schema sage_test.ad_team to role ad_team;
grant ALL PRIVILEGES on future tables in schema sage_test.ad_team to role sysadmin;
-- grant all privileges on table sage_test.ad_team.diverse_cohorts_fileview to role sysadmin;

use role ad_team;
use database sage;
use schema ad_team;
COPY INTO "SAGE"."AD_TEAM"."DIVERSE_COHORTS_FILEVIEW"
FROM '@"SAGE"."AD_TEAM"."%DIVERSE_COHORTS_FILEVIEW"/__snowflake_temp_import_files__/'
FILES = ('Job-301735543709776341820576351.csv')
FILE_FORMAT = (
    TYPE=CSV,
    SKIP_HEADER=1,
    FIELD_DELIMITER=',',
    TRIM_SPACE=FALSE,
    FIELD_OPTIONALLY_ENCLOSED_BY='"',
    DATE_FORMAT=AUTO,
    TIME_FORMAT=AUTO,
    TIMESTAMP_FORMAT=AUTO
)
ON_ERROR=ABORT_STATEMENT
PURGE=TRUE;

SELECT *
FROM sage.ad_team.diverse_cohorts_fileview
limit 10;

SELECT distinct("study")
FROM sage.portal_raw.AD;
