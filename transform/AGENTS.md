<!-- Last reviewed: 2026-04 -->

## Project

dbt project that transforms raw Synapse RDS snapshot data into analyst-ready models deployed as Snowflake dynamic tables. Profile name: `transform`. Source data lives in `SYNAPSE_DATA_WAREHOUSE.RDS_RAW`.

## Stack

- dbt (Snowflake adapter), profile: `transform`
- Snowflake dynamic tables (mart materialization)
- SQLFluff: 3.0.6

## Setup

Prefix all `dbt` invocations with `uv run --group dbt`:

```bash
uv run --group dbt dbt run --selector synapse_data_warehouse
```

## Commands

```bash
# Run all models for synapse_data_warehouse (dev + prod)
dbt run --selector synapse_data_warehouse

# Run sage models — target name alone does not gate this selector, so only
# run it from a context intended to deploy to its configured destination
dbt run --selector sage --target prod

# Run a specific model(s)
dbt run --select stg_synapse__access_approval
dbt run --select intermediate.synapse

# Generate docs
dbt docs generate --target prod

# Test
dbt test
```

**Profiles:** `~/.dbt/profiles.yml` must define a `transform` profile with `dev` and `prod` outputs. Create or update that file locally using the standard dbt profile format and Snowflake adapter settings; see the dbt profile configuration and Snowflake setup docs for the required structure and fields. Fill in credentials locally and do not commit them.

**DO NOT execute `dbt run` unless:** You specify `--selector dev` and have ensured that the database and/or schema in `~/.dbt/profiles.yml` corresponds to the feature branch developer database/schema OR if the user specifically requests for models to be deployed to the `prod` environment.

## Selectors

Defined in `selectors.yml`:
- `synapse_data_warehouse` — staging + intermediate + `marts/synapse_data_warehouse/`; runs against dev and prod
- `sage` — `marts/sage/` only; target name alone does not gate it, so only invoke from a context intended to deploy to its configured destination

## Structure

```
models/
  staging/synapse/      ← stg_synapse__* views
  intermediate/         ← int_synapse_* views
  marts/
    synapse_data_warehouse/  ← dynamic tables → SYNAPSE_DATA_WAREHOUSE
    sage/                    ← dynamic tables → SAGE
```

See `models/CLAUDE.md` for model development conventions (naming, contracts, materialization, timestamp handling).

## Constraints

- **`target/` and `logs/` are gitignored** — do not commit dbt artifacts.
