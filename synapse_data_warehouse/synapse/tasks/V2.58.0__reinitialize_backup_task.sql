-- Our synapse_data_warehouse.synapse.backup_synapse_data_warehouse task
-- was created outside of the usual (current) CI process.
-- We recreate the task here so that it's on the books.
--
-- This creates a little extra complexity because we will also get the task
-- in the dev warehouse, although we only want to backup prod.
-- To have our cake and eat it too, we will manually resume the tasks
-- we create here in prod.
USE SCHEMA {{ database_name }}.synapse; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE TASK backup_synapse_data_warehouse_task
    SCHEDULE = 'USING CRON 0 3 * * 0 America/Los_Angeles'
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
AS
    CREATE OR REPLACE DATABASE backup_synapse_data_warehouse
    CLONE synapse_data_warehouse;

-- Creates a child task that runs immediately after
-- BACKUP_SYNAPSE_DATA_WAREHOUSE task and revokes USAGE from
-- SYNAPSE_DATA_WAREHOUSE_ANALYST (which in turn revokes this privilege
-- from DATA_ANALYTICS, and analyst roles more generally, since they
-- inherit access to the backup database via this role).
CREATE OR REPLACE TASK revoke_backup_synapse_access
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    AFTER backup_synapse_data_warehouse_task
AS
    REVOKE USAGE
        ON DATABASE backup_synapse_data_warehouse
        FROM ROLE synapse_data_warehouse_analyst;
