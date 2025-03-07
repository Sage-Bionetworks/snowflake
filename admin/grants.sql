USE ROLE SECURITYADMIN;
-- ACCOUNTADMIN privileges
GRANT ROLE ACCOUNTADMIN
TO USER "x.schildwachter@sagebase.org";
GRANT ROLE ACCOUNTADMIN
TO USER "khai.do@sagebase.org";
GRANT ROLE ACCOUNTADMIN
TO USER "phil.snyder@sagebase.org";

-- SYSADMIN privileges
GRANT ROLE SYSADMIN
TO USER "kevin.boske@sagebase.org";
GRANT ROLE SYSADMIN
TO USER "x.schildwachter@sagebase.org";
GRANT ROLE SYSADMIN
TO USER "phil.snyder@sagebase.org";

GRANT ROLE SYSADMIN
TO USER DPE_SERVICE;
-- warehouse usage privileges
GRANT USAGE ON WAREHOUSE COMPUTE_XSMALL
TO ROLE DATA_ANALYTICS;
GRANT USAGE ON WAREHOUSE COMPUTE_XSMALL
TO ROLE GOVERNANCE;

-- public grants
GRANT USAGE ON DATABASE SAGE
TO ROLE PUBLIC;

-- GENIE privileges
GRANT ROLE GENIE_ADMIN
TO ROLE SYSADMIN;
GRANT ROLE GENIE_ADMIN
TO USER "alexander.paynter@sagebase.org";
GRANT ROLE GENIE_ADMIN
TO USER "xindi.guo@sagebase.org";
GRANT ROLE GENIE_ADMIN
TO USER "chelsea.nayan@sagebase.org";
GRANT ROLE GENIE_ADMIN
TO USER "rixing.xu@sagebase.org";
GRANT ROLE GENIE_ADMIN
TO USER "adam.taylor@sagebase.org";

-- RECOVER privileges
GRANT ROLE RECOVER_DATA_ENGINEER
TO ROLE SYSADMIN;
GRANT ROLE RECOVER_DATA_ANALYTICS
TO ROLE RECOVER_DATA_ENGINEER;
GRANT ROLE RECOVER_DATA_ENGINEER
TO USER "phil.snyder@sagebase.org";
GRANT ROLE RECOVER_DATA_ENGINEER
TO USER "rixing.xu@sagebase.org";
GRANT ROLE RECOVER_DATA_ENGINEER
TO USER "thomas.yu@sagebase.org";
GRANT ROLE RECOVER_DATA_ENGINEER
TO USER RECOVER_SERVICE;

-- AD privileges
GRANT ROLE AD
TO ROLE SYSADMIN;
GRANT ROLE AD
TO USER "abby.vanderlinden@sagebase.org";
GRANT ROLE AD
TO USER DBT_SERVICE;
GRANT ROLE AD
TO USER AD_SERVICE;

-- NF privileges
GRANT ROLE NF_ADMIN
TO ROLE SYSADMIN;
GRANT ROLE NF_ADMIN
TO USER "anh.nguyet.vu@sagebase.org";
GRANT ROLE NF_ADMIN
TO USER "thomas.yu@sagebase.org";

-- SCIDATA privileges
GRANT ROLE SCIDATA_ADMIN
TO ROLE SYSADMIN;
GRANT ROLE SCIDATA_ADMIN
TO USER "susheel.varma@sagebase.org";
GRANT ROLE SCIDATA_ADMIN
TO USER "thomas.yu@sagebase.org";

-- Data engineer privileges
GRANT ROLE DATA_ENGINEER
TO ROLE SYSADMIN;
GRANT ROLE DATA_ENGINEER
TO USER "phil.snyder@sagebase.org";
GRANT ROLE DATA_ENGINEER
TO USER "rixing.xu@sagebase.org";
GRANT ROLE DATA_ENGINEER
TO USER "thomas.yu@sagebase.org";
GRANT ROLE DATA_ENGINEER
TO USER "brad.macdonald@sagebase.org";
GRANT ROLE DATA_ENGINEER
TO USER "bryan.fauble@sagebase.org";
GRANT ROLE DATA_ENGINEER
TO USER "nick.grosenbacher@sagebase.org";
GRANT ROLE DATA_ENGINEER
TO USER "jenny.medina@sagebase.org";
GRANT ROLE DATA_ENGINEER
TO USER DPE_SERVICE;

