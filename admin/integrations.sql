USE ROLE ACCOUNTADMIN;

-- Storage integration for 2026 Synapse RDS -> Snowflake pipeline (SNOW-392)
CREATE OR REPLACE STORAGE INTEGRATION synapse_snapshot
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::766808016710:role/snowflake-role-synapse-snowflake-rds-snapshots-dev'

-- * Integration to prod (SNOW-14)
CREATE STORAGE INTEGRATION IF NOT EXISTS synapse_prod_warehouse_s3
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::325565585839:role/snowflake-access-SnowflakeServiceRole-2JSCDRkX8TcW'
    STORAGE_ALLOWED_LOCATIONS = ('s3://prod.datawarehouse.sagebase.org', 's3://prod.filehandles.sagebase.org');

-- DESC INTEGRATION synapse_prod_warehouse_s3;
CREATE STORAGE INTEGRATION IF NOT EXISTS synapse_dev_warehouse_s3
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::449435941126:role/snowflake-access-SnowflakeServiceRole-BKQMHdbc4uU4'
    STORAGE_ALLOWED_LOCATIONS = ('s3://dev.datawarehouse.sagebase.org', 's3://dev.filehandles.sagebase.org');

-- RECOVER dev integration
DROP STORAGE INTEGRATION IF EXISTS recover_dev_s3;

-- DESC INTEGRATION synapse_dev_warehouse_s3;
-- https://docs.snowflake.com/en/user-guide/oauth-partner
-- Integration with tableau
CREATE SECURITY INTEGRATION IF NOT EXISTS ts_oauth_int2
  TYPE = OAUTH
  ENABLED = TRUE
  OAUTH_CLIENT = TABLEAU_SERVER
  OAUTH_REFRESH_TOKEN_VALIDITY = 86400;

CREATE SECURITY INTEGRATION IF NOT EXISTS td_oauth_int2
  TYPE = OAUTH
  ENABLED = TRUE
  OAUTH_REFRESH_TOKEN_VALIDITY = 36000
  OAUTH_CLIENT = TABLEAU_DESKTOP;

-- DESC SECURITY INTEGRATION ts_oauth_int2;
-- Used these instructions to create google SAML integration
-- https://community.snowflake.com/s/article/configuring-g-suite-as-an-identity-provider
create security integration IF NOT EXISTS GOOGLE_SSO
    type = saml2
    enabled = true
    saml2_issuer = '<% saml2_issuer %>'
    saml2_sso_url = '<% saml2_sso_url %>' 
    saml2_provider = 'custom'
    saml2_x509_cert='<% saml2_x509_cert %>'
    saml2_sp_initiated_login_page_label = 'GOOGLE_SSO'
    saml2_enable_sp_initiated = true
    SAML2_SIGN_REQUEST = true
    SAML2_SNOWFLAKE_ACS_URL = 'https://mqzfhld-vp00034.snowflakecomputing.com/fed/login'
    SAML2_SNOWFLAKE_ISSUER_URL = 'https://mqzfhld-vp00034.snowflakecomputing.com';

-- DESC security integration GOOGLE_SSO;
