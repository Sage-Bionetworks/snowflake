<!-- Last reviewed: 2026-04 -->

## Project

dbt project that transforms raw Synapse RDS snapshot data into analyst-ready models deployed as Snowflake dynamic tables. Profile name: `transform`. Source data lives in `SYNAPSE_DATA_WAREHOUSE.RDS_RAW`.

## Stack

- dbt (Snowflake adapter), profile: `transform`
- Snowflake dynamic tables (mart materialization)
- SQLFluff: 3.0.6

## Commands

```bash
# Run all models for synapse_data_warehouse (dev + prod)
dbt run --selector synapse_data_warehouse

# Run sage models (prod only — skipped automatically in dev)
dbt run --selector sage --target prod

# Run a specific model(s)
dbt run --select stg_synapse__access_approval
dbt run --select intermediate.synapse

# Generate docs (prod target required for complete lineage)
dbt docs generate --target prod

# Test
dbt test
```

**Profiles:** `~/.dbt/profiles.yml` must define a `transform` profile with `dev` and `prod` outputs. Create or update that file locally using the standard dbt profile format and Snowflake adapter settings; see the dbt profile configuration and Snowflake setup docs for the required structure and fields. Fill in credentials locally and do not commit them.

## Selectors

Defined in `selectors.yml`:
- `synapse_data_warehouse` — staging + intermediate + `marts/synapse_data_warehouse/`; runs against dev and prod
- `sage` — `marts/sage/` only; prod target required

## Structure

```
models/
  staging/synapse/      ← stg_synapse__* views
  intermediate/         ← int_synapse_* views
  marts/
    synapse_data_warehouse/  ← dynamic tables → SYNAPSE_DATA_WAREHOUSE
    sage/                    ← dynamic tables → SAGE (prod only)
```

See `models/CLAUDE.md` for model development conventions (naming, contracts, materialization, timestamp handling).

## Constraints

- **`target/` and `logs/` are gitignored** — do not commit dbt artifacts.
- **Do not run `dbt docs generate` without `--target prod`** — dev databases lack sage models; the generated lineage graph will be incomplete.
- **Do not run `dbt run --selector sage` without `--target prod`** — sage models are disabled for non-prod targets; the run will succeed but produce no output.

