USE ROLE PUBLIC;
USE WAREHOUSE COMPUTE_ORG;
USE DATABASE synapse_data_warehouse;
USE SCHEMA synapse_raw;

SELECT distinct(FILE_NAME)
FROM synapse_data_warehouse.synapse_raw.filesnapshots;

// File extensions
with file_extensions as (
    select split_part(FILE_NAME,'.',-1) as fileext
    from synapse_data_warehouse.synapse.file_latest
)
select fileext, count(*) AS number_of_files
from file_extensions
group by fileext
ORDER BY number_of_files DESC;


// Number of change events
SELECT CHANGE_TYPE, count(*) as number_of_events
FROM synapse_data_warehouse.synapse.file_latest
GROUP BY CHANGE_TYPE
;

// Number of counts for different statuses
SELECT STATUS, count(*)
FROM synapse_data_warehouse.synapse.file_latest
GROUP BY STATUS;

-- TODO: Can you extract which projects have these mp4's and the folder
-- names under which they are stored, as a next step?
