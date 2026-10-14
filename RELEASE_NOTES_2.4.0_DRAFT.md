# 2.4.0 (draft)

Changes on `main` since 2.3.2.

## Deployment notes

- `admin/grants.sql` changes deploy on push to `main`.
- New schemachange scripts:
  - `synapse_data_warehouse`: `rds_landing` V2.76.0 – V2.76.3 and V2.76.7, `rds_raw` V2.77.0 – V2.77.1, `synapse_event` V2.78.0, `synapse` V2.78.1.
  - `sage`: V1.6.0.
- dbt-core is upgraded to 1.12.3. CI now reuses the project `uv` environment.

## Data warehouse

- **[SNOW-507] RDS_LANDING ingestion extended to the remaining tables.** Adds ingest-metadata columns and clustering to the remaining landing tables, plus their COPY INTO snapshot tasks. (#419)
- **[SNOW-562] RDS_RAW dynamic tables for the remaining data types.** Includes the event-like tables, `sent_messages` and `materialized_view_*`, with corrected dedup keys. (#432)
- **[SNOW-562] Grant APPLY on the RDS_RAW PII masking policies** to `SYNAPSE_DATA_WAREHOUSE[_DEV]_PROXY_ADMIN`, so the dynamic tables it owns can mask columns. (#431)
- **[SNOW-568] Fix the RDS snapshot finalizer race** by scoping it to the current `graph_run_group_id` and fixing the `task_history()` scope. (#433)
- **Hotfix:** suspend the root task before updating the task graph.
- **[SNOW-540] Add `SYNAPSE_EVENT.FILEHANDLEASSOCIATION_EVENT`.** Registers it, `objectdownload_event`, `fileupload_event` and `access_event` as dbt source tables. (#436)

## dbt / analytics

- **[SNOW-499] Data access submission aggregate mart** (`data_access_submission_aggregate`, `SYNAPSE_AGGREGATE`). Promotes the `attempt` column; metrics are dated by event date. (#420)
- **[SNOW-504] Blank reviewer and modified-by/on** for unreviewed (submitted/cancelled) submissions in the data access submission dashboard mart. (#435)
- **[SNOW-380] Configure Agora and Model AD GA4 reports** in `sage/`. (#430)

## Developer tooling and CI

- **`snowclone` package and on-demand clone-provisioning workflow** (`procure_clone.yaml`). Includes hotfixes for the missing `--package` flag in `uv run` and the wrong deploy-database env var in `test_with_clone.yaml`. (#371)
- **[SNOW-581] Clone procurement Phase 2 now revokes database-role membership**, not just database-level privileges. Cloned grants no longer leave unrelated roles with read access. (#434)
- **[SNOW-563] Upgrade dbt-core to 1.12.3**, unblocking the sqlparse remediation. (#425)
- **[SNOW-576] Reuse the project uv environment for dbt/schemachange in CI**, with `--frozen` and `--no-build`. (#426)

## Access

- Grant `TECH_PRODUCT` to Bruce Hoff. (#428)

## Excluded

These were already released in 2.3.x or are sync-only:

- Already in 2.3.x: #405/#408, #407, #409, #411/#415, #413, #417, #418, #421, #423, plus #384, #387, #390, #396, #397, #406.
- Sync-only: #424 ("Sync dev with main") and the "Merge main into dev" merges.
- #429 and #437 ("Merge dev into main") are squash commits. Their bodies repeat many of the excluded PRs.