-- data analytics privileges
GRANT ROLE DATA_ANALYTICS TO USER "diep.thach@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "rixing.xu@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "thomas.yu@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "anh.nguyet.vu@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "luca.foschini@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "xindi.guo@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "abby.vanderlinden@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "phil.snyder@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "chelsea.nayan@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "alexander.paynter@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "x.schildwachter@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "natosha.edmonds@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "kevin.boske@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "brad.macdonald@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "robert.allaway@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "victor.baham@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "meghasyam@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "pranav.anbarasu@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "elias.chaibub.neto@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "bryan.fauble@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "john.hill@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "bruce.hoff@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "marco.marasca@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "sandhra.sokhal@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "adam.hindman@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "jessica.malenfant@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "ann.novakowski@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "christine.suver@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "adam.taylor@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "sophia.jobe@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "thomas.schaffter@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "solly.sieberts@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "arti.singh@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "dan.lu@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "jessica.britton@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "christina.conrad@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "drew.duglan@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "zoe.leanza@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "anna.greenwood@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "jay.hodgson@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "milan.vu@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "richard.yaxley@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "ashley.clayton@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "verena.chung@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "jineta.banerjee@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "jenny.medina@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "lakaija.johnson@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "sonia.carlson@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "anthony.williams@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "loren.wolfe@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "lingling.peng@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "gianna.jordan@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "mieko.hashimoto@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "andrew.lamb@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "milen.nikolov@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "amy.heiser@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "rchai@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "maria.diaz@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "gaia.andreoletti@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "susheel.varma@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "amber.nelson@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "tiara.adams@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "william.poehlman@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "alberto.pepe@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "jessica.vera@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "kimberly.corrigan@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "mackenzie.wildman@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "aditi.gopalan@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "angie.bowen@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "aditya.nath@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "james.moon@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "orion.banks@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "samia.ahmed@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "lisa.pasquale@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "joni.harker@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "jo.scanlan@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "trisha.zintel@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "anthony.pena@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "hayley.sanchez@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "bishoy.kamel@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER "andrea.varsavsky@sagebase.org";
GRANT ROLE DATA_ANALYTICS TO USER AD_SERVICE;

// Leaders
GRANT ROLE SAGE_LEADERS TO USER "kim.baggett@sagebase.org";
GRANT ROLE SAGE_LEADERS TO USER "luca.foschini@sagebase.org";
GRANT ROLE SAGE_LEADERS TO USER "alberto.pepe@sagebase.org";
GRANT ROLE SAGE_LEADERS TO USER "susheel.varma@sagebase.org";
GRANT ROLE SAGE_LEADERS TO USER "christine.suver@sagebase.org";
GRANT ROLE SAGE_LEADERS TO USER "anna.greenwood@sagebase.org";
GRANT ROLE SAGE_LEADERS TO USER "mackenzie.wildman@sagebase.org";
GRANT ROLE SAGE_LEADERS TO USER "amy.heiser@sagebase.org";
GRANT ROLE SAGE_LEADERS TO USER "brandon.morgan@sagebase.org";
GRANT ROLE SAGE_LEADERS TO USER "thomas.yu@sagebase.org";
GRANT ROLE SAGE_LEADERS TO USER "milen.nikolov@sagebase.org";
GRANT ROLE SAGE_LEADERS TO ROLE SYSADMIN;
GRANT ROLE DATA_ANALYTICS TO ROLE SAGE_LEADERS;
GRANT ROLE DATA_ANALYTICS TO ROLE SCIDATA_ADMIN;
GRANT ROLE DATA_ANALYTICS TO ROLE NF_ADMIN;
GRANT ROLE DATA_ANALYTICS TO ROLE GENIE_ADMIN;
GRANT ROLE DATA_ANALYTICS TO ROLE AD;
GRANT ROLE DATA_ANALYTICS TO ROLE GOVERNANCE;

