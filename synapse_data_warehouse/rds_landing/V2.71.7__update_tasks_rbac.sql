use database {{database_name}}; --noqa: JJ01,PRS,TMP

-- Grant MONITOR privilege on all existing RDS_LANDING tasks to the task read database role.
grant monitor
    on all tasks
    in schema rds_landing
    to database role rds_landing_task_read;