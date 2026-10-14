## Highlights
- Completed RDS_LANDING snapshot ingestion and RDS_RAW dynamic tables for the remaining RDS data types
- Added a data access submission aggregate mart and a FILEHANDLEASSOCIATION_EVENT table
- Added the snowclone package for on-demand zero-copy clone provisioning
- Fixed the RDS snapshot finalizer race condition

## Features
- [SNOW-507] Extended COPY INTO ingestion to the remaining RDS_LANDING tables (@philerooski in #419)
- [SNOW-562] Added RDS_RAW dynamic tables for the remaining data types and granted APPLY on the RDS_RAW masking policies to the proxy admin roles (@philerooski in #431, #432)
- [SNOW-499] Added data access submission aggregate mart (@philerooski in #420)
- [SNOW-540] Added SYNAPSE_EVENT.FILEHANDLEASSOCIATION_EVENT and registered SYNAPSE_EVENT tables as dbt source tables (@philerooski in #436)
- [SNOW-380] Configured Agora and Model AD GA4 reports (@philerooski in #430)
- Added snowclone package and on-demand clone-provisioning workflow (@philerooski in #371)

## Bug Fixes
- [SNOW-568] Fixed RDS snapshot finalizer race by scoping it to the current graph_run_group_id (@philerooski in #433)
- [SNOW-504] Blanked reviewer and modified by/on for unreviewed data access submissions (@philerooski in #435)
- [SNOW-581] Revoked database-role membership in clone procurement Phase 2, not just database privileges (@philerooski in #434)
- Suspended the root task before updating the RDS snapshot task graph (@philerooski in #419)

## Tech Debt
- [SNOW-563] Upgraded dbt-core to 1.12.3 to unblock sqlparse remediation (@philerooski in #425)
- [SNOW-576] Reused the project uv environment for dbt/schemachange in CI (@philerooski in #426)

## Other
- Granted TECH_PRODUCT to Bruce (@philerooski in #428)

Full Changelog: https://github.com/Sage-Bionetworks/snowflake/compare/2.3.2...2.4.0
