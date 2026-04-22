<!-- Last reviewed: 2026-04 -->

## Project

schemachange-managed DDL for the `SAGE` analyst database. Contains schemas for domain-specific analytics: citations (DataCite DOI tracking), governance, and Google Analytics 4 aggregates. Deployed to prod only — there is no `SAGE_DEV` database.

## Commands

```bash
# Prod deploy only (no dev environment for SAGE)
schemachange \
  --connection-name default \
  --config-folder sage \
  --snowflake-role sage_admin
```

## Schema layout

| Schema | Contents | Managed by |
|--------|----------|------------|
| `CITATIONS` | DataCite DOI tracking | schemachange |
| `GOOGLE_ANALYTICS_AGGREGATE` | GA4 event aggregates | schemachange |
| `GOVERNANCE` | Governance-related objects | schemachange |
| `AUDIT` | Audit objects | `sage_setup.sql` (SYSADMIN) |
| `AD` | Alzheimer's Data portal objects | `sage_setup.sql` (SYSADMIN) |

## RBAC

The `SAGE` database uses a simplified two-role model per schema (not the database-role-based model used in `SYNAPSE_DATA_WAREHOUSE`). See the [Analyst Role Hierarchy and Privilege Management](https://sagebionetworks.jira.com/wiki/spaces/DPE/pages/4315217948) Confluence page for full details.

**Per-schema account roles:**
- `{SCHEMA}_ADMIN` — write/ownership privileges; inherited by `SAGE_ADMIN`
- `{SCHEMA}_ANALYST` — read-only privileges; inherited by `DATA_ANALYTICS`

Privileges are assigned directly to these account roles (not via intermediate database roles). Role ownership is held by `USERADMIN`. Analysts who need role inheritance changes must request them through DPE.

**`SAGE_ADMIN`** manages the entire `SAGE` database, analogous to `SYNAPSE_DATA_WAREHOUSE_ADMIN` for the data warehouse.

## Script conventions

Follows the same V/R versioning as `synapse_data_warehouse/`:

- **Versioned (`V{major}.{minor}.{patch}__{description}.sql`):** one-time changes
- **Repeatable (`R__{description}.sql`):** idempotent re-runs (e.g., `CREATE OR REPLACE`)

The version sequence in `sage/` is independent of both `synapse_data_warehouse/` (V2.x) and `admin/` (V1.x). Check `SAGE.SCHEMACHANGE.CHANGE_HISTORY` before picking a new version number.

## Constraints

- **Prod only** — never attempt to deploy `sage/` to a dev or PR-clone database. There is no `SAGE_DEV`.
- **Do NOT run `dbt run --selector sage` without `--target prod`** — sage dbt models are disabled for non-prod targets.
