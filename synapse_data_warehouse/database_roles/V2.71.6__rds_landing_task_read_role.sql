-- Steps are a CONTINUATION of the procedures started for the RDS_LANDING schema,
-- and are following the RBAC design pattern for schemas documented here:
-- https://sagebionetworks.jira.com/wiki/spaces/DPE/pages/4115366084/Managing+Object+Privileges#Schemas

USE DATABASE {{ database_name }}; --noqa: JJ01,PRS,TMP

----------------------------------------------------------------------------------------------------
-- Step 13) Create task read access database role for RDS_LANDING:
----------------------------------------------------------------------------------------------------
CREATE OR REPLACE DATABASE ROLE RDS_LANDING_TASK_READ;


----------------------------------------------------------------------------------------------------
-- Step 14) Assign ownership of the task read role to <SCHEMA>_ALL_ADMIN database role:
----------------------------------------------------------------------------------------------------
GRANT OWNERSHIP
    ON DATABASE ROLE RDS_LANDING_TASK_READ
    TO DATABASE ROLE RDS_LANDING_ALL_ADMIN;


----------------------------------------------------------------------------------------------------
-- Step 15) Assign inheritance of the task read role to <SCHEMA>_ALL_DEVELOPER database role:
----------------------------------------------------------------------------------------------------
GRANT DATABASE ROLE RDS_LANDING_TASK_READ
    TO DATABASE ROLE RDS_LANDING_ALL_DEVELOPER;
