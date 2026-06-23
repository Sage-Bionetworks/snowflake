-- Steps are a CONTINUATION of the procedures started for the RDS_LANDING schema RBAC,
-- and are following the RBAC design pattern for schemas documented here:
-- https://sagebionetworks.jira.com/wiki/spaces/DPE/pages/4115366084/Managing+Object+Privileges#Schemas
--
-- NOTE: Task ownership must be held by the {DATABASE}_PROXY_ADMIN account role (not a database role),
-- because tasks require cross-schema account-level privileges (EXECUTE MANAGED TASK).

-----------------------------------------------------------------------------------------------------------
-- Step 18) Grant ownership of future tasks in PROD RDS_LANDING to PROXY_ADMIN account role:
-----------------------------------------------------------------------------------------------------------
GRANT OWNERSHIP
    ON FUTURE TASKS
    IN SCHEMA SYNAPSE_DATA_WAREHOUSE.RDS_LANDING
    TO ROLE SYNAPSE_DATA_WAREHOUSE_PROXY_ADMIN;


-----------------------------------------------------------------------------------------------------------
-- Step 19) Grant ownership of future tasks in DEV RDS_LANDING to PROXY_ADMIN account role:
-----------------------------------------------------------------------------------------------------------
GRANT OWNERSHIP
    ON FUTURE TASKS
    IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.RDS_LANDING
    TO ROLE SYNAPSE_DATA_WAREHOUSE_DEV_PROXY_ADMIN;


-----------------------------------------------------------------------------------------------------------
-- Step 20) Grant MONITOR on future tasks in PROD RDS_LANDING to task read database role:
-----------------------------------------------------------------------------------------------------------
GRANT MONITOR
    ON FUTURE TASKS
    IN SCHEMA SYNAPSE_DATA_WAREHOUSE.RDS_LANDING
    TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE.RDS_LANDING_TASK_READ;


-----------------------------------------------------------------------------------------------------------
-- Step 21) Grant MONITOR on future tasks in DEV RDS_LANDING to task read database role:
-----------------------------------------------------------------------------------------------------------
GRANT MONITOR
    ON FUTURE TASKS
    IN SCHEMA SYNAPSE_DATA_WAREHOUSE_DEV.RDS_LANDING
    TO DATABASE ROLE SYNAPSE_DATA_WAREHOUSE_DEV.RDS_LANDING_TASK_READ;
