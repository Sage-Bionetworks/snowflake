USE ROLE PUBLIC;
USE WAREHOUSE COMPUTE_ORG;

USE DATABASE synapse_data_warehouse;
USE SCHEMA synapse_raw;

SELECT distinct(FILE_NAME)
FROM synapse_data_warehouse.synapse_raw.filesnapshots;

-- select distinct FILE_NAME
-- from synapse_data_warehouse.synapse_raw.filesnapshots
-- where year(snapshot_date) = 2023 and month(snapshot_date) = 8 and day(snapshot_date) = 3;

-- with file_extensions as (
--     select split_part(FILE_NAME,'.',-1) as fileext
--     from synapse_data_warehouse.synapse_raw.filesnapshots
--     where year(snapshot_date) = 2023 and month(snapshot_date) = 8 and day(snapshot_date) = 3
-- )
-- select fileext, count(*) AS number_of_files
-- from file_extensions
-- group by fileext
-- ORDER BY number_of_files DESC;

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

// Can you extract which projects have these mp4's and the folder
// names under which they are stored, as a next step?
SELECT *
FROM synapse_data_warehouse.synapse.file_latest
LIMIT 10;

select *
from synapse_data_warehouse.synapse_raw.nodesnapshots
LIMIT 10;

// Look into this: https://github.com/nf-osi/usagereports/blob/main/notes.md
// https://github.com/nf-osi/usagereports/blob/patch/pkg-update/README.md#workflow


-- ## Number of calls per user
-- with U
-- as (
--     SELECT user_id, count(*) as user_calls
--     FROM processedaccessrecord
--     WHERE
--         DATE(record_date) > DATE('2023-09-01') and
--         client = 'PYTHON'
--     group by user_id
-- ),
-- T as (
--     SELECT distinct id, user_name
--     FROM userprofilesnapshots
-- )
-- select *
-- FROM U
-- LEFT JOIN T
-- ON U.user_id = T.id
-- ORDER BY user_calls DESC
-- ;
   