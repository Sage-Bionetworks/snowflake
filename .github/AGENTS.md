<!-- Last reviewed: 2026-04 -->

## Overview

CI/CD workflows and shared actions for this repository.

## Workflows

### `ci.yaml` — main deployment pipeline

Triggers on push to `dev` or `main`. Jobs run only on the branch where they are relevant:

| Job | Trigger branch | What it does | Notable dependency |
|-----|---------------|--------------|-------------------|
| `schemachange_synapse_data_warehouse_dev` | `dev` | Deploys `synapse_data_warehouse/` to `SYNAPSE_DATA_WAREHOUSE_DEV` as `synapse_data_warehouse_dev_admin` | — |
| `schemachange_synapse_data_warehouse_prod` | `main` | Deploys `synapse_data_warehouse/` to `SYNAPSE_DATA_WAREHOUSE` as `synapse_data_warehouse_admin` | — |
| `schemachange_sage` | `main` | Deploys `sage/` to `SAGE` as `sage_admin` | — |
| `schemachange_admin` | `main` | Runs all four `admin/` schemachange subdirs in order (warehouses → policies → ownership_grants → future_grants) | `needs: schemachange_synapse_data_warehouse_prod` |
| `snowsql_admin` | `main` | Runs `admin/*.sql` files via `snow sql` (users, roles, databases, integrations, grants) | `needs: schemachange_admin` |

The `schemachange_admin` → `snowsql_admin` dependency means all DDL migrations always precede the idempotent grant scripts.

### `test_with_clone.yaml` — PR validation

Triggers on pull requests targeting `dev`. Skipped if the `skip_cloning` label is present.

1. Zero-copy clones `SYNAPSE_DATA_WAREHOUSE_DEV` → `SYNAPSE_DATA_WAREHOUSE_DEV_{branch}` (branch name sanitized to alphanumeric + underscores)
2. Creates a `<CLONE>_PROXY_ADMIN` account role, transfers ownership of all inter-schema objects (tasks, dynamic tables) and database roles in the clone to it, then grants it to `DATA_ENGINEER` so the clone admin can act through the proxy
3. Applies `synapse_data_warehouse/` schemachange migrations to the clone
4. Tears down the clone when the PR is closed

**Maintenance:** When a new schema is added to `synapse_data_warehouse/`, the ownership-transfer and database-role grant steps in `test_with_clone.yml` must be updated to cover it (see `RDS_RAW` as a recent example).

**Branch naming requirement:** Feature branches must start with `snow-` (e.g., `snow-407-feature`) for the `test_with_clone.yaml` workflow to trigger.

**Python version:** The `configure-snowflake-cli` action, which is used by this workflow, uses Python 3.13.

## Shared actions

### `actions/configure-snowflake-cli/`

Sets up the Snowflake CLI (`snow`) with private key authentication. Accepts:
- `PRIVATE_KEY_PASSPHRASE`
- `PRIVATE_KEY`
- `ACCOUNT`
- `USER`

Used by all jobs in both workflows.

## Secrets and variables

All credentials are stored as GitHub Actions secrets/vars under the `dev` and `prod` environments. Key names:

- `SNOWSQL_ACCOUNT` — Snowflake account identifier
- `ADMIN_SERVICE_USER` — service account username
- `ADMIN_SERVICE_PRIVATE_KEY` / `ADMIN_SERVICE_PASS_PHRASE` — key pair auth
- `SNOWFLAKE_SYNAPSE_DATA_WAREHOUSE_DATABASE` — database name (differs per environment)
- `SNOWFLAKE_SYNAPSE_STAGE_STORAGE_INTEGRATION`, `SNOWFLAKE_SYNAPSE_STAGE_URL`
- `SNOWFLAKE_SNAPSHOTS_STAGE_STORAGE_INTEGRATION`, `SNOWFLAKE_SNAPSHOTS_STAGE_URL`
- `SAML2_ISSUER`, `SAML2_SSO_URL`, `SAML2_X509_CERT` — SAML integration secrets (prod only)
