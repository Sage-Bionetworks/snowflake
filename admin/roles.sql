USE WAREHOUSE COMPUTE_ORG;
use role securityadmin;

// Grant system roles to users
GRANT ROLE SYSADMIN
TO USER "kevin.boske@sagebase.org";

GRANT ROLE SYSADMIN
TO USER "x.schildwachter@sagebase.org";

// GENIE
USE ROLE USERADMIN;
CREATE ROLE IF NOT EXISTS genie_admin;
USE ROLE SECURITYADMIN;
grant role genie_admin
to role useradmin;
GRANT ROLE genie_admin
TO USER "alex.paynter@sagebase.org";
grant role genie_admin
to user "xindi.guo@sagebase.org";
grant role genie_admin
to user "chelsea.nayan@sagebase.org";

// RECOVER
USE ROLE USERADMIN;
CREATE ROLE IF NOT EXISTS recover_data_engineer;
CREATE ROLE IF NOT EXISTS recover_data_analytics;

USE ROLE SECURITYADMIN;
grant role recover_data_engineer
to role useradmin;
grant role recover_data_analytics
to role useradmin;
GRANT ROLE recover_data_engineer
TO USER "phil.snyder@sagebase.org";
GRANT ROLE recover_data_engineer
TO USER "rixing.xu@sagebase.org";
GRANT ROLE recover_data_engineer
TO USER "thomas.yu@sagebase.org";

// AD
USE ROLE USERADMIN;
CREATE ROLE IF NOT EXISTS AD;
USE ROLE SECURITYADMIN;
GRANT ROLE AD
TO ROLE useradmin;
GRANT ROLE AD
TO USER "abby.vanderlinden@sagebase.org";

USE ROLE USERADMIN;
CREATE ROLE IF NOT EXISTS masking_admin;
GRANT ROLE masking_admin
TO USER "thomas.yu@sagebase.org";
USE ROLE ACCOUNTADMIN;
GRANT APPLY MASKING POLICY on ACCOUNT
to ROLE masking_admin;

USE ROLE USERADMIN;
CREATE ROLE IF NOT EXISTS data_engineer;
USE ROLE SECURITYADMIN;
grant role data_engineer
to role useradmin;

GRANT ROLE data_engineer
TO USER "phil.snyder@sagebase.org";
GRANT ROLE data_engineer
TO USER "rixing.xu@sagebase.org";
GRANT ROLE data_engineer
TO USER "thomas.yu@sagebase.org";
GRANT ROLE data_engineer
TO USER "brad.macdonald@sagebase.org";
GRANT ROLE data_engineer
TO USER "bryan.fauble@sagebase.org";
