# ── Account security policies ──────────────────────────────────────────────────
# Mirrors: admin/policies/V1.10.0 + V1.10.1 + V1.17.0
# ACCOUNTADMIN is the default provider in this root module.
#
# NOTE on applying policies to accounts/users:
# Snowflake requires UNSET before SET at the account level (no FORCE in all cases).
# The attachment resources below are commented out for objects that need manual
# attention on first apply.  Uncomment once the existing policy has been unset.

# ── Password policy ───────────────────────────────────────────────────────────
resource "snowflake_password_policy" "default" {
  database              = "POLICY_DB"
  schema                = "PUBLIC"
  name                  = "PASSWORD_POLICY"
  password_min_length   = 14
  password_max_age_days = 0  # Never expire — SSO users have no password anyway
}

# ── Session policies ──────────────────────────────────────────────────────────
resource "snowflake_session_policy" "admin_timeout" {
  name                         = "ADMIN_TIMEOUT_POLICY"
  session_idle_timeout_mins    = 15
  session_ui_idle_timeout_mins = 15
  comment                      = "Short idle timeout for admin-role sessions"
}

# ── Authentication policies ───────────────────────────────────────────────────
# Three tiers: service accounts (password only), admins (SAML + password), users (SAML only)

resource "snowflake_authentication_policy" "service_account" {
  name                   = "SERVICE_ACCOUNT_AUTHENTICATION_POLICY"
  authentication_methods = ["PASSWORD"]
  comment                = "Service accounts use key-pair / password; no SAML"
}

resource "snowflake_authentication_policy" "admin" {
  name                   = "ADMIN_AUTHENTICATION_POLICY"
  authentication_methods = ["SAML", "PASSWORD"]
  security_integrations  = ["GOOGLE_SSO", "JUMPCLOUD"]
  comment                = "Human admins: SSO preferred, password allowed for break-glass"
}

resource "snowflake_authentication_policy" "user" {
  name                   = "USER_AUTHENTICATION_POLICY"
  authentication_methods = ["SAML"]
  security_integrations  = ["GOOGLE_SSO"]
  comment                = "Standard users: SAML (Google SSO) only"
}

# ── Policy attachments ────────────────────────────────────────────────────────
# Attaching policies to specific admin users; all others fall through to the
# account-level policy.  Attach resources only after verifying no existing
# policy is set on the target user (Snowflake rejects SET without prior UNSET).

resource "snowflake_user_authentication_policy_attachment" "admin_users" {
  for_each = toset([
    "thomas.yu@sagebase.org",
    "khai.do@sagebase.org",
    "x.schildwachter@sagebase.org",
    "phil.snyder@sagebase.org",
  ])
  user_name                  = each.value
  authentication_policy_name = snowflake_authentication_policy.admin.fully_qualified_name
}

resource "snowflake_user_authentication_policy_attachment" "service_accounts" {
  for_each = toset([
    "DPE_SERVICE",
    "DEVELOPER_SERVICE",
    "ADMIN_SERVICE",
    "GENIE_SERVICE",
  ])
  user_name                  = each.value
  authentication_policy_name = snowflake_authentication_policy.service_account.fully_qualified_name
}
