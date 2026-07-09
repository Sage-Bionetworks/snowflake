-- Grant MONITOR on all existing RDS_LANDING tasks to the task read database role.
-- Moved to admin/grants.sql — object-level grants (non-ownership, non-future) belong there,
-- not in schemachange scripts.
select 1;
