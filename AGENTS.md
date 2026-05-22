<!-- Last reviewed: 2026-04 -->

## Project

Sage Bionetworks' Snowflake data warehouse. Ingests Synapse platform data (MySQL RDS snapshots + S3 event data), transforms it via dbt, and serves analytics to Tableau, Streamlit dashboards, and ad-hoc SQL consumers.

## Subsystems

Each major subsystem is self-contained with its own `CLAUDE.md`:

- `synapse_data_warehouse/` — schemachange-managed DDL for the primary Synapse databases (there are dev and prod deployements).
- `transform/` — dbt project (staging → intermediate → marts)
- `admin/` — account-level RBAC and objects, e.g.,  warehouse provisioning, masking policies, ownership transfers, and future grants.
- `sage/` — schemachange-managed DDL for the `SAGE` analyst database (citations, governance, GA4 aggregates).
- `finance/` — Python ELT pulling MIP financial data via API into Snowflake.
- `analytics/` — ad-hoc SQL and one-off Python ETL scripts. Not deployed by CI.
- `genie/` — GENIE cancer genomics queries and Snowpark scripts. Query-focused, minimal DDL.
- `data_validation/` — Great Expectations checkpoints on raw + portal tables.
- `.github/` — CI/CD workflows and shared actions.

## Data flow

Two separate ingestion paths feed into `SYNAPSE_DATA_WAREHOUSE[_DEV]`:

```
Glue pipeline                              MySQL RDS snapshots
(event data + weekly snapshots)
    ↓ Snowflake stages + tasks                 ↓ COPY INTO
SYNAPSE_RAW                                RDS_LANDING → RDS_RAW
    │                                              │
    └──────────────────┬────────────────────────── ┘
                       ↓ dynamic tables / tasks
           SYNAPSE_EVENT      ← event data (file/node/object)
           SYNAPSE            ← most-recent-state objects
           SYNAPSE_AGGREGATE  ← time-window aggregates
                       ↓ dbt (staging → intermediate → marts)
           SYNAPSE_DATA_WAREHOUSE marts    ← analyst-ready dynamic tables
           SAGE schemas                   ← analyst schemas; may draw from
                                             SYNAPSE_DATA_WAREHOUSE or other sources
                       ↓
           Tableau / Streamlit / ad-hoc SQL
```

## Database environments

| Database | Environment | Managed by |
|----------|-------------|------------|
| `SYNAPSE_DATA_WAREHOUSE` | Prod | schemachange + dbt |
| `SYNAPSE_DATA_WAREHOUSE_DEV` | Dev | schemachange + dbt |
| `SYNAPSE_DATA_WAREHOUSE_DEV_{branch}` | PR clone | CI/CD zero-copy clone |
| `SAGE` | Prod only | schemachange (`sage/`) |

## Contributing conventions

**Branch naming:** Feature branches must be prefixed with their Jira ticket identifier (e.g., `snow-407-new-feature`) for the cloned-db test/deploy to succeed. Work off `dev`, not `main`.

**PR title format:** `[SNOW-NNN] Brief description` — Jira ticket prefix is required by the PR template.

**Skip clone label:** Add `skip_cloning` label to a PR to bypass the zero-copy clone test if no schema changes are involved.

**`admin/` changes:** Any PR targeting `dev` that also touches `admin/` must have those `admin/` changes cherry-picked into a separate branch off `main` and opened as a separate PR (since `admin/` deploys only on push to `main`). If the `dev` based changes are dependent on changes in `admin/`, then the description of the associated PR should indicate that this PR "depends on" the PR associated with the `admin/` changes.

**Python environment:** Dependencies are managed with [uv](https://docs.astral.sh/uv/). Run tools via `uv run --group <name> <cmd>` — no separate sync step needed. Available groups: `snowflake`, `schemachange`, `dbt`, `finance`, `streamlit`, `google-analytics`. See `pyproject.toml` for the full definitions.

**CONTRIBUTING.md** Additional contribution guidelines are contained in [CONTRIBUTING.md](./CONTRIBUTING.md).

## Schemachange rules

These apply to every schemachange-managed directory in this repo (`synapse_data_warehouse/`, `sage/`, `admin/` subdirs):

- **Never edit `SCHEMACHANGE.CHANGE_HISTORY` directly** — schemachange uses this to determine which scripts have been applied.
- **Never reuse or edit an applied version number** — increment the minor or patch version instead.
- **Do not use repeatable scripts to create objects with downstream dependencies** — if a task or dynamic table references a table, create that table in a V-script first.
- **All `GRANT OWNERSHIP` statements belong in `admin/ownership_grants/`** — adding them inside DDL migration scripts will auto-suspend tasks.
- **SQLFluff noqa:** Use `--noqa: JJ01,PRS,TMP` on lines with template variables. Add `CP01` or `CP02` only if that specific line also triggers capitalization rules.

## Interfacing with Snowflake

Snowflake can be interfaced with via the `snow` CLI tool.

**DO NOT** run commands which create, delete, or alter resources in Snowflake unless the user explictly requests those actions. Complete `snow` documentation is [here](https://docs.snowflake.com/en/developer-guide/snowflake-cli/index). 

## Off-limits paths

- **Never edit `private_keys/`** — Snowflake private key files used for authentication.
- **Never edit `.terraform/`** — generated Terraform provider binary. Terraform is a PoC; schemachange is the authoritative DDL tool.
- **Never edit `data_validation/gx/uncommitted/`** — auto-generated GX docs and validation outputs.

## Related systems

- **Synapse platform** (Sage-Bionetworks/Synapse-Repository-Services): source of all RDS snapshots and S3 event data.
- **Synapse portals** (NF, AD, HTAN): data loaded via `analytics/portal_elt.py` using `synapseclient`.
- **MIP financial API**: source for `finance/` ELT pipeline.
- **DataCite API**: source for `sage/citations/` DOI tracking.
- **Google Analytics 4**: source for `sage/google_analytics_aggregate/` via service account (`Ga4_service_account.json`).
- Jira project: SNOW (`https://sagebionetworks.jira.com/browse/SNOW`)
- Internal developer docs: `https://sagebionetworks.jira.com/wiki/spaces/DPE/pages/3015508258/Sage+Data+Warehouse+Snowflake`
