USE WAREHOUSE COMPUTE_ORG;

use role securityadmin;

// Grant system roles to users
GRANT ROLE SYSADMIN
TO USER "kevin.boske@sagebase.org";

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


// Public role
// Synapse data warehouse
// GRANT SELECT ON ALL TABLES IN SCHEMA synapse_data_warehouse.synapse TO ROLE PUBLIC;
-- TODO: Add these back in after governance
-- GRANT SELECT ON FUTURE TABLES IN SCHEMA synapse_data_warehouse.synapse
-- TO ROLE PUBLIC;


USE ROLE USERADMIN;
CREATE ROLE IF NOT EXISTS masking_admin;

use role securityadmin;
GRANT CREATE MASKING POLICY ON SCHEMA SYNAPSE_DATA_WAREHOUSE.synapse
TO ROLE masking_admin;

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
GRANT CREATE SCHEMA, USAGE ON DATABASE SYNAPSE_DATA_WAREHOUSE
TO ROLE data_engineer;
-- GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE SYNAPSE_DATA_WAREHOUSE
-- TO ROLE data_engineer;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN DATABASE SYNAPSE_DATA_WAREHOUSE
-- TO ROLE data_engineer;
GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE SYNAPSE_DATA_WAREHOUSE
TO ROLE data_engineer;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN DATABASE SYNAPSE_DATA_WAREHOUSE
TO ROLE data_engineer;
GRANT CREATE SCHEMA, USAGE ON DATABASE SAGE
TO ROLE data_engineer;
-- GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE SAGE
-- TO ROLE data_engineer;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN DATABASE SAGE
-- TO ROLE data_engineer;
GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE SAGE
TO ROLE data_engineer;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN DATABASE SAGE
TO ROLE data_engineer;
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