GRANT ROLE FAIR TO USER "anthony.williams@sagebase.org";
GRANT ROLE FAIR TO USER "loren.wolfe@sagebase.org";
GRANT ROLE FAIR TO USER "lingling.peng@sagebase.org";
GRANT ROLE FAIR TO USER "gianna.jordan@sagebase.org";
GRANT ROLE FAIR TO USER "mieko.hashimoto@sagebase.org";
GRANT ROLE FAIR TO USER "andrew.lamb@sagebase.org";
GRANT ROLE FAIR TO USER "milen.nikolov@sagebase.org";
GRANT ROLE FAIR TO USER "amy.heiser@sagebase.org";
GRANT ROLE FAIR TO ROLE SYSADMIN;

GRANT ROLE DPE_OPS TO USER "thomas.yu@sagebase.org";
GRANT ROLE DPE_OPS TO USER "sophia.jobe@sagebase.org";
GRANT ROLE DPE_OPS TO ROLE SYSADMIN;

GRANT ROLE GOVERNANCE TO USER "christine.suver@sagebase.org";
GRANT ROLE GOVERNANCE TO USER "kimberly.corrigan@sagebase.org";
GRANT ROLE GOVERNANCE TO USER "ann.novakowski@sagebase.org";
GRANT ROLE GOVERNANCE TO USER "thomas.yu@sagebase.org";
GRANT ROLE GOVERNANCE TO USER "x.schildwachter@sagebase.org";
GRANT ROLE GOVERNANCE TO USER "anthony.pena@sagebase.org";
GRANT ROLE GOVERNANCE TO USER "hayley.sanchez@sagebase.org";
GRANT ROLE GOVERNANCE TO ROLE SYSADMIN;

-- Create governance privileges
GRANT ROLE MASKING_ADMIN
TO USER "thomas.yu@sagebase.org";
USE ROLE ACCOUNTADMIN;
GRANT APPLY MASKING POLICY ON ACCOUNT
TO ROLE MASKING_ADMIN;


-- Synapse data warehouse privileges
GRANT USAGE ON INTEGRATION SYNAPSE_PROD_WAREHOUSE_S3
TO ROLE SYSADMIN;
GRANT USAGE ON INTEGRATION SYNAPSE_PROD_WAREHOUSE_S3
TO ROLE DATA_ENGINEER;

USE ROLE SECURITYADMIN;
GRANT CREATE MASKING POLICY ON SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE
TO ROLE MASKING_ADMIN;

-- Allow for data engineer role to create tasks
-- https://docs.snowflake.com/en/user-guide/tasks-intro#creating-tasks
USE ROLE ACCOUNTADMIN;
GRANT EXECUTE TASK, EXECUTE MANAGED TASK ON ACCOUNT TO ROLE taskadmin;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE DATA_ENGINEER; --noqa: PRS
USE ROLE securityadmin;
GRANT ROLE taskadmin TO ROLE DATA_ENGINEER; --noqa: PRS

-- Synapse data warehouse dev privileges
USE SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_RAW;
GRANT USAGE ON INTEGRATION SYNAPSE_DEV_WAREHOUSE_S3
TO ROLE SYSADMIN;

GRANT USAGE ON ALL PROCEDURES IN DATABASE SYNAPSE_DATA_WAREHOUSE
TO ROLE GOVERNANCE;
GRANT USAGE ON FUTURE PROCEDURES IN DATABASE SYNAPSE_DATA_WAREHOUSE
TO ROLE GOVERNANCE;

-- Sage database privileges
GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE SAGE
TO ROLE DATA_ENGINEER;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN DATABASE SAGE
TO ROLE DATA_ENGINEER;
GRANT CREATE SCHEMA, USAGE ON DATABASE SAGE
TO ROLE DATA_ENGINEER;
GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE SAGE
TO ROLE DATA_ENGINEER;
GRANT ALL PRIVILEGES ON ALL TABLES IN DATABASE SAGE
TO ROLE DATA_ENGINEER;

