-- Some database roles were created prematurely, despite not having
-- any objects which require permissions in their respective schema.
DROP DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_TASK_READ;
DROP DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_VIEW_READ;
DROP DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.SYNAPSE_STAGE_READ;