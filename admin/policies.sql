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

CREATE PASSWORD POLICY password_policy
PASSWORD_MIN_LENGTH = 14
PASSWORD_MAX_AGE_DAYS = 0;

ALTER ACCOUNT
SET PASSWORD POLICY password_policy;
