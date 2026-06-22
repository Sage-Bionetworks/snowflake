use database {{database_name}}; --noqa: JJ01,PRS,TMP

-- Grant MONITOR privilege on all existing RDS_LANDING tasks to the task read database role.
grant MONITOR
    on all tasks
    in schema RDS_LANDING
    to database role RDS_LANDING_TASK_READ;