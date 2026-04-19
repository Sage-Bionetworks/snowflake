# ── SSO users ─────────────────────────────────────────────────────────────────
# All human users authenticate via Google SSO (SAML2); no passwords are set.
# A single for_each loop keeps the list DRY and avoids one resource block per person.
# Mirrors: admin/users.sql CREATE USER blocks
#
# Default provider (USERADMIN) creates users.

locals {
  # login_name == name for all SSO users (Google Workspace email = Snowflake login)
  sso_users = toset([
    # Platform
    "diep.thach@sagebase.org",
    "x.schildwachter@sagebase.org",
    "kevin.boske@sagebase.org",
    "john.hill@sagebase.org",
    "bruce.hoff@sagebase.org",
    "marco.marasca@sagebase.org",
    "sandhra.sokhal@sagebase.org",
    "adam.hindman@sagebase.org",
    "jay.hodgson@sagebase.org",
    "nick.grosenbacher@sagebase.org",
    "khai.do@sagebase.org",
    "thomas.schaffter@sagebase.org",
    # Cancer Bio
    "adam.taylor@sagebase.org",
    "chelsea.nayan@sagebase.org",
    "xindi.guo@sagebase.org",
    "alexander.paynter@sagebase.org",
    "aditi.gopalan@sagebase.org",
    "amber.nelson@sagebase.org",
    "jessica.vera@sagebase.org",
    # ADTR
    "victor.baham@sagebase.org",
    "jessica.malenfant@sagebase.org",
    "jessica.britton@sagebase.org",
    "zoe.leanza@sagebase.org",
    "milan.vu@sagebase.org",
    "william.poehlman@sagebase.org",
    "jo.scanlan@sagebase.org",
    "trisha.zintel@sagebase.org",
    "bishoy.kamel@sagebase.org",
    "jaclyn.beck@sagebase.org",
    "karina.leal@sagebase.org",
    "ann.campton@sagebase.org",
    "melissa.klein@sagebase.org",
    "beatriz.saldana@sagebase.org",
    "andree-anne.berthiaume@sagebase.org",
    "jordan.driscoll@sagebase.org",
    "laura.heath@sagebase.org",
    "tiara.adams@sagebase.org",
    "emma.costa@sagebase.org",
    "julia.gray@sagebase.org",
    # SciData Misc
    "ashley.clayton@sagebase.org",
    "vanessa.barone@sagebase.org",
    "savitha.sangameswaran@sagebase.org",
    "ram.ayyala@sagebase.org",
    "angie.bowen@sagebase.org",
    "tera.derita@sagebase.org",
    # NF Rare Disease
    "anh.nguyet.vu@sagebase.org",
    "robert.allaway@sagebase.org",
    "james.moon@sagebase.org",
    "belinda.garana@sagebase.org",
    # Advanced Data Analytics
    "jineta.banerjee@sagebase.org",
    "orion.banks@sagebase.org",
    "ziwei.pan@sagebase.org",
    "aditya.nath@sagebase.org",
    # Digital Health
    "solly.sieberts@sagebase.org",
    "elias.chaibub.neto@sagebase.org",
    "sonia.carlson@sagebase.org",
    # Governance
    "kimberly.corrigan@sagebase.org",
    "anthony.pena@sagebase.org",
    "jonathan.liaw-gray@sagebase.org",
    "samuel.cason@sagebase.org",
    "amelia.weixler@sagebase.org",
    # CNB
    "verena.chung@sagebase.org",
    "rchai@sagebase.org",
    "maria.diaz@sagebase.org",
    "gaia.andreoletti@sagebase.org",
    "serghei.mangul@sagebase.org",
    # Tech
    "anthony.williams@sagebase.org",
    "loren.wolfe@sagebase.org",
    "mieko.hashimoto@sagebase.org",
    "milen.nikolov@sagebase.org",
    "amy.heiser@sagebase.org",
    "christina.parry@sagebase.org",
    "ann.novakowski@sagebase.org",
    "samia.ahmed@sagebase.org",
    "shaun.kalweit@sagebase.org",
    # DPE
    "bryan.fauble@sagebase.org",
    "rixing.xu@sagebase.org",
    "thomas.yu@sagebase.org",
    "jenny.medina@sagebase.org",
    "phil.snyder@sagebase.org",
    "sophia.jobe@sagebase.org",
    "dan.lu@sagebase.org",
    "lingling.peng@sagebase.org",
    "gianna.jordan@sagebase.org",
    "andrew.lamb@sagebase.org",
    # Leadership
    "luca.foschini@sagebase.org",
    "alberto.pepe@sagebase.org",
    "susheel.varma@sagebase.org",
    "christine.suver@sagebase.org",
    "mackenzie.wildman@sagebase.org",
    "andrea.varsavsky@sagebase.org",
    "dottie.young@sagebase.org",
    # Finance
    "brandon.morgan@sagebase.org",
    "barry.webb@sagebase.org",
    "sarah.mansfield@sagebase.org",
    "ranell.nystrom@sagebase.org",
    # Sponsored Research
    "luisa.chekrygin@sagebase.org",
    "laurielle.roberson@sagebase.org",
  ])

  # Users that are currently disabled (departed or inactive).
  # Terraform manages the disabled state; the user resource still exists so grants
  # referencing it don't error, but login is blocked.
  disabled_sso_users = toset([
    "abby.vanderlinden@sagebase.org",
    "anna.greenwood@sagebase.org",
    "arti.singh@sagebase.org",
    "brad.macdonald@sagebase.org",
    "christina.conrad@sagebase.org",
    "drew.duglan@sagebase.org",
    "hayley.sanchez@sagebase.org",
    "james.eddy@sagebase.org",
    "kim.baggett@sagebase.org",
    "lakaija.johnson@sagebase.org",
    "lisa.pasquale@sagebase.org",
    "natosha.edmonds@sagebase.org",
    "nicholas.lee@sagebase.org",
    "pranav.anbarasu@sagebase.org",
    "richard.yaxley@sagebase.org",
    "sarah.chan@sagebase.org",
    "meghasyam@sagebase.org",
  ])
}

