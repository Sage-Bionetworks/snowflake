USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

-- Drop the ``NODE_LATEST`` table so that a new dynamic table with the same name can be created in its place
DROP TABLE {{database_name}}.synapse.NODE_LATEST; --noqa: JJ01,PRS,TMP