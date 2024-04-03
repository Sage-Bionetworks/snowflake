/* 
This is a script to calculate total data size in GiB for each ENTITY_ID (folder or project).
ENTITY_IDs can be a single Synapse folder/project ID or a list of Synapse folder/proejct IDs seperated by comma
*/

USE ROLE DATA_ANALYTICS;
USE DATABASE synapse_data_warehouse;
USE WAREHOUSE COMPUTE_XSMALL;

-- The list of folders to be checked
SET
    ENTITY_IDs = '';

-- Calculate Data Size
WITH RECURSIVE nodesnapshots
    -- Column list of the "view"
    (
        ID,
        PARENT_ID,
        NAME,
        NODE_TYPE,
        FILE_HANDLE_ID,
        ENTITY_ID
    ) 
    AS 
    -- Common Table Expression
    (
        -- Anchor Clause
        SELECT
            ID,
            PARENT_ID,
            NAME,
            NODE_TYPE,
            FILE_HANDLE_ID,
            ID AS ENTITY_ID
        FROM
            synapse_data_warehouse.synapse.node_latest
        WHERE
            ID IN (
                SELECT
                    REPLACE(VALUE, 'syn', '')
                FROM
                    TABLE(SPLIT_TO_TABLE($ENTITY_IDs, ','))
            )
            
        UNION ALL
        
        -- Recursive Clause
        SELECT
            node.ID,
            node.PARENT_ID,
            node.NAME,
            node.NODE_TYPE,
            node.FILE_HANDLE_ID,
            nodesnapshots.ENTITY_ID
        FROM
            synapse_data_warehouse.synapse.node_latest AS node
        JOIN 
            nodesnapshots 
        ON 
            node.PARENT_ID = nodesnapshots.ID
    ) 
-- This is the "main select".
SELECT
    'syn' || nodesnapshots.ENTITY_ID AS ENTITY_ID,
    sum(filesnapshots.CONTENT_SIZE)/ power(2, 30) AS CONTENT_SIZE_in_GiB
FROM
    nodesnapshots
JOIN 
    synapse_data_warehouse.synapse.file_latest AS filesnapshots 
ON 
    nodesnapshots.file_handle_id = filesnapshots.ID
GROUP BY
    nodesnapshots.ENTITY_ID;  
