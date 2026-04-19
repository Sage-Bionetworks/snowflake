# ── Role grants ────────────────────────────────────────────────────────────────
# Two kinds live here:
#   1. Role → Role  (hierarchy, e.g. GENIE_ADMIN → SYSADMIN)
#   2. Role → User  (assignment, e.g. DATA_ENGINEER → thomas.yu@sagebase.org)
#
# provider: snowflake.securityadmin — SECURITYADMIN is required for all GRANT ROLE.
# Mirrors: admin/grants.sql role-assignment sections.

# ── Role hierarchy (role → parent role) ───────────────────────────────────────

locals {
  role_to_role = {
    # Domain roles rolled up into SYSADMIN so admins can switch to them directly
    "GENIE_ADMIN->SYSADMIN"   = { role = "GENIE_ADMIN",   parent = "SYSADMIN" }
    "AD->SYSADMIN"            = { role = "AD",            parent = "SYSADMIN" }
    "NF_ADMIN->SYSADMIN"      = { role = "NF_ADMIN",      parent = "SYSADMIN" }
    "SCIDATA_ADMIN->SYSADMIN" = { role = "SCIDATA_ADMIN", parent = "SYSADMIN" }
    "FAIR->SYSADMIN"          = { role = "FAIR",          parent = "SYSADMIN" }
    "DPE_OPS->SYSADMIN"       = { role = "DPE_OPS",       parent = "SYSADMIN" }
    "GOVERNANCE->SYSADMIN"    = { role = "GOVERNANCE",    parent = "SYSADMIN" }
    "SAGE_LEADERS->SYSADMIN"  = { role = "SAGE_LEADERS",  parent = "SYSADMIN" }
    "DATA_ENGINEER->SYSADMIN" = { role = "DATA_ENGINEER", parent = "SYSADMIN" }
    "MASKING_ADMIN->SYSADMIN" = { role = "MASKING_ADMIN", parent = "SYSADMIN" }
    "TASKADMIN->DATA_ENGINEER" = { role = "TASKADMIN",    parent = "DATA_ENGINEER" }

    # SDW domain roles
    "SDW_ADMIN->SYSADMIN"              = { role = "SYNAPSE_DATA_WAREHOUSE_ADMIN",         parent = "SYSADMIN" }
    "SDW_DEV_ADMIN->SYSADMIN"          = { role = "SYNAPSE_DATA_WAREHOUSE_DEV_ADMIN",     parent = "SYSADMIN" }
    "SDW_ANALYST->SDW_ADMIN"           = { role = "SYNAPSE_DATA_WAREHOUSE_ANALYST",       parent = "SYNAPSE_DATA_WAREHOUSE_ADMIN" }
    "SDW_DEV_ANALYST->SDW_DEV_ADMIN"   = { role = "SYNAPSE_DATA_WAREHOUSE_DEV_ANALYST",   parent = "SYNAPSE_DATA_WAREHOUSE_DEV_ADMIN" }
    "SDW_ANALYST->AD"                  = { role = "SYNAPSE_DATA_WAREHOUSE_ANALYST",       parent = "AD" }

    # DATA_ANALYTICS is inherited by several leadership/domain roles
    "DA->SAGE_LEADERS"  = { role = "DATA_ANALYTICS", parent = "SAGE_LEADERS" }
    "DA->SCIDATA_ADMIN" = { role = "DATA_ANALYTICS", parent = "SCIDATA_ADMIN" }
    "DA->NF_ADMIN"      = { role = "DATA_ANALYTICS", parent = "NF_ADMIN" }
    "DA->GENIE_ADMIN"   = { role = "DATA_ANALYTICS", parent = "GENIE_ADMIN" }
    "DA->GOVERNANCE"    = { role = "DATA_ANALYTICS", parent = "GOVERNANCE" }
  }
}

resource "snowflake_grant_account_role" "role_to_role" {
  for_each         = local.role_to_role
  provider         = snowflake.securityadmin
  role_name        = each.value.role
  parent_role_name = each.value.parent
}

# ── Role → User assignments ────────────────────────────────────────────────────

