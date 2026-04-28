<!-- Last reviewed: 2026-04 -->

## Project

schemachange-managed DDL for the primary Synapse data warehouse. Contains all table definitions, dynamic tables, tasks, streams, and staged data ingestion for raw Synapse snapshots, RDS snapshots, and event aggregations. Version history tracked in `<database>.SCHEMACHANGE.CHANGE_HISTORY`.

## Commands

```bash
# Dev deploy
schemachange \
  --connection-name default \
  --root-folder synapse_data_warehouse \
  --config-folder synapse_data_warehouse \
  --snowflake-role synapse_data_warehouse_dev_admin

# Prod deploy
schemachange \
  --connection-name default \
  --root-folder synapse_data_warehouse \
  --config-folder synapse_data_warehouse \
  --snowflake-role synapse_data_warehouse_admin

# Check what has been applied (substitute the target database name)
-- SELECT * FROM <database>.SCHEMACHANGE.CHANGE_HISTORY ORDER BY INSTALLED_ON DESC;
```

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

## RBAC

This database follows the structured database-role-based access pattern. See `admin/CLAUDE.md` for the full hierarchy and `admin/future_grants/CLAUDE.md` for adding new object types. The `database_roles/` subdirectory contains the V-scripts that set up database roles and grants for each schema.

## Template variables

Every SQL file uses `{{database_name}}` to stay environment-agnostic:

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

**SQLFluff noqa:** Use `--noqa: JJ01,PRS,TMP` on lines with template variables. Add `CP01` or `CP02` only if that specific line also triggers capitalization rules.

## Versioned vs. repeatable scripts

**Versioned (`V{major}.{minor}.{patch}__{description}.sql`):**
- Use for: `CREATE TABLE`, `CREATE STREAM`, new objects that other objects depend on
- Applied exactly once; version numbers are permanent
- Current sequence is in the V2.x range; check `CHANGE_HISTORY` before picking a new version

**Repeatable (`R__{description}.sql`):**
- Use for: `CREATE OR ALTER TABLE`, `CREATE TASK IF NOT EXISTS` (idempotent re-runs)
- Re-executed whenever the file content changes
- Do NOT use for tables referenced by tasks, streams, or dynamic tables that won't be recreated — use a V-script instead

## Dynamic table pattern

```sql
CREATE OR REPLACE DYNAMIC TABLE {{database_name}}.schema.table_name
    TARGET_LAG = '1 day'                        -- use '7 days' only for cold/infrequently-queried tables
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'Grain: one row per ...'
AS
SELECT
    col1,
    col2
FROM {{database_name}}.source_schema.source_table
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY <grain_columns>
    ORDER BY <timestamp> DESC
) = 1;
```

Do NOT convert stable snapshot tables to dynamic tables without testing — dynamic table conversion was reverted once (`Revert 'convert file latest to dynamic table'`, commit `2a07475`) due to ownership and lag behavior issues. Validate in dev first.

## Task pattern (repeatable scripts)

```sql
CREATE TASK IF NOT EXISTS {{database_name}}.schema.task_name
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
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

## S3 COPY INTO pattern

```sql
COPY INTO {{database_name}}.synapse_raw.table_name
FROM @{{stage_storage_integration}}_STAGE/path/
    FILE_FORMAT = (TYPE = PARQUET)
    MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
    PATTERN = '.*partition_key=.*/.*';
```

Extract partition date from metadata filename:
```sql
NULLIF(REGEXP_REPLACE(METADATA$FILENAME, '.*partition_key=([^/]+)/.*', '\\1'), '__HIVE_DEFAULT_PARTITION__')::DATE
```

## Constraints

- **Never edit `SCHEMACHANGE.CHANGE_HISTORY` directly** — schemachange uses this to determine which scripts have been applied.
- **Never reuse or edit an applied version number** — increment the minor or patch version instead.
- **Do NOT use repeatable scripts to create tables with downstream dependencies** — if a task or dynamic table references a table, create that table in a V-script first.
- **Ownership transfers for this database belong in `admin/ownership_grants/`** — do not add `GRANT OWNERSHIP` here; it will auto-suspend tasks.

