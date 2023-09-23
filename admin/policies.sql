// https://docs.snowflake.com/en/user-guide/security-column-ddm-use
use role masking_admin;
CREATE MASKING POLICY IF NOT EXISTS synapse_data_warehouse.synapse.email_mask AS (val string) returns string ->
  CASE
    WHEN current_role() IN ('SYSADMIN') THEN VAL
    ELSE regexp_replace(val,'.+\@','*****@') -- leave email domain unmasked
  END;
