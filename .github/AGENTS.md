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

1. Procures an RBAC-configured zero-copy clone of `SYNAPSE_DATA_WAREHOUSE_DEV` via `uv run snowclone freeze` (see `packages/snowclone/`), without its `--deploy-folder` — the clone's ownership hierarchy is discovered at runtime, so no per-schema maintenance of this workflow is needed when a schema is added
2. Re-enables `DIRECTORY` on the clone's S3 external stages (a zero-copy-clone quirk; see the inline comment and SNOW-556), then deploys `synapse_data_warehouse/` schemachange and runs `dbt run --selector synapse_data_warehouse --target clone` against the clone — both keyed off the `clone_db` output from step 1
3. Tears down the clone (`uv run snowclone melt`) when the PR is closed

**Branch naming requirement:** Feature branches must start with `snow-` (e.g., `snow-407-feature`) for the `test_with_clone.yaml` workflow to trigger.

### `procure_clone.yaml` — on-demand provisioning

`workflow_dispatch` wrapper around the same `packages/snowclone/` package for ad-hoc
clones of any database (free-form `database` input — not a fixed list). Inputs:
`database`, `environment`, `clone_suffix`, `developer_role`, `deploy_folder`
(blank skips the deploy), `dbt_selector` (blank skips dbt), `action` (procure/teardown),
`dry_run`.

**dbt is layered on in the workflow, not in `snowclone`:** the package only ever
runs schemachange (every database has that); dbt is database-specific, so
`snowclone freeze` emits its resolved clone name as a `clone_db` step output, and
the workflow uses that to run `actions/configure-dbt` + `dbt run --selector
${{ inputs.dbt_selector }}` as its own step, the same way `test_with_clone.yaml`'s
clone job does for `SYNAPSE_DATA_WAREHOUSE`. A caller cloning a database with no dbt
project just leaves `dbt_selector` blank.

**Python version:** The `configure-snowflake-cli` action sets up Python 3.13 and installs `uv`. The clone workflows invoke `uv run snowclone freeze` / `uv run snowclone melt`, which syncs the workspace and installs the `snowclone` package (and its Snowflake connector dependency) on the fly — no separate install step.

## Shared actions

### `actions/configure-snowflake-cli/`

Sets up the Snowflake CLI (`snow`) with private key authentication. Accepts:
- `PRIVATE_KEY_PASSPHRASE`
- `PRIVATE_KEY`
- `ACCOUNT`
- `USER`

Used by jobs across `ci.yaml`, `test_with_clone.yaml`, and `procure_clone.yaml`.

### `actions/configure-dbt/`

Installs dbt (Snowflake adapter) via uv and writes a `~/.dbt/profiles.yml` for the given role/database/target. Accepts the same credentials as `configure-snowflake-cli` plus `ROLE`, `DATABASE`, and `TARGET_NAME`.

Used alongside `configure-snowflake-cli` in the three dbt-running `ci.yaml` jobs and in the clone workflows' dbt steps.

## Secrets and variables

Credentials must be stored as GitHub Actions secrets scoped to the `dev`, `dev_restricted`, or `prod` environments — never at the repository level. A job only resolves a given secret/var if it declares the matching `environment:`, so a repository-level copy of a credential is reachable from any job with no approval gate and defeats the environment protection rules entirely. Every job that touches Snowflake must therefore declare an `environment:`.

`dev_restricted` duplicates `dev`'s values for `test_with_clone.yaml`'s use; keep the two in sync manually when rotating credentials, since there's no way to copy a secret's value between environments programmatically.

Secrets:

- `ADMIN_SERVICE_PRIVATE_KEY` / `ADMIN_SERVICE_PASS_PHRASE` — key pair auth
- `SNOWSQL_ACCOUNT` — Snowflake account identifier
- `SNOWSQL_WAREHOUSE` — warehouse; also picked up by `snow` and schemachange from `SNOWFLAKE_WAREHOUSE`, where it overrides `connections.toml`

Variables:

- `ADMIN_SERVICE_USER` — service account username
- `SNOWFLAKE_SYNAPSE_DATA_WAREHOUSE_DATABASE` — GitHub variable holding the warehouse database name (differs per environment); workflows feed it into the deploy env var below
- `SNOWFLAKE_SYNAPSE_STAGE_STORAGE_INTEGRATION`, `SNOWFLAKE_SYNAPSE_STAGE_URL`
- `SNOWFLAKE_SNAPSHOTS_STAGE_STORAGE_INTEGRATION`, `SNOWFLAKE_SNAPSHOTS_STAGE_URL`
- `STACK`
- `SAML2_ISSUER`, `SAML2_SSO_URL`, `SAML2_X509_CERT` — Google Workspace IdP metadata for the `GOOGLE_SSO` SAML integration (prod only). Variables rather than secrets: these are the IdP's public entity ID, SSO endpoint, and public signing certificate, all published in Google's SAML metadata. Note that `admin/integrations.sql` creates `GOOGLE_SSO` with `IF NOT EXISTS`, so these values only take effect if the integration is absent — they are a recovery seed, not the live config.

**Deploy target env var:** every `schemachange-config.yml` reads a single standardized
env var, `SNOWFLAKE_DEPLOY_DATABASE`, for its target database (and change-history
table). `ci.yaml` sets it per environment; `snowclone` sets it to the clone.
The `synapse_data_warehouse/` config has no default (fails fast — it has dev and prod
deployments); the `sage/` config defaults to `SAGE` (prod-only).
