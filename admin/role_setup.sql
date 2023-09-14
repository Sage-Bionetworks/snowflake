// Custom role setup
CREATE ROLE IF NOT EXISTS genie_admin;

use role securityadmin;
GRANT ROLE genie_admin
TO USER "alex.paynter@sagebase.org";
grant role genie_admin
to role useradmin;
grant role genie_admin
to user "xindi.guo@sagebase.org";
grant role genie_admin
to user "chelsea.nayan@sagebase.org";

CREATE ROLE IF NOT EXISTS recover_admin;

GRANT CREATE SCHEMA, USAGE on DATABASE RECOVER
TO ROLE recover_admin;
GRANT CREATE TABLE, USAGE on SCHEMA recover.pilot
TO ROLE recover_admin;

grant role recover_admin
to role useradmin;
GRANT ROLE recover_admin
TO USER "phil.snyder@sagebase.org";
GRANT ROLE recover_admin
TO USER "rixing.xu@sagebase.org";
GRANT ROLE recover_admin
TO USER "thomas.yu@sagebase.org";
GRANT USAGE ON WAREHOUSE recover_xsmall
TO ROLE recover_admin;

