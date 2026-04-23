<!-- Last reviewed: 2026-04 -->

## Purpose

Versioned schemachange scripts (`V{major}.{minor}.{patch}__{description}.sql`) that define future grants on schema-level objects. Executed by SECURITYADMIN.

## Why future grants

Without future grants, new objects created in a schema (e.g., a new table added by a `V__` migration) are not automatically accessible to `DATA_ENGINEER` or any read role. Future grants ensure privilege coverage persists as new objects are added.

## When to add a script here

Add a new versioned script here whenever:
- A new schema is created (bootstrap all archetypes for every object type in that schema)
- A new object type (e.g., FUNCTION) is introduced to an existing schema for the first time

**Only new object types need grants set up.** Once future grants are in place for a given object type in a schema, new objects of that type are covered automatically.

## Pattern

Each script should cover both prod and dev databases:

```sql
-- Prod
GRANT SELECT ON FUTURE TABLES IN SCHEMA SYNAPSE_DATA_WAREHOUSE.{schema}
    TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.{schema}_TABLE_READ; --noqa: JJ01,PRS,TMP

-- Dev
GRANT SELECT ON FUTURE TABLES IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.{schema}
    TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.{schema}_TABLE_READ; --noqa: JJ01,PRS,TMP
```

## Version numbering

This directory shares the `V1.x` version sequence with `admin/ownership_grants/`, `admin/warehouses/`, and `admin/policies/`. Check the highest version number across all four directories before picking the next version.
