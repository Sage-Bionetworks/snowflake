<!-- Last reviewed: 2026-04 -->

## Purpose

Versioned schemachange scripts (`V{major}.{minor}.{patch}__{description}.sql`) that transfer ownership of Snowflake objects. Executed exactly once per script by SECURITYADMIN.

## Why a separate directory

Granting ownership on a TASK auto-suspends the task, even when transferring to the same role. These scripts must run only once and must never be mixed into `admin/grants.sql` (which is idempotent and re-run on every deploy).

## Pattern

```sql
GRANT OWNERSHIP ON ALL {OBJECT_TYPE}S IN SCHEMA {database}.{schema}
    TO ROLE {role}
    REVOKE CURRENT GRANTS;
```

Always include `REVOKE CURRENT GRANTS`. Without it, executing the grant will fail if the role already owns the object.

## Version numbering

This directory shares the `V1.x` version sequence with `admin/future_grants/`, `admin/warehouses/`, and `admin/policies/`. Check the highest version number across all four directories before picking the next version.
