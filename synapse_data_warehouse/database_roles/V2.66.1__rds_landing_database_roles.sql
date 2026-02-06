-- Steps are created following the RBAC design pattern for schemas documented here:
-- https://sagebionetworks.jira.com/wiki/spaces/DPE/pages/4115366084/Managing+Object+Privileges#Schemas

USE DATABASE {{ database_name }}; --noqa: JJ01,PRS,TMP

-----------------------------------------------
-- Step 1) Create the archetype database roles:
-----------------------------------------------
-- <SCHEMA>_ALL_ADMIN database role which will own all the objects
CREATE OR REPLACE DATABASE ROLE RDS_LANDING_ALL_ADMIN;
-- <SCHEMA>_ALL_DEVELOPER database role which will have read access to all the objects
CREATE OR REPLACE DATABASE ROLE RDS_LANDING_ALL_DEVELOPER;


-------------------------------------------------------------------------------------------
-- Step 2) Assign ownership between these database roles and the appropriate account roles:
-------------------------------------------------------------------------------------------
-- <SCHEMA>_ALL_ADMIN database role owns the other archetype database role
GRANT OWNERSHIP ON DATABASE ROLE RDS_LANDING_ALL_DEVELOPER TO DATABASE ROLE RDS_LANDING_ALL_ADMIN;
-- <DATABASE>_PROXY_ADMIN account role owns the <SCHEMA>_ALL_ADMIN database role
GRANT OWNERSHIP ON DATABASE ROLE RDS_LANDING_ALL_ADMIN TO ROLE {{ database_name }}_PROXY_ADMIN;


------------------------------------------------------------------------------------------------
-- Step 3) Assign inheritance of these database roles to the appropriate database/account roles:
------------------------------------------------------------------------------------------------
GRANT DATABASE ROLE RDS_LANDING_ALL_ADMIN TO ROLE {{ database_name }}_PROXY_ADMIN;
GRANT DATABASE ROLE RDS_LANDING_ALL_DEVELOPER TO ROLE DATA_ENGINEER;


----------------------------------------------------------------------------------------------------
-- Step 4) Create read access database roles for anticipated object types (table and stage objects):
----------------------------------------------------------------------------------------------------
CREATE OR REPLACE DATABASE ROLE RDS_LANDING_TABLE_READ;
CREATE OR REPLACE DATABASE ROLE RDS_LANDING_STAGE_READ;


----------------------------------------------------------------------------------------------------
-- Step 5) Assign ownership of these read access database roles to <SCHEMA>_ALL_ADMIN database role:
----------------------------------------------------------------------------------------------------
GRANT OWNERSHIP ON DATABASE ROLE RDS_LANDING_TABLE_READ TO DATABASE ROLE RDS_LANDING_ALL_ADMIN;
GRANT OWNERSHIP ON DATABASE ROLE RDS_LANDING_STAGE_READ TO DATABASE ROLE RDS_LANDING_ALL_ADMIN;


--------------------------------------------------------------------------------------------------------
-- Step 6) Assign inheritance of these read access database roles to <SCHEMA>_ALL_DEVELOPER database role:
--------------------------------------------------------------------------------------------------------
GRANT DATABASE ROLE RDS_LANDING_TABLE_READ TO DATABASE ROLE RDS_LANDING_ALL_DEVELOPER;
GRANT DATABASE ROLE RDS_LANDING_STAGE_READ TO DATABASE ROLE RDS_LANDING_ALL_DEVELOPER;
