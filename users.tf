# Create and manage all users

resource "snowflake_saml_integration" "google_saml" {
  provider = snowflake.accountadmin
  name            = "GOOGLE_SSO"
  saml2_provider  = "Custom"
  saml2_issuer    = var.saml2_issuer
  saml2_sso_url   = var.saml2_sso_url
  saml2_x509_cert = var.saml2_x509_cert
  saml2_snowflake_acs_url = "https://mqzfhld-vp00034.snowflakecomputing.com/fed/login"
  saml2_snowflake_issuer_url = "https://mqzfhld-vp00034.snowflakecomputing.com"
  enabled         = true
  saml2_sp_initiated_login_page_label = "GOOGLE_SSO"
  saml2_enable_sp_initiated = true
  saml2_sign_request = true
}

resource "snowflake_user" "user" {
  provider = snowflake.useradmin
  name         = "thomas.yu@sagebase.org"
  login_name   = "thomas.yu@sagebase.org"
}

resource "snowflake_user" "bmacdonald" {
  provider = snowflake.useradmin
  name         = "brad.macdonald@sagebase.org"
  login_name   = "brad.macdonald@sagebase.org"
}

resource "snowflake_user" "rxu" {
  provider = snowflake.useradmin
  name         = "rixing.xu@sagebase.org"
  login_name   = "rixing.xu@sagebase.org"
}

resource "snowflake_user" "dthach" {
  provider = snowflake.useradmin
  name         = "diep.thach@sagebase.org"
  login_name   = "diep.thach@sagebase.org"
}

resource "snowflake_user" "avu" {
  provider = snowflake.useradmin
  name         = "anh.nguyet.vu@sagebase.org"
  login_name   = "anh.nguyet.vu@sagebase.org"
}

resource "snowflake_user" "lfoschini" {
  provider = snowflake.useradmin
  name         = "luca.foschini@sagebase.org"
  login_name   = "luca.foschini@sagebase.org"
}

resource "snowflake_user" "sjobe" {
  provider = snowflake.useradmin
  name         = "sophia.jobe@sagebase.org"
  login_name   = "sophia.jobe@sagebase.org"
}

resource "snowflake_user" "xguo" {
  provider = snowflake.useradmin
  name         = "xindi.guo@sagebase.org"
  login_name   = "xindi.guo@sagebase.org"
}

resource "snowflake_user" "avanderlinden" {
  provider = snowflake.useradmin
  name         = "abby.vanderlinden@sagebase.org"
  login_name   = "abby.vanderlinden@sagebase.org"
}

resource "snowflake_user" "psnyder" {
  provider = snowflake.useradmin
  name         = "phil.snyder@sagebase.org"
  login_name   = "phil.snyder@sagebase.org"
}

resource "snowflake_user" "cnayan" {
  provider = snowflake.useradmin
  name         = "chelsea.nayan@sagebase.org"
  login_name   = "chelsea.nayan@sagebase.org"
}

resource "snowflake_user" "apaynter" {
  provider = snowflake.useradmin
  name         = "alex.paynter@sagebase.org"
  login_name   = "alex.paynter@sagebase.org"
}

resource "snowflake_user" "xschildwachter" {
  provider = snowflake.useradmin
  name         = "x.schildwachter@sagebase.org"
  login_name   = "x.schildwachter@sagebase.org"
}

resource "snowflake_user" "nedmonds" {
  provider = snowflake.useradmin
  name         = "natosha.edmonds@sagebase.org"
  login_name   = "natosha.edmonds@sagebase.org"
}

resource "snowflake_user" "kboske" {
  provider = snowflake.useradmin
  name         = "kevin.boske@sagebase.org"
  login_name   = "kevin.boske@sagebase.org"
}

resource "snowflake_user" "rallaway" {
  provider = snowflake.useradmin
  name         = "robert.allaway@sagebase.org"
  login_name   = "robert.allaway@sagebase.org"
}

resource "snowflake_user" "nlee" {
  provider = snowflake.useradmin
  name         = "nicholas.lee@sagebase.org"
  login_name   = "nicholas.lee@sagebase.org"
}

resource "snowflake_user" "vbaham" {
  provider = snowflake.useradmin
  name         = "victor.baham@sagebase.org"
  login_name   = "victor.baham@sagebase.org"
}

resource "snowflake_user" "gjordan" {
  provider = snowflake.useradmin
  name         = "gianna.jordan@sagebase.org"
  login_name   = "gianna.jordan@sagebase.org"
}
