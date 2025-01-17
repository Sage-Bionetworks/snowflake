USE DATABASE {{ database_name }}; --noqa: JJ01,PRS,TMP

-- Create database roles which will own the respective namespace's objects
CREATE OR REPLACE DATABASE ROLE SYNAPSE_ALL_ADMIN;
CREATE OR REPLACE DATABASE ROLE SYNAPSE_RAW_ALL_ADMIN;
CREATE OR REPLACE DATABASE ROLE SCHEMACHANGE_ALL_ADMIN;

-- Grant ownership of the database roles to the database admin
GRANT OWNERSHIP
    ON DATABASE ROLE SYNAPSE_ALL_ADMIN
    TO ROLE {{ database_name }}_ADMIN; --noqa: JJ01,PRS,TMP
GRANT OWNERSHIP
    ON DATABASE ROLE SYNAPSE_RAW_ALL_ADMIN
    TO ROLE {{ database_name }}_ADMIN; --noqa: JJ01,PRS,TMP
GRANT OWNERSHIP
    ON DATABASE ROLE SCHEMACHANGE_ALL_ADMIN
    TO ROLE {{ database_name }}_ADMIN; --noqa: JJ01,PRS,TMP

-- Grant database roles to account roles
GRANT DATABASE ROLE SYNAPSE_ALL_ADMIN
    TO ROLE {{ database_name }}_ADMIN; --noqa: JJ01,PRS,TMP
GRANT DATABASE ROLE SYNAPSE_RAW_ALL_ADMIN
    TO ROLE {{ database_name }}_ADMIN; --noqa: JJ01,PRS,TMP
GRANT DATABASE ROLE SCHEMACHANGE_ALL_ADMIN
    TO ROLE {{ database_name }}_ADMIN; --noqa: JJ01,PRS,TMP
