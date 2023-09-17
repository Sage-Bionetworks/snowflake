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

SELECT count(*)
FROM synapse_data_warehouse.synapse.file_latest
where not IS_PREVIEW;
