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
2. Reconfigures RBAC on the clone and deploys `synapse_data_warehouse/` schemachange — all via `uv run snowclone freeze` (see `packages/snowclone/`)
3. Tears down the clone via `uv run snowclone melt` when the PR is closed

The procurement logic lives in **`packages/snowclone/`** (a uv-workspace member),
which discovers the clone's ownership hierarchy at runtime (`SHOW` introspection)
and mirrors it under a single `<CLONE>_PROXY_ADMIN` account role granted to
`DATA_ENGINEER`. **No per-schema maintenance of this workflow is needed** when a
schema is added — the old hardcoded ownership-transfer steps have been replaced by
the package.

### `procure_clone.yaml` — on-demand provisioning

`workflow_dispatch` wrapper around the same `packages/snowclone/` package for ad-hoc
clones of any database (free-form `database` input — not a fixed list). Inputs:
`database`, `environment`, `clone_suffix`, `developer_role`, `deploy_folder`
(blank skips the deploy), `action` (procure/teardown), `dry_run`.

**Branch naming requirement:** Feature branches must start with `snow-` (e.g., `snow-407-feature`) for the `test_with_clone.yaml` workflow to trigger.

**Python version:** The `configure-snowflake-cli` action, used by both workflows, sets up Python 3.13 and installs `uv`. The clone workflows invoke `uv run snowclone freeze` / `uv run snowclone melt`, which syncs the workspace and installs the `snowclone` package (and its Snowflake connector dependency) on the fly — no separate install step.

## Shared actions

### `actions/configure-snowflake-cli/`

Sets up the Snowflake CLI (`snow`) with private key authentication. Accepts:
- `PRIVATE_KEY_PASSPHRASE`
- `PRIVATE_KEY`
- `ACCOUNT`
- `USER`

Used by jobs across `ci.yaml`, `test_with_clone.yaml`, and `procure_clone.yaml`.

## Secrets and variables

All credentials are stored as GitHub Actions secrets/vars under the `dev` and `prod` environments. Key names:

- `SNOWSQL_ACCOUNT` — Snowflake account identifier
- `ADMIN_SERVICE_USER` — service account username
- `ADMIN_SERVICE_PRIVATE_KEY` / `ADMIN_SERVICE_PASS_PHRASE` — key pair auth
- `SNOWFLAKE_SYNAPSE_DATA_WAREHOUSE_DATABASE` — GitHub variable holding the warehouse database name (differs per environment); workflows feed it into the deploy env var below
- `SNOWFLAKE_SYNAPSE_STAGE_STORAGE_INTEGRATION`, `SNOWFLAKE_SYNAPSE_STAGE_URL`
- `SNOWFLAKE_SNAPSHOTS_STAGE_STORAGE_INTEGRATION`, `SNOWFLAKE_SNAPSHOTS_STAGE_URL`

**Deploy target env var:** every `schemachange-config.yml` reads a single standardized
env var, `SNOWFLAKE_DEPLOY_DATABASE`, for its target database (and change-history
table). `ci.yaml` sets it per environment; `snowclone` sets it to the clone.
The `synapse_data_warehouse/` config has no default (fails fast — it has dev and prod
deployments); the `sage/` config defaults to `SAGE` (prod-only).
- `SAML2_ISSUER`, `SAML2_SSO_URL`, `SAML2_X509_CERT` — SAML integration secrets (prod only)
