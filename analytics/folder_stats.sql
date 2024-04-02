/* 
This script contains two parts: 1. lay out folder structure of the targeted FOLDER_IDs;
2. calculate total data size in GiB for each FOLDER_ID.
FOLDER_IDs can be a single Synapse folder ID or a list of Synapse folder IDs seperated by comma
*/

USE ROLE DATA_ANALYTICS;
USE DATABASE synapse_data_warehouse;
USE WAREHOUSE COMPUTE_XSMALL;

-- The list of folders to be checked
SET
    FOLDER_IDs = '';

-- Lay Out Data Structure
WITH RECURSIVE nodesnapshots 
    -- Column list of the "view"
    (
        ID,
        PARENT_ID,
        NAME,
        NODE_TYPE,
        FILE_HANDLE_ID,
        FOLDER_ID
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
            ID AS FOLDER_ID
        FROM
            synapse_data_warehouse.synapse.node_latest
        WHERE
            ID IN (
                SELECT
                    REPLACE(VALUE, 'syn', '')
                FROM
                    TABLE(SPLIT_TO_TABLE($FOLDER_IDs, ','))
            )
            
        UNION ALL
        
        -- Recursive Clause
        SELECT
            node.ID,
            node.PARENT_ID,
            node.NAME,
            node.NODE_TYPE,
            node.FILE_HANDLE_ID,
            nodesnapshots.FOLDER_ID
        FROM
            synapse_data_warehouse.synapse.node_latest AS node
        JOIN 
            nodesnapshots
        ON
            node.PARENT_ID = nodesnapshots.ID
    ) 
-- This is the "main select".
SELECT
    'syn' || nodesnapshots.FOLDER_ID AS FOLDER_ID,
    'syn' || nodesnapshots.PARENT_ID AS PARENT_ID,
    'syn' || nodesnapshots.ID AS ID,
    COUNT(nodesnapshots.ID) AS COUNTS,
    nodesnapshots.NAME,
    nodesnapshots.NODE_TYPE,
    nodesnapshots.FILE_HANDLE_ID,
    filesnapshots.CONTENT_SIZE
FROM
    nodesnapshots
JOIN 
    synapse_data_warehouse.synapse.file_latest AS filesnapshots 
ON nodesnapshots.file_handle_id = filesnapshots.ID
GROUP BY nodesnapshots.FOLDER_ID;

-- Calculate Data Size
WITH RECURSIVE nodesnapshots
    -- Column list of the "view"
    (
        ID,
        PARENT_ID,
        NAME,
        NODE_TYPE,
        FILE_HANDLE_ID,
        FOLDER_ID
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
            ID AS FOLDER_ID
        FROM
            synapse_data_warehouse.synapse.node_latest
        WHERE
            ID IN (
                SELECT
                    REPLACE(VALUE, 'syn', '')
                FROM
                    TABLE(SPLIT_TO_TABLE($FOLDER_IDs, ','))
            )
            
        UNION ALL
        
        -- Recursive Clause
        SELECT
            node.ID,
            node.PARENT_ID,
            node.NAME,
            node.NODE_TYPE,
            node.FILE_HANDLE_ID,
            nodesnapshots.FOLDER_ID
        FROM
            synapse_data_warehouse.synapse.node_latest AS node
        JOIN 
            nodesnapshots 
        ON 
            node.PARENT_ID = nodesnapshots.ID
    ) 
-- This is the "main select".
SELECT
    'syn' || nodesnapshots.FOLDER_ID AS FOLDER_ID,
    sum(filesnapshots.CONTENT_SIZE)/ power(2, 30) AS CONTENT_SIZE_in_GiB
FROM
    nodesnapshots
JOIN 
    synapse_data_warehouse.synapse.file_latest AS filesnapshots 
ON 
    nodesnapshots.file_handle_id = filesnapshots.ID
GROUP BY
    nodesnapshots.FOLDER_ID;  
