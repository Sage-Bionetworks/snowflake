USE SCHEMA POLICY_DB.PUBLIC;

-- 1. Update the authentication policy with all desired methods
ALTER AUTHENTICATION POLICY ADMIN_AUTHENTICATION_POLICY
    SET AUTHENTICATION_METHODS = (
        'SAML',
        'KEYPAIR',
        'PROGRAMMATIC_ACCESS_TOKEN'
    );

-- 2. Assign the dummy network policy (created in admin/policies/V1.17.0[...]) to everyone
-- as described in https://docs.snowflake.com/en/user-guide/network-policies#activate-a-network-policy-for-your-account
ALTER ACCOUNT SET NETWORK_POLICY = allow_all_ips;
