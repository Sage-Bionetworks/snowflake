USE DATABASE {{ database_name }};

-- SAGE.AD already exists in Snowflake; CREATE SCHEMA is intentionally omitted.
SELECT 1; -- required to avoid schemachange "Empty SQL Statement" error
