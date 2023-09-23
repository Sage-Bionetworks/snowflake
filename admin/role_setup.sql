use role securityadmin;

// Grant system roles to users
GRANT ROLE SYSADMIN
TO USER "kevin.boske@sagebase.org";

// GENIE
CREATE ROLE IF NOT EXISTS genie_admin;
grant role genie_admin
to role useradmin;
GRANT ROLE genie_admin
TO USER "alex.paynter@sagebase.org";
grant role genie_admin
to user "xindi.guo@sagebase.org";
grant role genie_admin
to user "chelsea.nayan@sagebase.org";

grant USAGE on database genie
to role genie_admin;
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE GENIE
TO ROLE genie_admin;
GRANT SELECT ON FUTURE TABLES IN DATABASE GENIE
TO ROLE genie_admin;
-- GRANT USAGE ON ALL SCHEMAS IN DATABASE GENIE
-- TO ROLE genie_admin;
-- GRANT SELECT ON ALL TABLES IN DATABASE GENIE
-- TO ROLE genie_admin;
GRANT USAGE ON WAREHOUSE tableau
TO ROLE genie_admin;

// RECOVER
CREATE ROLE IF NOT EXISTS recover_data_engineer;
grant role recover_data_engineer
to role useradmin;
GRANT CREATE SCHEMA, USAGE ON DATABASE RECOVER
TO ROLE recover_data_engineer;
GRANT ALL PRIVILEGES ON SCHEMA recover.pilot
TO ROLE recover_data_engineer;

GRANT ROLE recover_data_engineer
TO USER "phil.snyder@sagebase.org";
GRANT ROLE recover_data_engineer
TO USER "rixing.xu@sagebase.org";
GRANT ROLE recover_data_engineer
TO USER "thomas.yu@sagebase.org";
GRANT USAGE ON WAREHOUSE recover_xsmall
TO ROLE recover_data_engineer;

// AD
CREATE ROLE IF NOT EXISTS ad_team;
GRANT ROLE ad_team
TO ROLE useradmin;
GRANT ROLE ad_team
TO USER "abby.vander.linden@sagebase.org";
GRANT USAGE ON DATABASE sage_test
TO ROLE ad_team;

// Synapse data warehouse
// GRANT SELECT ON ALL TABLES IN SCHEMA synapse_data_warehouse.synapse TO ROLE PUBLIC;
GRANT SELECT ON FUTURE TABLES IN SCHEMA synapse_data_warehouse.synapse
TO ROLE PUBLIC;

GRANT USAGE ON FUTURE SCHEMAS IN DATABASE sage_test
TO ROLE PUBLIC;
GRANT SELECT ON FUTURE TABLES IN DATABASE sage_test
TO ROLE PUBLIC;

GRANT USAGE ON DATABASE sage_test
TO ROLE PUBLIC;