-- GRANT USAGE ON FUTURE SCHEMAS IN DATABASE SAGE
-- TO ROLE DATA_ANALYTICS;
-- GRANT SELECT ON FUTURE TABLES IN DATABASE SAGE
-- TO ROLE DATA_ANALYTICS;
-- GRANT SELECT ON FUTURE VIEWS IN DATABASE SAGE
-- TO ROLE DATA_ANALYTICS;
GRANT SELECT ON FUTURE TABLES IN SCHEMA SAGE.AD
TO ROLE DATA_ANALYTICS;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA SAGE.AD
TO ROLE DATA_ANALYTICS;
GRANT SELECT ON FUTURE TABLES IN SCHEMA SAGE.IT
TO ROLE DATA_ANALYTICS;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA SAGE.IT
TO ROLE DATA_ANALYTICS;
GRANT SELECT ON FUTURE TABLES IN SCHEMA SAGE.CITATIONS
TO ROLE DATA_ANALYTICS;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA SAGE.CITATIONS
TO ROLE DATA_ANALYTICS;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA SAGE.AUDIT
TO ROLE DATA_ANALYTICS;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA SAGE.AUDIT
TO ROLE DATA_ANALYTICS;
GRANT USAGE ON DATABASE SAGE
TO ROLE DATA_ANALYTICS;

-- AD database privileges
USE SCHEMA SAGE.AD;
GRANT ALL PRIVILEGES ON SCHEMA AD
TO ROLE AD;
GRANT CREATE SCHEMA, USAGE ON DATABASE SAGE
TO ROLE AD;

-- NF database privileges
USE SCHEMA SAGE.NF;
GRANT ALL PRIVILEGES ON SCHEMA NF
TO ROLE NF_ADMIN;

-- SCIDATA database privileges
USE SCHEMA SAGE.SCIDATA;
GRANT ALL PRIVILEGES ON SCHEMA SCIDATA
TO ROLE SCIDATA_ADMIN;


-- GENIE database privileges
USE DATABASE GENIE;
GRANT USAGE ON DATABASE GENIE
TO ROLE GENIE_ADMIN;
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE GENIE
TO ROLE GENIE_ADMIN;
GRANT SELECT ON FUTURE TABLES IN DATABASE GENIE
TO ROLE GENIE_ADMIN;

GRANT USAGE ON WAREHOUSE TABLEAU
TO ROLE GENIE_ADMIN;

-- RECOVER database privileges
USE DATABASE RECOVER;
GRANT CREATE SCHEMA, USAGE ON DATABASE RECOVER
TO ROLE RECOVER_DATA_ENGINEER;
GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE RECOVER
TO ROLE RECOVER_DATA_ENGINEER;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN DATABASE RECOVER
TO ROLE RECOVER_DATA_ENGINEER;
GRANT USAGE ON WAREHOUSE RECOVER_XSMALL
TO ROLE RECOVER_DATA_ENGINEER;
GRANT USAGE ON DATABASE RECOVER
TO ROLE RECOVER_DATA_ANALYTICS;
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE RECOVER
TO ROLE RECOVER_DATA_ANALYTICS;
GRANT SELECT ON FUTURE TABLES IN DATABASE RECOVER
TO ROLE RECOVER_DATA_ANALYTICS;
GRANT USAGE ON INTEGRATION RECOVER_DEV_S3
TO ROLE SYSADMIN;

-- Create DBT specific role

GRANT SELECT ON FUTURE TABLES IN DATABASE RECOVER
TO ROLE RECOVER_DATA_ANALYTICS;

-- IPINFO
GRANT IMPORTED PRIVILEGES ON DATABASE IPINFO_FREE_COUNTRY__ASN_IP_ADDRESS_DATA
TO DATA_ANALYTICS;

GRANT IMPORTED PRIVILEGES ON DATABASE IPINFO_FREE_COUNTRY__ASN_IP_ADDRESS_DATA
TO DATA_ENGINEER;

-- SYNAPSE_DATA_WAREHOUSE domain roles
GRANT ROLE SYNAPSE_DATA_WAREHOUSE_ADMIN TO ROLE SYSADMIN;
GRANT ROLE SYNAPSE_DATA_WAREHOUSE_ANALYST TO ROLE SYNAPSE_DATA_WAREHOUSE_ADMIN;

-- SYNAPSE_DATA_WAREHOUSE_DEV domain roles
GRANT ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ADMIN TO ROLE SYSADMIN;
GRANT ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ANALYST TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ADMIN;