locals {
  accountadmin_users = toset([
    "x.schildwachter@sagebase.org",
    "khai.do@sagebase.org",
    "phil.snyder@sagebase.org",
  ])

  sysadmin_users = toset([
    "x.schildwachter@sagebase.org",
    "phil.snyder@sagebase.org",
    "DPE_SERVICE",
  ])

  data_engineer_users = toset([
    "phil.snyder@sagebase.org",
    "rixing.xu@sagebase.org",
    "thomas.yu@sagebase.org",
    "brad.macdonald@sagebase.org",
    "bryan.fauble@sagebase.org",
    "nick.grosenbacher@sagebase.org",
    "jenny.medina@sagebase.org",
    "DPE_SERVICE",
  ])

  genie_admin_users = toset([
    "alexander.paynter@sagebase.org",
    "xindi.guo@sagebase.org",
    "chelsea.nayan@sagebase.org",
    "rixing.xu@sagebase.org",
    "adam.taylor@sagebase.org",
    "GENIE_SERVICE",
  ])

  ad_users = toset([
    "samia.ahmed@sagebase.org",
  ])

  nf_admin_users = toset([
    "anh.nguyet.vu@sagebase.org",
    "thomas.yu@sagebase.org",
  ])

  scidata_admin_users = toset([
    "susheel.varma@sagebase.org",
    "thomas.yu@sagebase.org",
  ])

  masking_admin_users = toset([
    "thomas.yu@sagebase.org",
  ])

  dpe_ops_users = toset([
    "thomas.yu@sagebase.org",
    "sophia.jobe@sagebase.org",
  ])

  governance_users = toset([
    "christine.suver@sagebase.org",
    "kimberly.corrigan@sagebase.org",
    "ann.novakowski@sagebase.org",
    "anthony.pena@sagebase.org",
    "samia.ahmed@sagebase.org",
    "jonathan.liaw-gray@sagebase.org",
    "samuel.cason@sagebase.org",
    "amelia.weixler@sagebase.org",
  ])

  fair_users = toset([
    "anthony.williams@sagebase.org",
    "loren.wolfe@sagebase.org",
    "lingling.peng@sagebase.org",
    "gianna.jordan@sagebase.org",
    "mieko.hashimoto@sagebase.org",
    "andrew.lamb@sagebase.org",
    "milen.nikolov@sagebase.org",
    "amy.heiser@sagebase.org",
  ])

  sage_leaders_users = toset([
    "luca.foschini@sagebase.org",
    "alberto.pepe@sagebase.org",
    "susheel.varma@sagebase.org",
    "christine.suver@sagebase.org",
    "mackenzie.wildman@sagebase.org",
    "amy.heiser@sagebase.org",
    "brandon.morgan@sagebase.org",
    "thomas.yu@sagebase.org",
    "milen.nikolov@sagebase.org",
    "andrea.varsavsky@sagebase.org",
    "kim.baggett@sagebase.org",
  ])
}

resource "snowflake_grant_account_role" "accountadmin_to_users" {
  for_each  = local.accountadmin_users
  provider  = snowflake.securityadmin
  role_name = "ACCOUNTADMIN"
  user_name = each.value
}

resource "snowflake_grant_account_role" "sysadmin_to_users" {
  for_each  = local.sysadmin_users
  provider  = snowflake.securityadmin
  role_name = "SYSADMIN"
  user_name = each.value
}

resource "snowflake_grant_account_role" "data_engineer_to_users" {
  for_each  = local.data_engineer_users
  provider  = snowflake.securityadmin
  role_name = "DATA_ENGINEER"
  user_name = each.value
}

resource "snowflake_grant_account_role" "genie_admin_to_users" {
  for_each  = local.genie_admin_users
  provider  = snowflake.securityadmin
  role_name = "GENIE_ADMIN"
  user_name = each.value
}

resource "snowflake_grant_account_role" "ad_to_users" {
  for_each  = local.ad_users
  provider  = snowflake.securityadmin
  role_name = "AD"
  user_name = each.value
}

resource "snowflake_grant_account_role" "nf_admin_to_users" {
  for_each  = local.nf_admin_users
  provider  = snowflake.securityadmin
  role_name = "NF_ADMIN"
  user_name = each.value
}

resource "snowflake_grant_account_role" "scidata_admin_to_users" {
  for_each  = local.scidata_admin_users
  provider  = snowflake.securityadmin
  role_name = "SCIDATA_ADMIN"
  user_name = each.value
}

resource "snowflake_grant_account_role" "masking_admin_to_users" {
  for_each  = local.masking_admin_users
  provider  = snowflake.securityadmin
  role_name = "MASKING_ADMIN"
  user_name = each.value
}

resource "snowflake_grant_account_role" "dpe_ops_to_users" {
  for_each  = local.dpe_ops_users
  provider  = snowflake.securityadmin
  role_name = "DPE_OPS"
  user_name = each.value
}

resource "snowflake_grant_account_role" "governance_to_users" {
  for_each  = local.governance_users
  provider  = snowflake.securityadmin
  role_name = "GOVERNANCE"
  user_name = each.value
}

resource "snowflake_grant_account_role" "fair_to_users" {
  for_each  = local.fair_users
  provider  = snowflake.securityadmin
  role_name = "FAIR"
  user_name = each.value
}

