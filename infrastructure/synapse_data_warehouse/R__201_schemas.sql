USE ROLE SYSADMIN;
USE DATABASE {{ database_name }};

CREATE OR ALTER SCHEMA SYNAPSE_RAW WITH MANAGED ACCESS;
CREATE OR ALTER SCHEMA SYNAPSE WITH MANAGED ACCESS;
CREATE OR ALTER SCHEMA SYNAPSE_AGGREGATE;
CREATE OR ALTER SCHEMA SYNAPSE_EVENT
COMMENT = 'Event data is derived from raw data by retaining only the most recent snapshot for each distinct event. The identifier of an event is determined by a subset of columns which uniquely identifies the occurrence or instance of an event.';
CREATE OR ALTER SCHEMA RDS_LANDING;
CREATE OR ALTER SCHEMA RDS_RAW;
