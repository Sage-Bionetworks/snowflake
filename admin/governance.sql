use role accountadmin;
// https://docs.snowflake.com/en/user-guide/security-column-ddm-use

use role useradmin;
CREATE ROLE masking_admin;
use role securityadmin;
GRANT CREATE MASKING POLICY on SCHEMA SYNAPSE_DATA_WAREHOUSE.synapse
to ROLE masking_admin;
GRANT CREATE MASKING POLICY on SCHEMA SYNAPSE_DATA_WAREHOUSE.synapse_raw
to ROLE masking_admin;

use role accountadmin;
GRANT APPLY MASKING POLICY on ACCOUNT
to ROLE masking_admin;
GRANT ROLE masking_admin
TO USER thomasyu888;
use role masking_admin;
CREATE OR REPLACE MASKING POLICY email_mask AS (val string) returns string ->
  CASE
    WHEN current_role() IN ('SYSADMIN') THEN VAL
    ELSE regexp_replace(val,'.+\@','*****@') -- leave email domain unmasked
  END;

ALTER TABLE IF EXISTS synapse_data_warehouse.synapse.userprofile_latest
MODIFY COLUMN email
SET MASKING POLICY email_mask;

ALTER TABLE IF EXISTS synapse_data_warehouse.synapse_raw.userprofilesnapshot_raw
MODIFY COLUMN email
SET MASKING POLICY email_mask;
