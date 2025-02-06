USE DATABASE {{ database_name }}; --noqa: JJ01,PRS,TMP

-- Create proxy admin database role which will own the `*ALL_ADMIN` roles
CREATE OR REPLACE DATABASE ROLE ALL_ADMIN;

-- Grant ownership of the proxy admin database role to the database admin
GRANT OWNERSHIP
    ON DATABASE ROLE ALL_ADMIN
    TO ROLE {{ database_name }}_ADMIN; --noqa: JJ01,PRS,TMP

-- Grant proxy admin role to the database admin account role
GRANT DATABASE ROLE ALL_ADMIN
    TO ROLE {{ database_name }}_ADMIN; --noqa: JJ01,PRS,TMP