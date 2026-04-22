<!-- Last reviewed: 2026-04 -->

## Project

Manages all Snowflake account-level configuration: user/role creation, warehouse provisioning, storage/SAML integrations, RBAC grants, masking policies, and ownership transfers. Changes here affect all databases and all users — treat this directory as infrastructure-as-code.

## Deployment order (CI, push to `main` only)

CI runs these steps in strict order via `schemachange_admin` → `snowsql_admin` job dependency:

1. `schemachange admin/warehouses` — as `SYSADMIN`
2. `schemachange admin/policies` — as `ACCOUNTADMIN`
3. `schemachange admin/ownership_grants` — as `SECURITYADMIN`
4. `schemachange admin/future_grants` — as `SECURITYADMIN`
5. `snow sql -f admin/users.sql` — as `USERADMIN`
6. `snow sql -f admin/roles.sql` — as `SYSADMIN`
7. `snow sql -f admin/databases.sql` — as `SYSADMIN`
8. `snow sql -f admin/integrations.sql` — as `ACCOUNTADMIN` (secrets passed as `--variable` flags)
9. `snow sql -f admin/applications/grants.sql` — as `SECURITYADMIN`
10. `snow sql -f admin/grants.sql` — as `SECURITYADMIN`

The `snowsql_admin` job has `needs: schemachange_admin`, so schemachange steps always run before `snow sql` steps.

## Subdirectories

| Directory | Contents | Deployed by | Role |
|-----------|----------|-------------|------|
| `admin/warehouses/` | Warehouse DDL | schemachange | SYSADMIN |
| `admin/policies/` | Masking policy DDL | schemachange | ACCOUNTADMIN |
| `admin/ownership_grants/` | `GRANT OWNERSHIP` transfers | schemachange | SECURITYADMIN |
| `admin/future_grants/` | `GRANT ... ON FUTURE OBJECTS IN SCHEMA` | schemachange | SECURITYADMIN |

See each subdirectory's `CLAUDE.md` for specifics.

## Account-level role hierarchy

```
ACCOUNTADMIN
  └── SYSADMIN
        └── DATA_ENGINEER        ← developers/service accounts
  └── SECURITYADMIN
  └── USERADMIN
  └── MASKING_ADMIN
  └── TASKADMIN
```

All custom account roles must be inherited by `SYSADMIN` (or a role already under it). This is required so that `SYSADMIN` can manage objects created by those roles.

## RBAC for `SYNAPSE_DATA_WAREHOUSE` databases

The `SYNAPSE_DATA_WAREHOUSE` and `SYNAPSE_DATA_WAREHOUSE_DEV` databases use a structured database-role-based access pattern. See the [Role and Privilege Management](https://sagebionetworks.jira.com/wiki/spaces/DPE/pages/4076863503) and [Managing Object Privileges](https://sagebionetworks.jira.com/wiki/spaces/DPE/pages/4115366084) Confluence pages for full details.

**Summary:** Each schema is governed by a set of database roles scoped to that schema:

```
{DATABASE}_PROXY_ADMIN          ← account role; owns the cross-schema database roles below
  └── {SCHEMA}_ALL_ADMIN        ← owns all objects in schema; granted OWNERSHIP on schema
        ├── {SCHEMA}_TABLE_READ
        ├── {SCHEMA}_VIEW_READ
        ├── {SCHEMA}_STAGE_READ
        ├── {SCHEMA}_TASK_READ
        ├── {SCHEMA}_STREAM_READ
        └── {SCHEMA}_ALL_DEVELOPER  ← inherited by DATA_ENGINEER account role
```

- **Database roles** cannot be assumed directly by users; they must be inherited by account roles.
- **Proxy admin** roles are account roles that own database roles and hold any account-level privileges needed (e.g., `EXECUTE MANAGED TASK`). This keeps functional and access-based role concerns separate.
- **Only new object types** need role and privilege setup. Once future grants are in place, new objects of the same type are covered automatically.

## RBAC for `SAGE` database

The `SAGE` database uses a simpler two-role model per schema. See the [Analyst Role Hierarchy and Privilege Management](https://sagebionetworks.jira.com/wiki/spaces/DPE/pages/4315217948) Confluence page for full details.

**Summary:** Each schema has two account roles (not database roles):
- `{SCHEMA}_ADMIN` — write/ownership privileges; inherited by `SAGE_ADMIN`
- `{SCHEMA}_ANALYST` — read-only privileges; inherited by `DATA_ANALYTICS`

Analyst roles are owned by `USERADMIN`. Access requests and role inheritance changes must go through DPE.

## Conventions

**Versioned file naming:** `V{major}.{minor}.{patch}__{description}.sql`. The versioning sequence is shared across all schemachange-managed directories under `admin/` (i.e., `warehouses/`, `policies/`, `ownership_grants/`, `future_grants/` all share the same version number sequence, currently in the V1.x range).

**Ownership transfer syntax:** Always use `REVOKE CURRENT GRANTS`:
```sql
GRANT OWNERSHIP ON {{objects}} IN SCHEMA db.schema TO ROLE new_owner REVOKE CURRENT GRANTS;
```

**Service accounts:** `ADMIN_SERVICE` (ACCOUNTADMIN), `DEVELOPER_SERVICE` (DATA_ENGINEER), `DPE_SERVICE` (SYSADMIN + DATA_ENGINEER). Do not create new service accounts without updating `admin/users.sql`.

**Warehouse standards:** All warehouses: `warehouse_type = STANDARD`, `initially_suspended = TRUE`, `auto_resume = TRUE`, `auto_suspend = 60`. The Tableau warehouse uses `auto_suspend = 300` (longer for query cache warm-up).

## Constraints

- **`admin/policies/` requires ACCOUNTADMIN** — masking policy DDL requires account-admin privileges.
- **SAML integration variables are secrets** — `saml2_issuer`, `saml2_sso_url`, `saml2_x509_cert` are passed as `--variable` flags from GitHub secrets; never hardcode them.

