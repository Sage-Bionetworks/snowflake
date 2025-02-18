-- PASSWORD for backwards compatibility with account currently used for CI 
-- KEYPAIR for future support of service accounts
ALTER AUTHENTICATION POLICY service_account_authentication_policy
  SET AUTHENTICATION_METHODS = ('PASSWORD', 'KEYPAIR');
-- SAML to continue support for "external browser" login
-- KEYPAIR for future support of key-pair auth for regular users 
ALTER AUTHENTICATION POLICY user_authentication_policy
  SET AUTHENTICATION_METHODS = ('SAML', 'KEYPAIR');