-- CREATE DATABASE privileges on domain ADMIN roles
USE ROLE ACCOUNTADMIN;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE SYNAPSE_DATA_WAREHOUSE_ADMIN;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ADMIN;
-- Switch back to SECURITYADMIN role
USE ROLE SECURITYADMIN;

---- RBAC reconfiguration of data warehouse ----
-- The following grants provide read access on most 
-- objects presently within the data warehouse.

---- SYNAPSE_DATA_WAREHOUSE ----
-- Grant the aggregate roles usage on their respective schema
GRANT USAGE, MONITOR
    ON SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE
    TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SYNAPSE_ALL_ANALYST;
GRANT USAGE, MONITOR
    ON SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW
    TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW_ALL_ANALYST;
GRANT USAGE, MONITOR
    ON SCHEMA SYNAPSE_DATA_WAREHOUSE.SCHEMACHANGE
    TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SCHEMACHANGE_ALL_ANALYST;

-- Grant object-type-specific privileges to the appropriate object-type-specific role
-- SYNAPSE
GRANT SELECT, REFERENCES
	ON ALL TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SYNAPSE_TABLE_READ;
GRANT SELECT, MONITOR
	ON ALL DYNAMIC TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SYNAPSE_TABLE_READ;
GRANT USAGE, READ
	ON ALL STAGES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SYNAPSE_STAGE_READ;
GRANT SELECT, REFERENCES
	ON ALL VIEWS
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SYNAPSE_VIEW_READ;
GRANT MONITOR
	ON ALL TASKS
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SYNAPSE_TASK_READ;

-- SYNAPSE_RAW
GRANT SELECT, REFERENCES
	ON ALL TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW_TABLE_READ;
GRANT USAGE, READ
	ON ALL STAGES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW_STAGE_READ;
GRANT SELECT
	ON ALL STREAMS
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW_STREAM_READ;
GRANT MONITOR
	ON ALL TASKS
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW_TASK_READ;

-- SCHEMACHANGE
GRANT SELECT, REFERENCES
	ON ALL TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SCHEMACHANGE
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.SCHEMACHANGE_TABLE_READ;

---- SYNAPSE_DATA_WAREHOUSE_DEV ----
-- Grant the aggregate roles usage on their respective schema
GRANT USAGE, MONITOR
    ON SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE
    TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_ALL_ANALYST;
GRANT USAGE, MONITOR
    ON SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_RAW
    TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_RAW_ALL_ANALYST;
GRANT USAGE, MONITOR
    ON SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SCHEMACHANGE
    TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SCHEMACHANGE_ALL_ANALYST;

-- Grant object-type-specific privileges to the appropriate object-type-specific role
-- SYNAPSE
GRANT SELECT, REFERENCES
	ON ALL TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_TABLE_READ;
GRANT SELECT, MONITOR
	ON ALL DYNAMIC TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_TABLE_READ;

-- SYNAPSE_RAW
GRANT SELECT, REFERENCES
	ON ALL TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_RAW
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_RAW_TABLE_READ;
GRANT USAGE, READ
	ON ALL STAGES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_RAW
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_RAW_STAGE_READ;
GRANT SELECT
	ON ALL STREAMS
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_RAW
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_RAW_STREAM_READ;
GRANT MONITOR
	ON ALL TASKS
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_RAW
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_RAW_TASK_READ;

-- SCHEMACHANGE
GRANT SELECT, REFERENCES
	ON ALL TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SCHEMACHANGE
	TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SCHEMACHANGE_TABLE_READ;

-- Allow SECURITYADMIN to deploy schemachange for versioned admin scripts
GRANT USAGE
    ON DATABASE METADATA
    TO ROLE SECURITYADMIN;
GRANT USAGE
    ON SCHEMA METADATA.SCHEMACHANGE
    TO ROLE SECURITYADMIN;
GRANT SELECT, INSERT
    ON TABLE METADATA.SCHEMACHANGE.CHANGE_HISTORY
    TO ROLE SECURITYADMIN;

-- Grant appropriate roles to our service accounts
GRANT ROLE ACCOUNTADMIN
	TO USER ADMIN_SERVICE;
GRANT ROLE DATA_ENGINEER 
	TO USER DEVELOPER_SERVICE;

