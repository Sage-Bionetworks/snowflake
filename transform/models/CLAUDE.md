<!-- Last reviewed: 2026-04 -->

## Layer hierarchy

```
SOURCE: SYNAPSE_DATA_WAREHOUSE.RDS_RAW
    ↓
staging/synapse/   stg_synapse__*     materialized: view
    ↓
intermediate/      int_synapse_*      materialized: view
    ↓
marts/
  synapse_data_warehouse/             materialized: dynamic_table → SYNAPSE_DATA_WAREHOUSE
  sage/                               materialized: dynamic_table → SAGE (prod only)
```

## Naming conventions

| Layer | Pattern | Example |
|-------|---------|---------|
| Staging | `stg_{source}__{entity}` | `stg_synapse__access_approval` |
| Intermediate | `int_{source}_{entity}` | `int_synapse_acl` |
| Marts | descriptive | `data_access_submission_event` |

Staging uses double-underscore before source (`stg_synapse__`); intermediate uses single underscore (`int_synapse_`).

## Staging layer responsibilities

- Standardize column names (rename `id` → `{entity}_id`)
- Convert epoch milliseconds → `TIMESTAMP_NTZ`: `TO_TIMESTAMP(col / 1000)`
- Enforce primary key + not_null constraints via YAML contract

Never perform epoch-to-timestamp conversion in intermediate or mart models — it belongs in staging only.

Use `TIMESTAMP_NTZ(3)` when millisecond precision matters; plain `TIMESTAMP_NTZ` is fine for date-grain columns.

## Intermediate layer responsibilities

- Join staging models into unified business entities
- Aggregate accessor changes into `VARIANT` columns

`int_synapse_data_access_submission` stores `accessor_changes` as a `VARIANT` mapping of `principal_id (string) → access_type (GAIN_ACCESS | RENEW_ACCESS | REVOKE_ACCESS)`. Downstream mart models consume this as-is.

## Mart materialization config

Mart models configuration and materialization is configured in `dbt_project.yml` (do not override in individual models)

## Prod-only sage models

All models in `marts/sage/` include `+enabled: "{{ target.name == 'prod' }}"`. They are silently skipped in dev and CI. Do not add sage mart models without this condition.

## Contract enforcement

All models have `+contract: {enforced: true}` at the project root. Every model's YAML must define:
- `data_type` for every column
- `constraints: [{type: not_null}]` on business key columns
- `constraints: [{type: primary_key, columns: [...]}]` at the model level
- `constraints: [{type: foreign_key, to: ref('...'), to_columns: [...], warn_unenforced: false}]` for cross-model references

`warn_unenforced: false` suppresses dbt warnings for Snowflake's unenforced FK constraints (intentional).

Adding a column to model SQL without updating the YAML will cause a contract violation error at runtime.

## Docs and sources

**Docs persistence:** `+persist_docs: {relation: true, columns: true}` is set at root. Every model and column must have a `description` in its YAML file.

**Source YAML:** `staging/synapse/_synapse__sources.yml` — all `RDS_RAW` source tables are defined here. Add new source tables here before referencing with `{{ source() }}`.
