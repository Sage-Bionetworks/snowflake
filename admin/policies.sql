// https://docs.snowflake.com/en/user-guide/security-column-ddm-use
-- use role masking_admin;
-- USE DATABASE synapse_data_warehouse;
-- USE SCHEMA synapse;
-- CREATE MASKING POLICY IF NOT EXISTS email_mask AS (val string) returns string ->
--   CASE
--     WHEN current_role() IN ('SYSADMIN') THEN VAL
--     ELSE regexp_replace(val,'.+\@','*****@') -- leave email domain unmasked
--   END;

-- ALTER MASKING POLICY email_mask SET BODY ->
--   CASE
--     WHEN current_role() IN ('SYSADMIN') THEN VAL
--     ELSE '*****'
--   END;

USE ROLE SYSADMIN;
-- Add all policies into policy_db in case other database is blown away
CREATE DATABASE IF NOT EXISTS POLICY_DB;
USE DATABASE POLICY_DB;
USE ROLE ACCOUNTADMIN;

CREATE PASSWORD POLICY password_policy
PASSWORD_MIN_LENGTH = 14
PASSWORD_MAX_AGE_DAYS = 0;

ALTER ACCOUNT
SET PASSWORD POLICY password_policy;
CREATE SESSION POLICY admin_timeout_policy
SESSION_IDLE_TIMEOUT_MINS = 15,
SESSION_UI_IDLE_TIMEOUT_MINS = 15;

ALTER USER "x.schildwachter@sagebase.org"
SET SESSION POLICY admin_timeout_policy;
ALTER USER "khai.do@sagebase.org"
SET SESSION POLICY admin_timeout_policy;
ALTER USER THOMASYU888
SET SESSION POLICY admin_timeout_policy;
ALTER USER "thomas.yu@sagebase.org"
SET SESSION POLICY admin_timeout_policy;

-- tag service accounts with account type service to not trigger security warning
CREATE TAG ACCOUNT_TYPE;
ALTER USER AD_SERVICE SET TAG ACCOUNT_TYPE = 'service';
ALTER USER DPE_SERVICE SET TAG ACCOUNT_TYPE = 'service';
ALTER USER SNOWFLAKE SET TAG ACCOUNT_TYPE = 'service';
ALTER USER thomasyu888 SET TAG ACCOUNT_TYPE = 'service';

-- Set up authentication policies
-- SHOW PARAMETERS LIKE 'ENABLE_IDENTIFIER_FIRST_LOGIN' IN ACCOUNT;
ALTER ACCOUNT SET ENABLE_IDENTIFIER_FIRST_LOGIN = TRUE;

-- SHOW PASSWORD POLICIES IN ACCOUNT;
-- SHOW SESSION POLICIES IN ACCOUNT;
-- SHOW AUTHENTICATION POLICIES IN ACCOUNT;
-- SHOW MASKING POLICIES IN ACCOUNT;
-- SHOW NETWORK RULES IN ACCOUNT;

-- Not including CLIENT_TYPES will enable all types for each auth policy
CREATE AUTHENTICATION POLICY IF NOT EXISTS service_account_authentication_policy
  AUTHENTICATION_METHODS = ('PASSWORD');

CREATE AUTHENTICATION POLICY IF NOT EXISTS admin_authentication_policy
  AUTHENTICATION_METHODS = ('SAML', 'PASSWORD')
  SECURITY_INTEGRATIONS = ('GOOGLE_SSO', 'JUMPCLOUD');

CREATE AUTHENTICATION POLICY IF NOT EXISTS user_authentication_policy
  AUTHENTICATION_METHODS = ('SAML')
  // CLIENT_TYPES = ('SNOWFLAKE_UI', 'SNOWSQL', 'DRIVERS')
  SECURITY_INTEGRATIONS = ('GOOGLE_SSO');

ALTER ACCOUNT SET AUTHENTICATION POLICY user_authentication_policy;
ALTER USER "thomas.yu@sagebase.org" SET AUTHENTICATION POLICY admin_authentication_policy;
ALTER USER "khai.do@sagebase.org" SET AUTHENTICATION POLICY admin_authentication_policy;

ALTER USER RECOVER_SERVICE SET AUTHENTICATION POLICY service_account_authentication_policy;
ALTER USER DPE_SERVICE SET AUTHENTICATION POLICY service_account_authentication_policy;
ALTER USER AD_SERVICE SET AUTHENTICATION POLICY service_account_authentication_policy;
ALTER USER THOMASYU888 SET AUTHENTICATION POLICY service_account_authentication_policy;
ALTER USER ADMIN_SERVICE SET AUTHENTICATION POLICY service_account_authentication_policy;
ALTER USER DEVELOPER_SERVICE SET AUTHENTICATION POLICY service_account_authentication_policy;

ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

ALTER AUTHENTICATION POLICY service_account_authentication_policy
  AUTHENTICATION_METHODS = ('PASSWORD', 'KEYPAIR');