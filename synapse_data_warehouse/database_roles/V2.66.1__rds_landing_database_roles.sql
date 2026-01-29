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
