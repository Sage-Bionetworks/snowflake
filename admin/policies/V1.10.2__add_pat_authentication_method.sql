USE SCHEMA POLICY_DB.PUBLIC;

-- 1. Create a permissive network policy
CREATE NETWORK POLICY IF NOT EXISTS allow_all_ips
    ALLOWED_IP_LIST = ('0.0.0.0/0');

-- 2. Update the authentication policy with all desired methods
ALTER AUTHENTICATION POLICY USER_AUTHENTICATION_POLICY
    SET AUTHENTICATION_METHODS = ('SAML', 'KEYPAIR', 'PROGRAMMATIC_ACCESS_TOKEN');

-- 3. Set the PAT policy to be user-friendly
ALTER AUTHENTICATION POLICY USER_AUTHENTICATION_POLICY
    SET PAT_POLICY = (
        DEFAULT_EXPIRY_IN_DAYS = 365,
        NETWORK_POLICY_EVALUATION = ENFORCED_NOT_REQUIRED
    );

-- 4. Assign the dummy network policy to everyone
----- as described in https://docs.snowflake.com/en/user-guide/network-policies#activate-a-network-policy-for-your-account
ALTER ACCOUNT SET NETWORK_POLICY = allow_all_ips;