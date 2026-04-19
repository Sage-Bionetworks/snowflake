USE ROLE ACCOUNTADMIN;

-- Storage integrations for the 2026 Synapse RDS -> Snowflake pipeline
CREATE OR REPLACE STORAGE INTEGRATION synapse_snapshots_dev
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = 'S3'
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::766808016710:role/snowflake-role-synapse-snowflake-rds-snapshots-dev'
STORAGE_ALLOWED_LOCATIONS = ('s3://synapse-snowflake-rds-snapshots-dev');

CREATE OR REPLACE STORAGE INTEGRATION synapse_snapshots_prod
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = 'S3'
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::766808016710:role/snowflake-role-synapse-snowflake-rds-snapshots-prod'
STORAGE_ALLOWED_LOCATIONS = ('s3://synapse-snowflake-rds-snapshots-prod');

-- Legacy Synapse data warehouse S3 integrations
CREATE STORAGE INTEGRATION IF NOT EXISTS synapse_prod_warehouse_s3
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = 'S3'
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::325565585839:role/snowflake-access-SnowflakeServiceRole-2JSCDRkX8TcW'
STORAGE_ALLOWED_LOCATIONS = ('s3://prod.datawarehouse.sagebase.org', 's3://prod.filehandles.sagebase.org');

CREATE STORAGE INTEGRATION IF NOT EXISTS synapse_dev_warehouse_s3
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = 'S3'
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::449435941126:role/snowflake-access-SnowflakeServiceRole-BKQMHdbc4uU4'
STORAGE_ALLOWED_LOCATIONS = ('s3://dev.datawarehouse.sagebase.org', 's3://dev.filehandles.sagebase.org');

-- Tableau OAuth integrations
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

-- Google SSO (SAML2) — certificate and issuer values are managed outside of version control
CREATE SECURITY INTEGRATION IF NOT EXISTS GOOGLE_SSO
TYPE = SAML2
ENABLED = TRUE
SAML2_ISSUER = '<% saml2_issuer %>'
SAML2_SSO_URL = '<% saml2_sso_url %>'
SAML2_PROVIDER = 'custom'
SAML2_X509_CERT = '<% saml2_x509_cert %>'
SAML2_SP_INITIATED_LOGIN_PAGE_LABEL = 'GOOGLE_SSO'
SAML2_ENABLE_SP_INITIATED = TRUE
SAML2_SIGN_REQUEST = TRUE
SAML2_SNOWFLAKE_ACS_URL = 'https://mqzfhld-vp00034.snowflakecomputing.com/fed/login'
SAML2_SNOWFLAKE_ISSUER_URL = 'https://mqzfhld-vp00034.snowflakecomputing.com';
