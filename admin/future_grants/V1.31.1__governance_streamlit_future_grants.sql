-- Future ownership of Streamlit objects in SAGE.GOVERNANCE for the admin role,
-- and viewer access for the analyst role.
GRANT OWNERSHIP
    ON FUTURE STREAMLIT
    IN SCHEMA SAGE.GOVERNANCE
    TO ROLE SAGE_GOVERNANCE_ADMIN;
GRANT USAGE
    ON FUTURE STREAMLIT
    IN SCHEMA SAGE.GOVERNANCE
    TO ROLE SAGE_GOVERNANCE_ANALYST;

-- Future ownership of stages in SAGE.GOVERNANCE for the admin role.
-- Stages are used as source locations for Streamlit app files.
GRANT OWNERSHIP
    ON FUTURE STAGES
    IN SCHEMA SAGE.GOVERNANCE
    TO ROLE SAGE_GOVERNANCE_ADMIN;