resource "snowflake_grant_account_role" "sage_leaders_to_users" {
  for_each  = local.sage_leaders_users
  provider  = snowflake.securityadmin
  role_name = "SAGE_LEADERS"
  user_name = each.value
}

# DATA_ANALYTICS is granted to a large set of users (all analysts + team members)
resource "snowflake_grant_account_role" "data_analytics_to_users" {
  for_each = toset([
    "diep.thach@sagebase.org",
    "rixing.xu@sagebase.org",
    "thomas.yu@sagebase.org",
    "anh.nguyet.vu@sagebase.org",
    "luca.foschini@sagebase.org",
    "xindi.guo@sagebase.org",
    "phil.snyder@sagebase.org",
    "chelsea.nayan@sagebase.org",
    "alexander.paynter@sagebase.org",
    "x.schildwachter@sagebase.org",
    "kevin.boske@sagebase.org",
    "brad.macdonald@sagebase.org",
    "robert.allaway@sagebase.org",
    "victor.baham@sagebase.org",
    "elias.chaibub.neto@sagebase.org",
    "bryan.fauble@sagebase.org",
    "john.hill@sagebase.org",
    "bruce.hoff@sagebase.org",
    "marco.marasca@sagebase.org",
    "sandhra.sokhal@sagebase.org",
    "adam.hindman@sagebase.org",
    "jessica.malenfant@sagebase.org",
    "ann.novakowski@sagebase.org",
    "christine.suver@sagebase.org",
    "adam.taylor@sagebase.org",
    "sophia.jobe@sagebase.org",
    "thomas.schaffter@sagebase.org",
    "solly.sieberts@sagebase.org",
    "dan.lu@sagebase.org",
    "jessica.britton@sagebase.org",
    "zoe.leanza@sagebase.org",
    "jay.hodgson@sagebase.org",
    "milan.vu@sagebase.org",
    "ashley.clayton@sagebase.org",
    "verena.chung@sagebase.org",
    "jineta.banerjee@sagebase.org",
    "jenny.medina@sagebase.org",
    "sonia.carlson@sagebase.org",
    "anthony.williams@sagebase.org",
    "loren.wolfe@sagebase.org",
    "lingling.peng@sagebase.org",
    "gianna.jordan@sagebase.org",
    "mieko.hashimoto@sagebase.org",
    "andrew.lamb@sagebase.org",
    "milen.nikolov@sagebase.org",
    "amy.heiser@sagebase.org",
    "rchai@sagebase.org",
    "maria.diaz@sagebase.org",
    "gaia.andreoletti@sagebase.org",
    "susheel.varma@sagebase.org",
    "amber.nelson@sagebase.org",
    "tiara.adams@sagebase.org",
    "william.poehlman@sagebase.org",
    "alberto.pepe@sagebase.org",
    "jessica.vera@sagebase.org",
    "kimberly.corrigan@sagebase.org",
    "mackenzie.wildman@sagebase.org",
    "aditi.gopalan@sagebase.org",
    "angie.bowen@sagebase.org",
    "aditya.nath@sagebase.org",
    "james.moon@sagebase.org",
    "orion.banks@sagebase.org",
    "jo.scanlan@sagebase.org",
    "trisha.zintel@sagebase.org",
    "anthony.pena@sagebase.org",
    "bishoy.kamel@sagebase.org",
    "andrea.varsavsky@sagebase.org",
    "serghei.mangul@sagebase.org",
    "jaclyn.beck@sagebase.org",
    "ziwei.pan@sagebase.org",
    "karina.leal@sagebase.org",
    "ann.campton@sagebase.org",
    "savitha.sangameswaran@sagebase.org",
    "vanessa.barone@sagebase.org",
    "jonathan.liaw-gray@sagebase.org",
    "laura.heath@sagebase.org",
    "melissa.klein@sagebase.org",
    "sarah.mansfield@sagebase.org",
    "andree-anne.berthiaume@sagebase.org",
    "dottie.young@sagebase.org",
    "jordan.driscoll@sagebase.org",
    "ram.ayyala@sagebase.org",
    "beatriz.saldana@sagebase.org",
    "tera.derita@sagebase.org",
    "belinda.garana@sagebase.org",
    "emma.costa@sagebase.org",
    "julia.gray@sagebase.org",
    "luisa.chekrygin@sagebase.org",
    "laurielle.roberson@sagebase.org",
    "samuel.cason@sagebase.org",
    "amelia.weixler@sagebase.org",
  ])
  provider  = snowflake.securityadmin
  role_name = "DATA_ANALYTICS"
  user_name = each.value
}
