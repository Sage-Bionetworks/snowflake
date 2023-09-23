// https://docs.snowflake.com/en/user-guide/security-column-ddm-use
use role useradmin;
USE WAREHOUSE COMPUTE_ORG;
CREATE ROLE IF NOT EXISTS masking_admin;
use role securityadmin;
GRANT ROLE masking_admin
TO ROLE useradmin;
GRANT ROLE masking_admin
TO USER "thomas.yu@sagebase.org";
GRANT CREATE MASKING POLICY ON SCHEMA SYNAPSE_DATA_WAREHOUSE.synapse
TO ROLE masking_admin;
USE ROLE accountadmin;
GRANT APPLY MASKING POLICY on ACCOUNT
TO ROLE masking_admin;
use role masking_admin;
use database synapse_data_warehouse;
use schema synapse;
CREATE MASKING POLICY IF NOT EXISTS email_mask AS (val string) returns string ->
  CASE
    WHEN current_role() IN ('SYSADMIN') THEN VAL
    ELSE regexp_replace(val,'.+\@','*****@') -- leave email domain unmasked
  END;
ALTER TABLE IF EXISTS userprofile_latest
MODIFY COLUMN email
SET MASKING POLICY email_mask;
