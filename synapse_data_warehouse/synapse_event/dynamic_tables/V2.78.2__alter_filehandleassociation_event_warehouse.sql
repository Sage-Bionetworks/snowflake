USE SCHEMA {{database_name}}.synapse_event; --noqa: JJ01,PRS,TMP

-- V2.78.0 creates this table on COMPUTE_MEDIUM for its expensive initial refresh.
-- Incremental refreshes are small, so move it back to COMPUTE_XSMALL.
ALTER DYNAMIC TABLE filehandleassociation_event SET WAREHOUSE = COMPUTE_XSMALL;
