USE ROLE PUBLIC;
USE WAREHOUSE COMPUTE_ORG;
USE DATABASE synapse_data_warehouse;

// File extensions
select * from synapse_data_warehouse.synapse.node_latest limit 10;
with file_extensions as (
    select split_part(name,'.',-1) as fileext
    from synapse_data_warehouse.synapse.node_latest
)
select fileext, count(*) AS number_of_files
from file_extensions
group by fileext
ORDER BY number_of_files DESC;

-- TODO: Can you extract which projects have these mp4's and the folder
-- names under which they are stored, as a next step?
with file_extensions as (
    select
        project_id,
        parent_id,
        split_part(name,'.',-1) as fileext
    from
        synapse_data_warehouse.synapse.node_latest
)
select
    distinct project_id
from
    file_extensions
where
    fileext ilike 'MP4';

with file_extensions as (
    select
        project_id,
        parent_id,
        split_part(name,'.',-1) as fileext
    from
        synapse_data_warehouse.synapse.node_latest
)
select
    project_id, count(*) as number_of_mp4s
from
    file_extensions
where
    fileext ilike 'MP4'
group by project_id
order by number_of_mp4s DESC;

// Number of change events
SELECT CHANGE_TYPE, count(*) as number_of_events
FROM synapse_data_warehouse.synapse.file_latest
GROUP BY CHANGE_TYPE
;

// Number of counts for different statuses
SELECT STATUS, count(*)
FROM synapse_data_warehouse.synapse.file_latest
GROUP BY STATUS;

