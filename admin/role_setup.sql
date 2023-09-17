use role securityadmin;

// Custom role setup
CREATE ROLE IF NOT EXISTS genie_admin;
grant role genie_admin
to role useradmin;
GRANT ROLE genie_admin
TO USER "alex.paynter@sagebase.org";
grant role genie_admin
to user "xindi.guo@sagebase.org";
grant role genie_admin
to user "chelsea.nayan@sagebase.org";

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
