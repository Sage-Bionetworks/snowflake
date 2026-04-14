<!-- Last reviewed: 2026-04 -->

## Project

Manages all Snowflake account-level configuration: user/role creation, warehouse provisioning, storage/SAML integrations, RBAC grants, masking policies, and ownership transfers. Changes here affect all databases and all users — treat this directory as infrastructure-as-code.

## Commands

```bash
# Executed by CI on push to main (different roles per script):
snow sql -f admin/users.sql          # USERADMIN
snow sql -f admin/roles.sql          # SYSADMIN
snow sql -f admin/databases.sql      # SYSADMIN
snow sql -f admin/integrations.sql \
  --variable saml2_issuer="..." \
  --variable saml2_sso_url="..." \
  --variable saml2_x509_cert="..."   # ACCOUNTADMIN

snow sql -f admin/grants.sql         # SECURITYADMIN
snow sql -f admin/applications/grants.sql

# Versioned migrations (schemachange, run by CI):
schemachange --connection-name default --root-folder admin/warehouses --snowflake-role SYSADMIN
schemachange --connection-name default --root-folder admin/policies --snowflake-role ACCOUNTADMIN
schemachange --connection-name default --root-folder admin/ownership_grants --snowflake-role SECURITYADMIN
schemachange --connection-name default --root-folder admin/future_grants --snowflake-role SECURITYADMIN
```

## Architecture

### Three separate grant file types — never mix them

| Location | What goes here | Executed by | Why separate |
|----------|---------------|-------------|--------------|
| `admin/grants.sql` | Account role grants, database usage, schema privileges, object SELECT/REFERENCES | SECURITYADMIN | Idempotent, re-runnable |
| `admin/ownership_grants/V*.sql` | `GRANT OWNERSHIP ... REVOKE CURRENT GRANTS` | SECURITYADMIN | Side effect: auto-suspends tasks. Must run exactly once. |
| `admin/future_grants/V*.sql` | `GRANT ... ON FUTURE OBJECTS IN SCHEMA` | SECURITYADMIN | Prevents privilege gaps on new objects; separate tracking |

### RBAC role hierarchy

Account-level roles (top to bottom):
```
ACCOUNTADMIN
  └── SYSADMIN
        └── DATA_ENGINEER        ← developers/service accounts
              └── (database roles via GRANT DATABASE ROLE)
  └── SECURITYADMIN
  └── USERADMIN
  └── MASKING_ADMIN
  └── TASKADMIN
```

Per-database namespace pattern (database roles, not account roles):
```
{DATABASE}_PROXY_ADMIN            ← account role; owns the database roles below
  └── {SCHEMA}_ALL_ADMIN          ← owns all objects in schema
        ├── {SCHEMA}_TABLE_READ
        ├── {SCHEMA}_VIEW_READ
        ├── {SCHEMA}_STAGE_READ
        ├── {SCHEMA}_TASK_READ
        ├── {SCHEMA}_STREAM_READ
        └── {SCHEMA}_ALL_DEVELOPER  ← granted to DATA_ENGINEER account role
```

Prod databases use `SYNAPSE_DATA_WAREHOUSE_PROXY_ADMIN`; dev uses `SYNAPSE_DATA_WAREHOUSE_DEV_PROXY_ADMIN`.

### Adding a new object type to a schema

When introducing a new object type (e.g., FUNCTION, STREAM) to an existing schema, you are responsible for the full RBAC setup:

1. In `admin/grants.sql`: grant OWNERSHIP ON FUTURE `{TYPE}` to `{SCHEMA}_ALL_ADMIN`
2. Create `{SCHEMA}_{TYPE}_READ` database role
3. Grant type-specific privileges (e.g., USAGE for functions, SELECT for tables) to the read role
4. Grant read role to `{SCHEMA}_ALL_DEVELOPER`
5. Add `admin/future_grants/V{next}__schema_future_{type}.sql` for both prod and dev databases
6. Add `admin/ownership_grants/V{next}__schema_ownership_{type}.sql` if transferring existing objects

## Conventions

**Ownership transfer syntax:** Always use `REVOKE CURRENT GRANTS` when transferring ownership:
```sql
GRANT OWNERSHIP ON SCHEMA db.schema TO ROLE new_owner REVOKE CURRENT GRANTS;
```

**Versioned file naming:** `V{major}.{minor}.{patch}__{description}.sql` — ownership_grants and future_grants maintain their own version sequences (starting at V1.x), separate from the synapse_data_warehouse V2.x sequence.

**Service accounts:** `ADMIN_SERVICE` (ACCOUNTADMIN), `DEVELOPER_SERVICE` (DATA_ENGINEER), `DPE_SERVICE` (SYSADMIN + DATA_ENGINEER). Do not create new service accounts without updating `admin/users.sql`.

**Warehouse standards:** All warehouses: `warehouse_type = STANDARD`, `initially_suspended = TRUE`, `auto_resume = TRUE`. Tableau warehouse uses `auto_suspend = 300` (longer for query cache warm-up); all others use 60–90 seconds.

## Constraints

- **Ownership grants must run separately from `grants.sql`** — granting ownership on a TASK auto-suspends it, even when the owner doesn't change. Never add `GRANT OWNERSHIP` to `grants.sql`.
- **`admin/policies/` requires ACCOUNTADMIN** — masking policy DDL requires account-admin privileges; do not attempt to run policy scripts as SYSADMIN.
- **SAML integration variables are secrets** — `saml2_issuer`, `saml2_sso_url`, `saml2_x509_cert` are passed as `--variable` flags from GitHub secrets; never hardcode them.

## Anti-Patterns — Do NOT

- **Do NOT add `GRANT OWNERSHIP` statements to `admin/grants.sql`** — side effect auto-suspends tasks (evidence: `admin/ownership_grants/` directory exists specifically because this caused issues in the past).
- **Do NOT skip creating future grants when adding a new schema or object type** — without future grants, new objects created in the schema will not be accessible to `DATA_ENGINEER` or read roles until manually re-granted.
