<!-- Last reviewed: 2026-04 -->

## Project

Sage Bionetworks' Snowflake data warehouse. Ingests Synapse platform data (MySQL RDS snapshots + S3 event data), transforms it via either dbt or schemachange-managed DDL, and serves analytics to Tableau, Streamlit dashboards, and ad-hoc SQL consumers.

## Subsystems

Each major subsystem is self-contained with its own `CLAUDE.md`:

- `synapse_data_warehouse/` — schemachange-managed DDL for the primary Synapse databases (there are dev and prod deployements).
- `transform/` — dbt project (staging → intermediate → marts)
- `admin/` — account-level RBAC and objects, e.g.,  warehouse provisioning, masking policies, ownership transfers, and future grants.
- `sage/` — schemachange-managed DDL for the `SAGE` analyst database (citations, governance, GA4 aggregates).
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
(landing/raw — 100% schemachange)          (landing/raw — 100% schemachange)
    │                                              │
    └──────────────────┬────────────────────────── ┘
                       ↓
           SYNAPSE_EVENT      ← event data (file/node/object)
           SYNAPSE            ← most-recent-state objects
           SYNAPSE_AGGREGATE  ← time-window aggregates
           (mix of schemachange dynamic tables and dbt marts,
            depending on the object — see below)
                       ↓ dbt (staging → intermediate → marts)
           SYNAPSE_DATA_WAREHOUSE marts    ← analyst-ready dynamic tables
           SAGE schemas                   ← analyst schemas; may draw from
                                             SYNAPSE_DATA_WAREHOUSE or other sources
                       ↓
           Tableau / Streamlit / ad-hoc SQL
```

`SYNAPSE_RAW` and `RDS_LANDING` (and `RDS_RAW`) are landing/raw schemas: everything in them is schemachange-managed DDL, full stop. Everything downstream of that — `SYNAPSE_EVENT`, `SYNAPSE`, `SYNAPSE_AGGREGATE`, and beyond — is not exclusively one framework or the other: dbt models can materialize directly into any of these schemas via a custom `schema:` config (e.g. a dbt mart deploying into `SYNAPSE_EVENT` alongside schemachange-managed dynamic tables there), and which framework owns any given object in them today is incidental to how it happened to get built, not a fixed rule. Seeing a target schema name doesn't by itself tell you which framework owns — or should own — a new object there.

## When schemachange vs. dbt is ambiguous

Whether a new table belongs in `synapse_data_warehouse/` (schemachange) or `transform/` (dbt) usually depends on where its underlying source data already lives and what shape it's in:

- Data with real change-capture semantics already in a schemachange-managed source (e.g. `SYNAPSE_RAW.*SNAPSHOTS`, which carries `change_type`/`change_timestamp` natively) is usually a direct schemachange dynamic table.
- Data that needs enrichment, joins, or derivation from `RDS_LANDING`/`RDS_RAW` is usually dbt's staging → intermediate → mart territory, even when the mart's final home is `SYNAPSE_EVENT`, `SYNAPSE`, or another schema that also holds schemachange-managed objects.

But this is genuinely ambiguous more often than it looks, and the ambiguity is often a product decision, not a technical one:

- The same request can map to more than one plausible source table or entity — e.g. "team events" could mean the team entity itself or team membership changes; "access request events" could mean the access requirement rule, the access request, or the access submission, each backed by different tables.
- A data domain sometimes already has partial representation in both frameworks (e.g. a schemachange raw snapshot table and an unrelated dbt staging/intermediate model derived from a different upstream system), and it isn't obvious which one, if either, the user actually means to extend.
- The right answer can depend on intent that isn't visible from the code at all: which entity was meant, whether current-state or full history is wanted, or whether an existing object already satisfies the request.

Before implementing a new object, check **both** `synapse_data_warehouse/` and `transform/` for existing models or tables over the same or related source data — not just the target schema — so you don't duplicate or shadow something that already exists. If, after that, real ambiguity remains along the lines above, don't resolve it by guessing and building — surface the ambiguity and the plausible options to the user and let them decide. A wrong guess here risks a duplicate or conflicting object in a shared production schema, not just wasted effort.

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

**Skip clone label:** Add `skip_cloning` label to a PR to bypass the zero-copy clone test if no schema changes are involved. Even if there are no schema changes, it may be useful to include this label to test changes to the zero-copy clone workflow (`.github/workflows/test_with_clone.yaml`).

**`admin/` changes:** Any PR targeting `dev` that also touches `admin/` must have those `admin/` changes cherry-picked into a separate branch off `main` and opened as a separate PR (since `admin/` deploys only on push to `main`). If the `dev` based changes are dependent on changes in `admin/`, then the description of the associated PR should indicate that this PR "depends on" the PR associated with the `admin/` changes.

**Python environment:** Dependencies are managed with [uv](https://docs.astral.sh/uv/). Run tools via `uv run --group <name> <cmd>` — no separate sync step needed. Available groups: `snowflake`, `schemachange`, `dbt`. See `pyproject.toml` for the full definitions. To use the Snowflake CLI, use the `snow` tool: `uvx --from snowflake-cli snow ...`. Streamlit app dependencies are managed per-app via `environment.yml` (conda/mamba) — see [STREAMLIT.md](./STREAMLIT.md).

**Code comments:** Comments should be plain, concise, and should add context that is not already obvious from the code itself. Prefer comments that explain intent, assumptions, business logic, or non-obvious implementation details.

**CONTRIBUTING.md** Additional contribution guidelines are contained in [CONTRIBUTING.md](./CONTRIBUTING.md).

## Schemachange rules

These apply to every schemachange-managed directory in this repo (`synapse_data_warehouse/`, `sage/`, `admin/` subdirs):

- **Never edit `SCHEMACHANGE.CHANGE_HISTORY` directly** — schemachange uses this to determine which scripts have been applied.
- **Never reuse or edit an applied version number** — increment the minor or patch version instead.
- **Do not use repeatable scripts to create objects with downstream dependencies** — if a task or dynamic table references a table, create that table in a V-script first.
- **Scripts that reference an object must have a higher version number than the script that creates it** — schemachange applies versioned scripts in ascending order, so a grant or DDL that depends on an object (e.g. a database role) must come after the script that creates it.
- **All `GRANT OWNERSHIP` statements belong in `admin/ownership_grants/`** — adding them inside DDL migration scripts will auto-suspend tasks.
- **Schema subdirectories contain only object DDL** — scripts under a schema subdir (e.g. `synapse_data_warehouse/rds_landing/`) must only create or alter objects (tables, tasks, stages, etc.). Database role creation, ownership, and inheritance belong in that database's `database_roles/` subdir; all other grants belong in `admin/` (see `admin/AGENTS.md` for the full split across `ownership_grants/`, `future_grants/`, and `grants.sql`).
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
- **DataCite API**: source for `sage/citations/` DOI tracking.
- **Google Analytics 4**: source for `sage/google_analytics_aggregate/` via service account (`Ga4_service_account.json`).
- Jira project: SNOW (`https://sagebionetworks.jira.com/browse/SNOW`)
- Internal developer docs: `https://sagebionetworks.jira.com/wiki/spaces/DPE/pages/3015508258/Sage+Data+Warehouse+Snowflake`
