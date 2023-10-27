-- This is a scheduled task to create zero copy clones only for accountadmins
use role accountadmin;
use schema synapse_data_warehouse.synapse;
create task if not exists backup_synapse_data_warehouse_task
    schedule = 'USING CRON 0 3 * * 0 America/Los_Angeles'
    user_task_managed_initial_warehouse_size = 'XSMALL'
as
    create or replace database backup_synapse_data_warehouse
    clone synapse_data_warehouse;
alter task if exists backup_synapse_data_warehouse_task resume;
use schema sage.portal_raw;
create task if not exists backup_sage_task
    schedule = 'USING CRON 0 3 * * 0 America/Los_Angeles'
    user_task_managed_initial_warehouse_size = 'XSMALL'
as
    create or replace database backup_sage
    clone sage;
alter task if exists backup_sage resume;