-- Allow the proxy admins to run serverless tasks
USE ROLE ACCOUNTADMIN;
GRANT EXECUTE MANAGED TASK
	ON ACCOUNT
	TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ALL_ADMIN;
GRANT EXECUTE MANAGED TASK
	ON ACCOUNT
	TO ROLE SYNAPSE_DATA_WAREHOUSE_ALL_ADMIN;
USE ROLE SECURITYADMIN;

-- Grant usage of our warehouses to the proxy admins
GRANT USAGE ON WAREHOUSE COMPUTE_XSMALL
	TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ALL_ADMIN;
GRANT USAGE ON WAREHOUSE COMPUTE_MEDIUM
	TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ALL_ADMIN;
GRANT USAGE ON WAREHOUSE COMPUTE_XSMALL
	TO ROLE SYNAPSE_DATA_WAREHOUSE_ALL_ADMIN;
GRANT USAGE ON WAREHOUSE COMPUTE_MEDIUM
	TO ROLE SYNAPSE_DATA_WAREHOUSE_ALL_ADMIN;

-- Allow the proxy admins to run tasks (generally)
USE ROLE ACCOUNTADMIN;
GRANT EXECUTE TASK
	ON ACCOUNT
	TO ROLE SYNAPSE_DATA_WAREHOUSE_ALL_ADMIN;
GRANT EXECUTE TASK
	ON ACCOUNT
	TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ALL_ADMIN;
USE ROLE SECURITYADMIN;

-- Allow the proxy admin to use storage integrations
-- necessary for external stages
USE ROLE ACCOUNTADMIN;
GRANT USAGE
    ON INTEGRATION SYNAPSE_PROD_WAREHOUSE_S3
    TO ROLE SYNAPSE_DATA_WAREHOUSE_ALL_ADMIN;
GRANT USAGE
    ON INTEGRATION SYNAPSE_DEV_WAREHOUSE_S3
    TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ALL_ADMIN;
USE ROLE SECURITYADMIN;

-- Supplant read-type privileges on data warehouse --
-- We first grant analyst account roles USAGE of the
-- respective "core" analyst account role for the data
-- warehouse. We then revoke redundant or excessive (e.g.,
-- write-type) privileges from the same account roles.

-- SYNAPSE_DATA_WAREHOUSE_DEV --
GRANT USAGE 
	ON ROLE SYNAPSE_DATA_WAREHOUSE_DEV_ANALYST
	TO ROLE DATA_ENGINEER;

-- SYNAPSE_DATA_WAREHOUSE --
GRANT USAGE 
	ON ROLE SYNAPSE_DATA_WAREHOUSE_ANALYST
	TO ROLE DATA_ENGINEER;
GRANT USAGE 
	ON ROLE SYNAPSE_DATA_WAREHOUSE_ANALYST
	TO ROLE GOVERNANCE;
GRANT USAGE 
	ON ROLE SYNAPSE_DATA_WAREHOUSE_ANALYST
	TO ROLE AD;
GRANT USAGE 
	ON ROLE SYNAPSE_DATA_WAREHOUSE_ANALYST
	TO ROLE DATA_ANALYTICS;

-- Revoke grants redundant with SYNAPSE_DATA_WAREHOUSE[_DEV]_ANALYST
-- SYNAPSE_DATA_WAREHOUSE --
REVOKE CREATE STREAMLIT, CREATE PROCEDURE, CREATE STAGE, CREATE STREAM, CREATE TABLE, CREATE TASK, MODIFY, USAGE, CREATE FUNCTION
	ON ALL SCHEMAS
	IN DATABASE SYNAPSE_DATA_WAREHOUSE
	FROM ROLE DATA_ENGINEER;
REVOKE CREATE SCHEMA, USAGE
	ON DATABASE SYNAPSE_DATA_WAREHOUSE
	FROM ROLE DATA_ENGINEER;
REVOKE USAGE
	ON DATABASE SYNAPSE_DATA_WAREHOUSE
	FROM ROLE GOVERNANCE;
REVOKE USAGE
	ON ALL SCHEMAS
	IN DATABASE SYNAPSE_DATA_WAREHOUSE
	FROM ROLE DATA_ANALYTICS;
