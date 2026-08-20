<!-- Last reviewed: 2026-04 -->

## Overview

CI/CD workflows and shared actions for this repository.

## Workflows

### `ci.yaml` — main deployment pipeline

Triggers on push to `dev` or `main`. Jobs run only on the branch where they are relevant:

| Job | Trigger branch | What it does | Notable dependency |
|-----|---------------|--------------|-------------------|
| `deploy_synapse_data_warehouse_dev` | `dev` | Deploys `synapse_data_warehouse/` to `SYNAPSE_DATA_WAREHOUSE_DEV` as `synapse_data_warehouse_dev_admin`, then runs `dbt run --selector synapse_data_warehouse --target dev` | — |
| `deploy_synapse_data_warehouse_prod` | `main` | Deploys `synapse_data_warehouse/` to `SYNAPSE_DATA_WAREHOUSE` as `synapse_data_warehouse_admin`, then runs `dbt run --selector synapse_data_warehouse --target prod` | — |
| `schemachange_sage` | `main` | Deploys `sage/` to `SAGE` as `sage_admin`, then runs `dbt run --selector sage --target prod` | `needs: deploy_synapse_data_warehouse_prod` |
| `schemachange_admin` | `main` | Runs all four `admin/` schemachange subdirs in order (warehouses → policies → ownership_grants → future_grants) | `needs: deploy_synapse_data_warehouse_prod` |
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

Credentials must be stored as GitHub Actions secrets scoped to the `dev`, `dev_restricted`, or `prod` environments — never at the repository level. A job only resolves a given secret/var if it declares the matching `environment:`, so a repository-level copy of a credential is reachable from any job with no approval gate and defeats the environment protection rules entirely. Every job that touches Snowflake must therefore declare an `environment:`.

`dev_restricted` duplicates `dev`'s values for `test_with_clone.yaml`'s use; keep the two in sync manually when rotating credentials, since there's no way to copy a secret's value between environments programmatically.

Secrets:

- `ADMIN_SERVICE_PRIVATE_KEY` / `ADMIN_SERVICE_PASS_PHRASE` — key pair auth
- `SNOWSQL_ACCOUNT` — Snowflake account identifier
- `SNOWSQL_WAREHOUSE` — warehouse; also picked up by `snow` and schemachange from `SNOWFLAKE_WAREHOUSE`, where it overrides `connections.toml`

Variables:

- `ADMIN_SERVICE_USER` — service account username
- `SNOWFLAKE_SYNAPSE_DATA_WAREHOUSE_DATABASE` — database name (differs per environment)
- `SNOWFLAKE_SYNAPSE_STAGE_STORAGE_INTEGRATION`, `SNOWFLAKE_SYNAPSE_STAGE_URL`
- `SNOWFLAKE_SNAPSHOTS_STAGE_STORAGE_INTEGRATION`, `SNOWFLAKE_SNAPSHOTS_STAGE_URL`
- `STACK`
- `SAML2_ISSUER`, `SAML2_SSO_URL`, `SAML2_X509_CERT` — Google Workspace IdP metadata for the `GOOGLE_SSO` SAML integration (prod only). Variables rather than secrets: these are the IdP's public entity ID, SSO endpoint, and public signing certificate, all published in Google's SAML metadata. Note that `admin/integrations.sql` creates `GOOGLE_SSO` with `IF NOT EXISTS`, so these values only take effect if the integration is absent — they are a recovery seed, not the live config.
