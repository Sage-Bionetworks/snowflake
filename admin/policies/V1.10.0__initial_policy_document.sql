USE SCHEMA POLICY_DB.PUBLIC;

CREATE PASSWORD POLICY IF NOT EXISTS password_policy
  PASSWORD_MIN_LENGTH = 14
  PASSWORD_MAX_AGE_DAYS = 0;

-- A note on setting policies --
-- Policies can be set at the account or user level. Snowflake provides
-- slightly different mechanisms for updating each:
--
-- Account:
-- Normally, an account-level policy must be first UNSET before
-- we can SET that policy. Optionally, we can specify `... FORCE`
-- at the end of the ALTER statement to avoid needing to UNSET.
-- Since we've already set the account parameters contained in this
-- file and don't want to tempt fate, we leave these commands commented out.
--
-- User:
-- Unlike account-level parameters, there is not even a FORCE
-- option for these statements, so we must comment these out.


-- ALTER ACCOUNT
--   SET PASSWORD POLICY password_policy;
CREATE SESSION POLICY IF NOT EXISTS admin_timeout_policy
  SESSION_IDLE_TIMEOUT_MINS = 15
  SESSION_UI_IDLE_TIMEOUT_MINS = 15;

-- See "A note on setting policies" --
-- ALTER USER "x.schildwachter@sagebase.org"
--   SET SESSION POLICY admin_timeout_policy;
-- ALTER USER "khai.do@sagebase.org"
--   SET SESSION POLICY admin_timeout_policy;
-- ALTER USER THOMASYU888
--   SET SESSION POLICY admin_timeout_policy;
-- ALTER USER "thomas.yu@sagebase.org"
--   SET SESSION POLICY admin_timeout_policy;

-- tag service accounts with account type service to not trigger security warning
CREATE TAG IF NOT EXISTS ACCOUNT_TYPE;
ALTER USER AD_SERVICE SET TAG ACCOUNT_TYPE = 'service';
ALTER USER DPE_SERVICE SET TAG ACCOUNT_TYPE = 'service';
ALTER USER SNOWFLAKE SET TAG ACCOUNT_TYPE = 'service';
ALTER USER thomasyu888 SET TAG ACCOUNT_TYPE = 'service';

-- Set up authentication policies
ALTER ACCOUNT SET ENABLE_IDENTIFIER_FIRST_LOGIN = TRUE;

-- Not including CLIENT_TYPES will enable all types for each auth policy
CREATE AUTHENTICATION POLICY IF NOT EXISTS service_account_authentication_policy
  AUTHENTICATION_METHODS = ('PASSWORD');

CREATE AUTHENTICATION POLICY IF NOT EXISTS admin_authentication_policy
  AUTHENTICATION_METHODS = ('SAML', 'PASSWORD')
  SECURITY_INTEGRATIONS = ('GOOGLE_SSO', 'JUMPCLOUD');

CREATE AUTHENTICATION POLICY IF NOT EXISTS user_authentication_policy
  AUTHENTICATION_METHODS = ('SAML')
  SECURITY_INTEGRATIONS = ('GOOGLE_SSO');

-- See "A note on setting policies" --
-- ALTER ACCOUNT SET AUTHENTICATION POLICY user_authentication_policy;

-- ALTER USER "thomas.yu@sagebase.org" SET AUTHENTICATION POLICY admin_authentication_policy;
-- ALTER USER "khai.do@sagebase.org" SET AUTHENTICATION POLICY admin_authentication_policy;

-- ALTER USER RECOVER_SERVICE SET AUTHENTICATION POLICY service_account_authentication_policy;
-- ALTER USER DPE_SERVICE SET AUTHENTICATION POLICY service_account_authentication_policy;
-- ALTER USER AD_SERVICE SET AUTHENTICATION POLICY service_account_authentication_policy;
-- ALTER USER THOMASYU888 SET AUTHENTICATION POLICY service_account_authentication_policy;
-- ALTER USER ADMIN_SERVICE SET AUTHENTICATION POLICY service_account_authentication_policy;
-- ALTER USER DEVELOPER_SERVICE SET AUTHENTICATION POLICY service_account_authentication_policy;

ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';