<!-- Last reviewed: 2026-04 -->

## Project

schemachange-managed DDL for the primary Synapse data warehouse. Contains all table definitions, dynamic tables, tasks, streams, and staged data ingestion for raw Synapse snapshots, RDS snapshots, and event aggregations. Version history tracked in `<database>.SCHEMACHANGE.CHANGE_HISTORY`.

## Schema layout

| Schema | Contents | Pattern |
|--------|----------|---------|
| `SYNAPSE_RAW` | Snapshot tables ingested from S3 (Parquet). 200+ tables. | V-scripts + R-scripts |
| `RDS_RAW` | MySQL RDS snapshot tables (access approvals, requirements, ACLs) | V-scripts |
| `RDS_LANDING` | External tables + stages for RDS snapshot ingestion | V-scripts |
| `SYNAPSE_EVENT` | File/Node/Object download and upload event tables | V-scripts + dynamic tables |
| `SYNAPSE_AGGREGATE` | Time-window aggregations of user upload/download activity | Dynamic tables |
| `SYNAPSE` | Transformed/materialized tables consumed by dbt and analysts | V-scripts + dynamic tables |
| `DATABASE_ROLES` | Role grant SQL (RBAC setup for this database) | V-scripts |
| `SCHEMACHANGE` | Version history metadata — never edit manually | Auto-created |

## Template variables

Every schemachange SQL script uses `{{database_name}}` to stay environment-agnostic:

```sql
USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
CREATE TABLE IF NOT EXISTS {{database_name}}.synapse_raw.my_table (...);
COPY INTO {{database_name}}.synapse_raw.my_table
  FROM @{{stage_storage_integration}}_STAGE/path/;
```

Available variables (set via env vars resolved from `schemachange-config.yml`):
- `database_name` → `SYNAPSE_DATA_WAREHOUSE` or `SYNAPSE_DATA_WAREHOUSE_DEV`
- `stage_storage_integration` → name of the Synapse S3 stage integration
- `stage_url` → S3 URL for the Synapse stage
- `snapshots_stage_storage_integration` → name of the RDS snapshots stage integration
- `snapshots_stage_url` → S3 URL for RDS snapshots
- `stack` → environment identifier

## Versioned vs. repeatable scripts

**Versioned (`V{major}.{minor}.{patch}__{description}.sql`):**
- Use for: `CREATE TABLE`, `CREATE STREAM`, new objects that other objects depend on
- Applied exactly once; version numbers are permanent
- Current sequence is in the V2.x range; check `CHANGE_HISTORY` before picking a new version

**Repeatable (`R__{description}.sql`):**
- Repeatable scripts run whenever the file contents change. It is strongly discouraged to use R scripts unless they provide a workaround for something that cannot be accomplished via a versioned script.

## Dynamic table pattern

```sql
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.schema.table_name
    TARGET_LAG = '8 hours'                        -- use '7 days' only for cold/infrequently-queried tables
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = '...'
AS
SELECT
    col1,
    col2
FROM {{database_name}}.source_schema.source_table
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY <primary key columns>
    ORDER BY <timestamp> DESC
) = 1;
```

## Task pattern

```sql
CREATE OR REPLACE TASK {{database_name}}.schema.task_name
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    AFTER predecessor_task
    SCHEDULE = 'USING CRON 0 0 * * * America/Los_Angeles'
AS
    <sql_statement>;
ALTER TASK {{database_name}}.schema.task_name RESUME;
```

- Chain tasks with `AFTER` for dependency ordering.
- Always `RESUME` the task in the same script.
- Use `user_task_managed_initial_warehouse_size` — avoids needing a separate warehouse.
- CRON uses `America/Los_Angeles` timezone.

## Comments in schemachange scripts

Keep comments short (one line max). Avoid step-numbered banners and ASCII decorators — they inflate context for agents reading these files.

## Constraints

See root `CLAUDE.md` for schemachange rules that apply across all directories (version numbers, `CHANGE_HISTORY`, repeatable scripts, ownership transfers).

Schema subdirectories (e.g. `rds_landing/`, `synapse_raw/`) must contain only DDL that creates or modifies objects. RBAC belongs elsewhere: role creation in `database_roles/`, grants in `admin/` (see `admin/AGENTS.md` for the full bootstrap split across `ownership_grants/`, `future_grants/`, and `grants.sql`).

