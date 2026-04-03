<!-- Last reviewed: 2026-04 -->

## Project

Sage Bionetworks' Snowflake data warehouse: ingests Synapse platform data (MySQL RDS snapshots + S3 event data), transforms it via dbt, and serves analytics to Tableau, Streamlit dashboards, and ad-hoc SQL consumers. Multiple subsystems (schemachange DDL, dbt transforms, admin governance, Python ELT) each have their own subdirectory with dedicated CLAUDE.md files.

## Stack

- SQL: Snowflake dialect
- Python: 3.10 (finance/Docker), 3.11 (GitHub Actions)
- schemachange: 4.0.1 (schema migration runner)
- dbt: Snowflake adapter (profile name: `transform`)
- SQLFluff: 3.0.6 — lints SQL with `--dialect snowflake --exclude-rules RF05,AM04,LT05,ST07`
- Snowflake CLI (`snow`): latest, used for admin SQL execution
- Pre-commit: SQLFluff hooks enforce SQL formatting automatically

## Commands

```bash
# Admin SQL (executed by CI, role varies by script)
snow sql -f admin/users.sql
snow sql -f admin/roles.sql
snow sql -f admin/databases.sql
snow sql -f admin/grants.sql

# schemachange — synapse_data_warehouse (dev)
schemachange \
  --connection-name default \
  --root-folder synapse_data_warehouse \
  --config-folder synapse_data_warehouse \
  --snowflake-role synapse_data_warehouse_dev_admin

# schemachange — synapse_data_warehouse (prod)
schemachange \
  --connection-name default \
  --root-folder synapse_data_warehouse \
  --config-folder synapse_data_warehouse \
  --snowflake-role synapse_data_warehouse_admin

# schemachange — sage database
schemachange \
  --connection-name default \
  --config-folder sage \
  --snowflake-role sage_admin

# schemachange — admin subsystems (each uses a different role)
schemachange --connection-name default --root-folder admin/warehouses --snowflake-role SYSADMIN
schemachange --connection-name default --root-folder admin/policies --snowflake-role ACCOUNTADMIN
schemachange --connection-name default --root-folder admin/ownership_grants --snowflake-role SECURITYADMIN
schemachange --connection-name default --root-folder admin/future_grants --snowflake-role SECURITYADMIN

# dbt (see transform/CLAUDE.md for full details)
dbt run --selector synapse_data_warehouse
dbt run --selector sage                   # prod only
dbt docs generate --target prod
```

## Data Models

### Medallion architecture

```
S3 (Parquet) + MySQL RDS snapshots
    ↓ COPY INTO / external stages
synapse_data_warehouse.SYNAPSE_RAW        ← schemachange-managed DDL
synapse_data_warehouse.RDS_RAW            ← MySQL snapshot tables
    ↓ dynamic tables / tasks
synapse_data_warehouse.SYNAPSE_EVENT      ← file/node/object events
synapse_data_warehouse.SYNAPSE_AGGREGATE  ← time-window user aggregates
    ↓ dbt (staging → intermediate → marts)
SYNAPSE_DATA_WAREHOUSE / SAGE             ← analyst-ready dynamic tables
    ↓
Tableau / Streamlit / ad-hoc SQL
```

### Database mapping

| Database | Environment | Managed by |
|----------|-------------|------------|
| `SYNAPSE_DATA_WAREHOUSE` | Prod | schemachange + dbt |
| `SYNAPSE_DATA_WAREHOUSE_DEV` | Dev | schemachange + dbt |
| `SYNAPSE_DATA_WAREHOUSE_DEV_{branch}` | PR clone | CI/CD zero-copy clone |
| `SAGE` | Prod only | schemachange (sage/) |

### Key env vars (names only, values in secrets)

`SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PRIVATE_KEY_PATH`, `SNOWFLAKE_PRIVATE_KEY_PASSPHRASE`, `SNOWFLAKE_SYNAPSE_DATA_WAREHOUSE_DATABASE`, `SNOWFLAKE_SYNAPSE_STAGE_STORAGE_INTEGRATION`, `SNOWFLAKE_SYNAPSE_STAGE_URL`, `SNOWFLAKE_SNAPSHOTS_STAGE_STORAGE_INTEGRATION`, `SNOWFLAKE_SNAPSHOTS_STAGE_URL`, `STACK`

## Conventions

**Branch naming:** Feature branches must start with `snow-` (e.g., `snow-407-new-feature`) — the CI test workflow only triggers on branches matching this pattern. Work off `dev`, not `main`.

**PR title format:** `[SNOW-NNN] Brief description` — Jira ticket prefix is required by the PR template.

**Skip clone label:** Add `skip_cloning` label to a PR to bypass the zero-copy clone test if no schema changes are involved.

**Template variables in SQL:** Use `{{database_name}}`, `{{stage_storage_integration}}`, etc. (double curly braces). These are resolved by schemachange from environment variables. Add `--noqa: TMP,PRS` to suppress SQLFluff template warnings on these lines.

