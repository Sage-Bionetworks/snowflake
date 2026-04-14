<!-- Last reviewed: 2026-04 -->

## Project

dbt project that transforms raw Synapse RDS snapshot data into analyst-ready models deployed as Snowflake dynamic tables. Follows a strict staging → intermediate → marts layer hierarchy. Profile name: `transform`. Active work includes governance datamart expansion (SNOW-386).

## Stack

- dbt (Snowflake adapter), profile: `transform`
- Snowflake dynamic tables (mart materialization)
- Source data: `SYNAPSE_DATA_WAREHOUSE.RDS_RAW` (MySQL RDS snapshots)

## Commands

```bash
# Run all models for synapse_data_warehouse (dev + prod)
dbt run --selector synapse_data_warehouse

# Run sage models (prod only — skipped automatically in dev)
dbt run --selector sage

# Run a specific model
dbt run --select stg_synapse__access_approval
dbt run --select intermediate.synapse
dbt run --select marts.synapse_data_warehouse

# Generate docs (requires prod target for full lineage)
dbt docs generate --target prod

# Test
dbt test
```

**Profiles:** `~/.dbt/profiles.yml` must define a `transform` profile with `dev` and `prod` outputs. Create or update that file locally using the standard dbt profile format and Snowflake adapter settings; see the dbt profile configuration and Snowflake setup docs for the required structure and fields. Fill in credentials locally and do not commit them.

## Data Models

### Layer hierarchy

```
SOURCE: SYNAPSE_DATA_WAREHOUSE.RDS_RAW  (MySQL snapshots)
    ↓
STAGING  (stg_synapse__*)              materialized: view
    - Standardize column names
    - Convert epoch ms → TIMESTAMP_NTZ
    - Rename id → {entity}_id
    - Enforce primary key + not_null constraints
    ↓
INTERMEDIATE  (int_synapse_*)          materialized: view
    - Join staging models into unified business entities
    - Aggregate accessor changes into VARIANT columns
    ↓
MARTS  (descriptive names)             materialized: dynamic_table
    - Target lag: 8 hours
    - Warehouse: compute_xsmall
    - synapse_data_warehouse/ → deployed to SYNAPSE_DATA_WAREHOUSE (dev + prod)
    - sage/ → deployed to SAGE database (prod only)
```

### Naming conventions

| Layer | Pattern | Example |
|-------|---------|---------|
| Staging | `stg_synapse__{entity}` | `stg_synapse__access_approval` |
| Intermediate | `int_synapse_{entity}` | `int_synapse_acl` |
| Marts | descriptive | `data_access_submission_event` |

Note: staging uses double-underscore before source (`stg_synapse__`), single underscore in intermediate (`int_synapse_`).

### Contract enforcement

All models have `+contract: {enforced: true}` at the project root. Every model's YAML file must define:
- `data_type` for every column
- `constraints: [{type: not_null}]` on business key columns
- `constraints: [{type: primary_key, columns: [...]}]` at the model level
- `constraints: [{type: foreign_key, to: ref('upstream_model'), to_columns: [...], warn_unenforced: false}]` for cross-model references

`warn_unenforced: false` is intentional — suppresses dbt warnings for Snowflake's unenforced FK constraints.

### Timestamp conversion rule

Source data timestamps are epoch **milliseconds** (NUMBER type). Convert in staging:
```sql
TO_TIMESTAMP(created_on_epoch / 1000) AS created_on  -- result: TIMESTAMP_NTZ
```
Never divide by 1000 in intermediate or mart models — it should already be a TIMESTAMP_NTZ by the time it leaves staging.

### TIMESTAMP_NTZ(3)

Use `TIMESTAMP_NTZ(3)` (millisecond precision) when source precision matters. Default `TIMESTAMP_NTZ` is fine for date-grain columns.

### Accessor changes pattern

`int_synapse_data_access_submission` aggregates access type changes into a single `VARIANT` column (`accessor_changes`) — a mapping of `principal_id (string) → access_type (GAIN_ACCESS | RENEW_ACCESS | REVOKE_ACCESS)`. Downstream mart models consume this as-is without further transformation.

### Prod-only sage models

Models in `marts/sage/` include `+enabled: "{{ target.name == 'prod' }}"`. They are silently skipped in dev and CI. To deploy sage models, run with `--target prod` and `--selector sage`.

## Conventions

**Selectors:** Use `selectors.yml` for environment-specific runs:
- `synapse_data_warehouse` selector: staging + intermediate + `marts/synapse_data_warehouse/`
- `sage` selector: `marts/sage/` only (prod target required)

**Docs persistence:** `+persist_docs: {relation: true, columns: true}` is set at root. Every model and column must have a `description` in its YAML file.

**Dynamic table config:** Mart models do not set `on_configuration_change` in SQL — it's inherited from `dbt_project.yml` (`apply`). Do not override it in individual model configs unless intentional.

**Source YAML location:** `models/staging/synapse/_synapse__sources.yml` — all RDS_RAW source tables are defined here. Add new source tables here before referencing with `{{ source() }}`.

## Constraints

- **Do not run `dbt run --selector sage` without `--target prod`** — sage models are disabled for non-prod targets; the run will succeed but produce no output, which is confusing.
- **Do not add mart models to `marts/sage/` without the `enabled` condition** — they would deploy to dev databases and create objects in the wrong database.
- **Do not skip contract definitions** — adding a column to a model SQL without adding it to the YAML will cause a contract violation error at runtime.
- **`target/` and `logs/` are gitignored** — do not commit dbt artifacts.

## Anti-Patterns — Do NOT

- **Do NOT add new staging columns without updating the YAML contract** — dbt enforces column-level contracts; the run will fail if SQL and YAML diverge.
- **Do NOT write timestamp conversions in intermediate or mart models** — epoch-to-timestamp conversion belongs in staging only. If a mart is receiving raw milliseconds, fix the staging model.
- **Do NOT use `dbt docs generate` without `--target prod`** — dev databases lack sage models; the generated lineage graph will be incomplete (evidence: PR #303 added `--target prod` requirement after a doc generation failure).
