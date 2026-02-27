USE DATABASE {{database_name}}; --noqa: JJ01,PRS,TMP

----------------------------------------------------------------------------------------------------
-- Step 1) Create read access database role for view objects:
----------------------------------------------------------------------------------------------------
CREATE OR REPLACE DATABASE ROLE RDS_RAW_VIEW_READ;


----------------------------------------------------------------------------------------------------
-- Step 2) Assign ownership of this read access database role to RDS_RAW_ALL_ADMIN database role:
----------------------------------------------------------------------------------------------------
GRANT OWNERSHIP ON DATABASE ROLE RDS_RAW_VIEW_READ TO DATABASE ROLE RDS_RAW_ALL_ADMIN;


--------------------------------------------------------------------------------------------------------
-- Step 3) Assign inheritance of this read access database role to RDS_RAW_ALL_DEVELOPER database role:
--------------------------------------------------------------------------------------------------------
GRANT DATABASE ROLE RDS_RAW_VIEW_READ TO DATABASE ROLE RDS_RAW_ALL_DEVELOPER;