**SQLFluff noqa:** Use `--noqa: JJ01,PRS,TMP,CP01` on lines with template variables or schema USE statements.

**Warehouse sizes:** Use `XSMALL` for most tasks; `MEDIUM` only for COPY INTO operations. All warehouses created with `initially_suspended = TRUE` and `auto_resume = TRUE`.

**Timestamp conversion:** Source data timestamps are epoch milliseconds (NUMBER). Always divide by 1000 before passing to `TO_TIMESTAMP()`. Apply this conversion in the staging layer — never in intermediate or mart models.

## Architecture

Each major subsystem is self-contained:

- `synapse_data_warehouse/` — schemachange-managed DDL for the primary warehouse. See `synapse_data_warehouse/CLAUDE.md`.
- `transform/` — dbt project (staging → intermediate → marts). See `transform/CLAUDE.md`.
- `admin/` — account-level RBAC, warehouses, policies. See `admin/CLAUDE.md`.
- `sage/` — schemachange config for the SAGE cross-cutting database (citations, governance, GA4 aggregates). Mirrors synapse_data_warehouse patterns.
- `finance/` — Python ELT pulling MIP financial data via API into Snowflake. Uses `snowflake-connector-python` 3.14.0 + `backoff` for retry logic.
- `analytics/` — ad-hoc SQL and one-off Python ETL scripts. Not deployed by CI.
- `genie/` — GENIE cancer genomics queries and Snowpark scripts. Query-focused, minimal DDL.
- `data_validation/` — Great Expectations checkpoints on raw + portal tables.
- `streamlit/` — Internal dashboards (data catalog, forecasting). Reads from SAGE/SYNAPSE_DATA_WAREHOUSE.

## Constraints

- **Never edit `private_keys/`** — contains Snowflake private key files used for authentication.
- **Never edit `.terraform/`** — generated Terraform provider binary. Terraform is a PoC; schemachange is the authoritative DDL tool.
- **Never edit `data_validation/gx/uncommitted/`** — auto-generated GX docs and validation outputs.
- **Ownership grants run separately from regular grants** — granting ownership on a TASK auto-suspends it, even when transferring to the same role. Ownership changes belong in `admin/ownership_grants/` (versioned, executed by SECURITYADMIN), not in `admin/grants.sql`.
- **schemachange version numbers are immutable** — once a `V{version}__*.sql` script has been applied, it cannot be re-executed or renamed. Always increment the version.

## Anti-Patterns — Do NOT

- **Do NOT mix ownership grants into `admin/grants.sql`** — ownership transfers have a side effect of auto-suspending tasks. They must live in `admin/ownership_grants/` and be executed separately (evidence: separate directory exists specifically for this, admin/README.md).
- **Do NOT use repeatable (`R__`) scripts for tables that other objects depend on** — repeatable scripts re-run on every schemachange execution; if a dependent view/task exists, the re-creation can fail. Introduce tables in a `V__` script first (evidence: CONTRIBUTING.md explicit rule).
- **Do NOT convert stable tables to dynamic tables without testing** — this was reverted once (`Revert 'convert file latest to dynamic table'`, commit `2a07475`). Test the lag behavior and ownership requirements before converting.
- **Do NOT run `dbt run --selector sage` outside prod** — sage models are explicitly disabled for non-prod targets via `+enabled: "{{ target.name == 'prod' }}"`.
- **Do NOT add new object types to a schema without setting up RBAC** — each new object type (table, view, task, stream, stage) needs: ownership grant to `{SCHEMA}_ALL_ADMIN`, a `{SCHEMA}_{TYPE}_READ` database role, future grants for both dev and prod databases. See `admin/README.md`.

### Rolled-up subdirectories

- `analytics/` — ad-hoc SQL and Python scripts, no deployment conventions beyond the branch/PR rules above.
- `genie/` — Snowpark Python + SQL queries for GENIE cancer data; uses same Snowflake connection patterns as `finance/`.
- `sage/` — schemachange config for SAGE database; same V/R script conventions as `synapse_data_warehouse/`.
- `streamlit/` — Streamlit dashboards reading from prod databases; no write operations.
- `finance/` — Python ELT for MIP financial data; runs in Docker (Python 3.10); uses OAuth + `backoff` retry for MIP API calls.
- `data_validation/` — Great Expectations project; run `validation.py` to execute checkpoints against raw tables.

## Related Systems

- **Synapse platform** (Sage-Bionetworks/Synapse-Repository-Services): source of all RDS snapshots and S3 event data ingested here.
- **Synapse portals** (NF, AD, HTAN): data loaded via `analytics/portal_elt.py` using `synapseclient`.
- **MIP financial API**: source for `finance/` ELT pipeline.
- **DataCite API**: source for `sage/citations/` DOI tracking.
- **Google Analytics 4**: source for `sage/google_analytics_aggregate/` via service account (`Ga4_service_account.json`).
- Jira project: SNOW (`https://sagebionetworks.jira.com/browse/SNOW`)
- Architecture docs: `https://sagebionetworks.jira.com/wiki/spaces/DPE/`
