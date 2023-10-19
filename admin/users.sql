!set variable_substitution=true;

// SAML integration
use role accountadmin;
// Used these instructions to create google SAML integration
// https://community.snowflake.com/s/article/configuring-g-suite-as-an-identity-provider
create security integration IF NOT EXISTS GOOGLE_SSO
    type = saml2
    enabled = true
    saml2_issuer = '&saml2_issuer'
    saml2_sso_url = '&saml2_sso_url'
    saml2_provider = 'custom'
    saml2_x509_cert='&saml2_x509_cert'
    saml2_sp_initiated_login_page_label = 'GOOGLE_SSO'
    saml2_enable_sp_initiated = true
    SAML2_SIGN_REQUEST = true
    SAML2_SNOWFLAKE_ACS_URL = 'https://mqzfhld-vp00034.snowflakecomputing.com/fed/login'
    SAML2_SNOWFLAKE_ISSUER_URL = 'https://mqzfhld-vp00034.snowflakecomputing.com';

-- DESC security integration GOOGLE_SSO;
USE ROLE USERADMIN;
CREATE USER IF NOT EXISTS "diep.thach@sagebase.org";
CREATE USER IF NOT EXISTS "rixing.xu@sagebase.org";
CREATE USER IF NOT EXISTS "thomas.yu@sagebase.org";
CREATE USER IF NOT EXISTS "anh.nguyet.vu@sagebase.org";
CREATE USER IF NOT EXISTS "luca.foschini@sagebase.org";
CREATE USER IF NOT EXISTS "xindi.guo@sagebase.org";
CREATE USER IF NOT EXISTS "abby.vanderlinden@sagebase.org";
CREATE USER IF NOT EXISTS "phil.snyder@sagebase.org";
CREATE USER IF NOT EXISTS "chelsea.nayan@sagebase.org";
CREATE USER IF NOT EXISTS "alexander.paynter@sagebase.org";
CREATE USER IF NOT EXISTS "x.schildwachter@sagebase.org";
CREATE USER IF NOT EXISTS "natosha.edmonds@sagebase.org";
CREATE USER IF NOT EXISTS "kevin.boske@sagebase.org";
CREATE USER IF NOT EXISTS "brad.macdonald@sagebase.org";
CREATE USER IF NOT EXISTS "robert.allaway@sagebase.org";
CREATE USER IF NOT EXISTS "nicholas.lee@sagebase.org";
CREATE USER IF NOT EXISTS "victor.baham@sagebase.org";
CREATE USER IF NOT EXISTS "meghasyam@sagebase.org";
CREATE USER IF NOT EXISTS "pranav.anbarasu@sagebase.org";
CREATE USER IF NOT EXISTS "elias.chaibub.neto@sagebase.org";
CREATE USER IF NOT EXISTS "bryan.fauble@sagebase.org";
CREATE USER IF NOT EXISTS "john.hill@sagebase.org";
CREATE USER IF NOT EXISTS "bruce.hoff@sagebase.org";
CREATE USER IF NOT EXISTS "marco.marasca@sagebase.org";
CREATE USER IF NOT EXISTS "sandhra.sokhal@sagebase.org ";
CREATE USER IF NOT EXISTS "adam.hindman@sagebase.org";
CREATE USER IF NOT EXISTS "jessica.malenfant@sagebase.org";
CREATE USER IF NOT EXISTS "pierrette.lo@sagebase.org";
CREATE USER IF NOT EXISTS "ann.novakowski@sagebase.org";
CREATE USER IF NOT EXISTS "christine.suver@sagebase.org";
CREATE USER IF NOT EXISTS "adam.taylor@sagebase.org";
CREATE USER IF NOT EXISTS "sophia.jobe@sagebase.org";
CREATE USER IF NOT EXISTS "thomas.schaffter@sagebase.org";
CREATE USER IF NOT EXISTS "jake.albrecht@sagebase.org";
CREATE USER IF NOT EXISTS "solly.sieberts@sagebase.org";
CREATE USER IF NOT EXISTS "arti.singh@sagebase.org";
CREATE USER IF NOT EXISTS "dan.lu@sagebase.org";
CREATE USER IF NOT EXISTS "jessica.britton@sagebase.org";
