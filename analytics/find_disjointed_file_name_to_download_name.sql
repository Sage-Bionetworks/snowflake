-- This was a small query put together for https://sagebionetworks.jira.com/browse/SYNSD-893
-- The query is looking for files that have a different name than the entity they are associated with
USE ROLE DATA_ENGINEER;
USE WAREHOUSE COMPUTE_XSMALL;
USE DATABASE SYNAPSE_DATA_WAREHOUSE;
USE SCHEMA SYNAPSE;

-- This is looking by parent_ID
SELECT ENTITY_LATEST.id, ENTITY_LATEST.name, FILE_LATEST.FILE_NAME, FILE_LATEST.CONTENT_MD5 FROM synapse_data_warehouse.synapse.node_latest ENTITY_LATEST
inner join
    synapse_data_warehouse.synapse.file_latest FILE_LATEST
on
    ENTITY_LATEST.file_handle_id = FILE_LATEST.ID
WHERE ENTITY_LATEST.PARENT_ID = 51286684
AND FILE_LATEST.FILE_NAME != ENTITY_LATEST.name