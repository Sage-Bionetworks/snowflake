USE DATABASE {{ database_name }}; --noqa: JJ01,PRS,TMP

-- Masked table-read role: same table-level access as RDS_RAW_TABLE_READ, but
-- excluded from the RDS_RAW_TABLE_READ check in the RDS_RAW PII masking policies.
CREATE OR REPLACE DATABASE ROLE RDS_RAW_TABLE_READ_MASKED;

-- Grant ownership to the RDS_RAW admin role
GRANT OWNERSHIP
    ON DATABASE ROLE RDS_RAW_TABLE_READ_MASKED
    TO DATABASE ROLE RDS_RAW_ALL_ADMIN;

-- Aggregate analyst role that inherits the masked read role, for account roles
-- that should only ever see masked RDS_RAW data.
CREATE OR REPLACE DATABASE ROLE RDS_RAW_ALL_ANALYST;

GRANT OWNERSHIP
    ON DATABASE ROLE RDS_RAW_ALL_ANALYST
    TO DATABASE ROLE RDS_RAW_ALL_ADMIN;

GRANT DATABASE ROLE RDS_RAW_TABLE_READ_MASKED
    TO DATABASE ROLE RDS_RAW_ALL_ANALYST;
