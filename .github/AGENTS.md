<!-- Last reviewed: 2026-04 -->

## Overview

CI/CD workflows and shared actions for this repository.

## Workflows

### `ci.yaml` — main deployment pipeline

Triggers on push to `dev` or `main`. Jobs run only on the branch where they are relevant:

| Job | Trigger branch | What it does | Notable dependency |
|-----|---------------|--------------|-------------------|
| `schemachange_synapse_data_warehouse_dev` | `dev` | Deploys `synapse_data_warehouse/` to `SYNAPSE_DATA_WAREHOUSE_DEV` as `synapse_data_warehouse_dev_admin`, then runs `dbt run --selector synapse_data_warehouse --target dev` | — |
| `schemachange_synapse_data_warehouse_prod` | `main` | Deploys `synapse_data_warehouse/` to `SYNAPSE_DATA_WAREHOUSE` as `synapse_data_warehouse_admin`, then runs `dbt run --selector synapse_data_warehouse --target prod` | — |
| `schemachange_sage` | `main` | Deploys `sage/` to `SAGE` as `sage_admin`, then runs `dbt run --selector sage --target prod` | `needs: schemachange_synapse_data_warehouse_prod` |
| `schemachange_admin` | `main` | Runs all four `admin/` schemachange subdirs in order (warehouses → policies → ownership_grants → future_grants) | `needs: schemachange_synapse_data_warehouse_prod` |
| `snowsql_admin` | `main` | Runs `admin/*.sql` files via `snow sql` (users, roles, databases, integrations, grants) | `needs: schemachange_admin` |

The `schemachange_admin` → `snowsql_admin` dependency means all DDL migrations always precede the idempotent grant scripts.

### `test_with_clone.yaml` — PR validation

Triggers on pull requests targeting `dev`. Skipped if the `skip_cloning` label is present.

1. Zero-copy clones `SYNAPSE_DATA_WAREHOUSE_DEV` → `SYNAPSE_DATA_WAREHOUSE_DEV_{branch}` (branch name sanitized to alphanumeric + underscores)
2. Creates a `<CLONE>_PROXY_ADMIN` account role, transfers ownership of all inter-schema objects (tasks, dynamic tables) and database roles in the clone to it, then grants it to `DATA_ENGINEER` so the clone admin can act through the proxy
3. Applies `synapse_data_warehouse/` schemachange migrations to the clone
4. Configures dbt and runs `dbt run --selector synapse_data_warehouse --target clone` against the clone
5. Tears down the clone when the PR is closed

**Maintenance:** When a new schema is added to `synapse_data_warehouse/`, or RBAC is updated for an existing schema, ensure the `test_with_clone.yml` grant management steps are updated to reflect the new RBAC. This is especially important for schemas that contain tasks or dynamic tables, as ownership must be transferred to the clone proxy admin role for grants (for example, MONITOR on tasks) to be applied correctly in the cloned environment. See RDS_RAW and RDS_LANDING in test_with_clone.yml for recent examples of the required grant management updates for proper clone setup.

**Branch naming requirement:** Feature branches must start with `snow-` (e.g., `snow-407-feature`) for the `test_with_clone.yaml` workflow to trigger.

## Shared actions

### `actions/configure-snowflake-cli/`

Sets up the Snowflake CLI (`snow`) with private key authentication. Accepts:
- `PRIVATE_KEY_PASSPHRASE`
- `PRIVATE_KEY`
- `ACCOUNT`
- `USER`

Used by all jobs in both workflows.

### `actions/configure-dbt/`

Installs dbt (Snowflake adapter) via uv and writes a `~/.dbt/profiles.yml` for the given role/database/target. Accepts the same credentials as `configure-snowflake-cli` plus `ROLE`, `DATABASE`, and `TARGET_NAME`.

Used alongside `configure-snowflake-cli` in the three dbt-running `ci.yaml` jobs and in `test_with_clone.yaml`'s clone job.

## Secrets and variables

All credentials are stored as GitHub Actions secrets/vars under the `dev` and `prod` environments. Key names:

- `SNOWSQL_ACCOUNT` — Snowflake account identifier
- `ADMIN_SERVICE_USER` — service account username
- `ADMIN_SERVICE_PRIVATE_KEY` / `ADMIN_SERVICE_PASS_PHRASE` — key pair auth
- `SNOWFLAKE_SYNAPSE_DATA_WAREHOUSE_DATABASE` — database name (differs per environment)
- `SNOWFLAKE_SYNAPSE_STAGE_STORAGE_INTEGRATION`, `SNOWFLAKE_SYNAPSE_STAGE_URL`
- `SNOWFLAKE_SNAPSHOTS_STAGE_STORAGE_INTEGRATION`, `SNOWFLAKE_SNAPSHOTS_STAGE_URL`
- `SAML2_ISSUER`, `SAML2_SSO_URL`, `SAML2_X509_CERT` — SAML integration secrets (prod only)
