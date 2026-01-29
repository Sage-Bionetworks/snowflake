-- Steps are created following the RBAC design pattern for schemas documented here:
-- https://sagebionetworks.jira.com/wiki/spaces/DPE/pages/4115366084/Managing+Object+Privileges#Schemas

USE DATABASE {{ database_name }}; --noqa: JJ01,PRS,TMP

-----------------------------------------------
-- Step 1) Create the archetype database roles:
-----------------------------------------------
-- <SCHEMA>_ALL_ADMIN database role which will own all the objects
CREATE OR REPLACE DATABASE ROLE RDS_LANDING_ALL_ADMIN;
-- <SCHEMA>_ALL_ANALYST database role which will have read access to all the silver/gold-layer objects
CREATE OR REPLACE DATABASE ROLE RDS_LANDING_ALL_ANALYST;
-- <SCHEMA>_ALL_DEVELOPER database role which will have read access to all the objects
CREATE OR REPLACE DATABASE ROLE RDS_LANDING_ALL_DEVELOPER;


-------------------------------------------------------------------------------------------
-- Step 2) Assign ownership between these database roles and the appropriate account roles:
-------------------------------------------------------------------------------------------
-- <SCHEMA>_ALL_ADMIN database role owns the other archetype database roles
GRANT OWNERSHIP ON DATABASE ROLE RDS_LANDING_ALL_ANALYST TO DATABASE ROLE RDS_LANDING_ALL_ADMIN;
GRANT OWNERSHIP ON DATABASE ROLE RDS_LANDING_ALL_DEVELOPER TO DATABASE ROLE RDS_LANDING_ALL_ADMIN;
-- <DATABASE>_PROXY_ADMIN account role owns the <SCHEMA>_ALL_ADMIN database role
GRANT OWNERSHIP ON DATABASE ROLE RDS_LANDING_ALL_ADMIN TO ROLE {{ database_name }}_PROXY_ADMIN;


---------------------------------------------------------------------------------------
-- Step 3) Assign inheritance of these database roles to the appropriate account roles:
---------------------------------------------------------------------------------------
GRANT USAGE ON DATABASE ROLE RDS_LANDING_ALL_ADMIN TO ROLE {{ database_name }}_PROXY_ADMIN;
GRANT USAGE ON DATABASE ROLE RDS_LANDING_ALL_ANALYST TO ROLE {{ database_name }}_ANALYST;
GRANT USAGE ON DATABASE ROLE RDS_LANDING_ALL_DEVELOPER TO ROLE DATA_ENGINEER;