REVOKE USAGE
	ON DATABASE SYNAPSE_DATA_WAREHOUSE
	FROM ROLE DATA_ANALYTICS;
REVOKE USAGE
	ON ALL SCHEMAS
	IN DATABASE SYNAPSE_DATA_WAREHOUSE
	FROM ROLE AD;
REVOKE USAGE
	ON ALL SCHEMAS
	IN DATABASE SYNAPSE_DATA_WAREHOUSE
	FROM ROLE GOVERNANCE;
REVOKE CREATE SCHEMA, USAGE
	ON DATABASE SYNAPSE_DATA_WAREHOUSE
	FROM ROLE AD;

-- SYNAPSE_DATA_WAREHOUSE.SCHEMACHANGE --
REVOKE EVOLVE SCHEMA, UPDATE, SELECT, INSERT
	ON ALL TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SCHEMACHANGE
	FROM ROLE DATA_ENGINEER;
REVOKE SELECT
	ON ALL TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SCHEMACHANGE
	FROM ROLE GOVERNANCE;

-- SYNAPSE_DATA_WAREHOUSE.SYNAPSE --
REVOKE SELECT
	ON ALL TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE
	FROM ROLE DATA_ANALYTICS;
REVOKE SELECT
	ON ALL TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE
	FROM ROLE AD;
REVOKE OPERATE, SELECT, MONITOR
	ON ALL DYNAMIC TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE
	FROM ROLE DATA_ENGINEER;
REVOKE EVOLVE SCHEMA, INSERT, UPDATE, SELECT
	ON ALL TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE
	FROM ROLE DATA_ENGINEER;
REVOKE SELECT
	ON ALL TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE
	FROM ROLE GOVERNANCE;
REVOKE SELECT
	ON ALL TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE
	FROM ROLE PUBLIC;

-- SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW --
REVOKE EVOLVE SCHEMA, SELECT, UPDATE, INSERT
	ON ALL TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW
	FROM ROLE DATA_ENGINEER;
REVOKE APPLYBUDGET, MONITOR, OPERATE
	ON ALL TASKS
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW
	FROM ROLE DATA_ENGINEER;
REVOKE SELECT
	ON ALL STREAMS
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW
	FROM ROLE DATA_ENGINEER;
REVOKE SELECT
	ON ALL TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW
	FROM ROLE GOVERNANCE;
REVOKE SELECT
	ON ALL TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW
	FROM ROLE DATA_ANALYTICS;

-- SYNAPSE_DATA_WAREHOUSE_DEV --
REVOKE CREATE TABLE, CREATE STREAM, CREATE TASK, MODIFY, USAGE, CREATE STAGE, CREATE PROCEDURE, CREATE FUNCTION, CREATE STREAMLIT
	ON ALL SCHEMAS
	IN DATABASE SYNAPSE_DATA_WAREHOUSE_DEV
	FROM ROLE DATA_ENGINEER;
REVOKE USAGE, CREATE SCHEMA
	ON DATABASE SYNAPSE_DATA_WAREHOUSE_DEV
	FROM ROLE DATA_ENGINEER;

-- SYNAPSE_DATA_WAREHOUSE_DEV.SCHEMACHANGE --
REVOKE INSERT, SELECT, UPDATE, EVOLVE SCHEMA
	ON ALL TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SCHEMACHANGE
	FROM ROLE DATA_ENGINEER;

-- SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE --
REVOKE OPERATE, SELECT, MONITOR
	ON ALL DYNAMIC TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE
	FROM ROLE DATA_ENGINEER;
REVOKE UPDATE, INSERT, EVOLVE SCHEMA, SELECT
	ON ALL TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE
	FROM ROLE DATA_ENGINEER;

-- SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_RAW --
REVOKE SELECT
	ON ALL STREAMS
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_RAW
	FROM ROLE DATA_ENGINEER;
REVOKE EVOLVE SCHEMA, INSERT, SELECT, UPDATE
	ON ALL TABLES
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_RAW
	FROM ROLE DATA_ENGINEER;
REVOKE APPLYBUDGET, MONITOR, OPERATE
	ON ALL TASKS
	IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_RAW
	FROM ROLE DATA_ENGINEER;