USE SCHEMA {{ database_name }}.GOVERNANCE;

-- Internal named stage for the governance dashboard Streamlit app source files.
-- File population and Streamlit object lifecycle are managed by Snowflake CLI in CI.
CREATE STAGE IF NOT EXISTS governance_dashboard_stage;
