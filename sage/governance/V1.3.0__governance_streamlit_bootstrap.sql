USE SCHEMA {{ database_name }}.governance;

-- This DDL is a formality:
-- File population and Streamlit object lifecycle are managed by Snowflake CLI in CI.
CREATE OR REPLACE STREAMLIT data_access_dashboard;
