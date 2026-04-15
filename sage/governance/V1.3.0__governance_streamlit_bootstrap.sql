USE SCHEMA {{ database_name }}.governance;

-- STREAMLIT objects do not support (future) ownership grants
-- We will need to create them as their intended owner
USE ROLE SAGE_GOVERNANCE_ADMIN;

-- This DDL is a formality:
-- File population and Streamlit object lifecycle are managed by Snowflake CLI in CI.
CREATE OR REPLACE STREAMLIT data_access_dashboard;