resource "snowflake_user" "sso" {
  for_each   = local.sso_users
  name       = each.value
  login_name = each.value
  # No password — authentication is exclusively via Google SSO (SAML2).
  # DEFAULT_SECONDARY_ROLES is kept empty per account policy (admin/users.sql).
  default_secondary_roles_option = "NONE"
}

resource "snowflake_user" "sso_disabled" {
  for_each   = local.disabled_sso_users
  name       = each.value
  login_name = each.value
  disabled   = true
  default_secondary_roles_option = "NONE"
}

# ── Service accounts ───────────────────────────────────────────────────────────
# TYPE = SERVICE users have no password and cannot use the UI.
# Mirrors: admin/users.sql service user blocks

resource "snowflake_service_user" "admin_service" {
  name    = "ADMIN_SERVICE"
  comment = "ACCOUNTADMIN-level service account for Terraform and admin automation"
}

resource "snowflake_service_user" "developer_service" {
  name    = "DEVELOPER_SERVICE"
  comment = "DATA_ENGINEER-level service account for developer automation"
}

resource "snowflake_service_user" "dpe_service" {
  name    = "DPE_SERVICE"
  comment = "SYSADMIN + DATA_ENGINEER service account for DPE CI/CD pipelines"
}

resource "snowflake_service_user" "genie_service" {
  name    = "GENIE_SERVICE"
  comment = "Service user for launching Genie workflows in Snowflake"
}

# ── Legacy service accounts (password-based, disabled) ────────────────────────
# These predate the TYPE=SERVICE model and are kept disabled.

resource "snowflake_legacy_service_user" "dbt_service" {
  name     = "DBT_SERVICE"
  disabled = true
  comment  = "Deprecated dbt service account — superseded by DPE_SERVICE"
}

resource "snowflake_legacy_service_user" "ad_service" {
  name     = "AD_SERVICE"
  disabled = true
  comment  = "Deprecated AD service account"
}
