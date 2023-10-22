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

-- * Can you extract which projects have these mp4's and the folder
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

-- traffic via portals via "ORIGIN"> The host name of the portal making the request, e.g., https://staging.synapse.org, https://adknowledgeportal.synapse.org, https://dhealth.synapse.org.
select
    origin,
    count(*) as number_of_requests,
    count(distinct user_id) as number_of_unique_users
from
    synapse_data_warehouse.synapse.processedaccess
where
    origin like '%synapse.org' and
    origin not like '%staging%' and
    record_date > '2023-01-01'
group by origin
order by number_of_requests DESC;

-- Top downloaded public projects since 2022-01-01
WITH DEDUP_FILEHANDLE AS (
    SELECT DISTINCT
        USER_ID,
        FILE_HANDLE_ID AS FD_FILE_HANDLE_ID,
        RECORD_DATE,
        PROJECT_ID
    FROM
        SYNAPSE_DATA_WAREHOUSE.SYNAPSE.FILEDOWNLOAD
),
public_projects AS (
    select
        distinct project_id
    from
        synapse_data_warehouse.synapse.node_latest
    where
        is_public and
        node_type = 'project'
)
SELECT
    project_id,
    count(*) as downloads_per_project,
    count(distinct user_id) as number_of_unique_users_downloaded,
    count(distinct fd_file_handle_id) as number_of_unique_files_downloaded
FROM
    DEDUP_FILEHANDLE
where
    project_id in (select project_id from public_projects)
group by
    project_id
order by
    downloads_per_project DESC;

-- Top downloaded public projects for September 2023

WITH DEDUP_FILEHANDLE AS (
    SELECT DISTINCT
        USER_ID,
        FILE_HANDLE_ID AS FD_FILE_HANDLE_ID,
        RECORD_DATE,
        PROJECT_ID
    FROM
        SYNAPSE_DATA_WAREHOUSE.SYNAPSE.FILEDOWNLOAD
    WHERE
        record_date >= '2023-09-01' and record_date < '2023-10-01'
),
public_projects AS (
    select
        distinct project_id
    from
        synapse_data_warehouse.synapse.node_latest
    where
        is_public and
        node_type = 'project'
)
SELECT
    project_id,
    count(*) as downloads_per_project,
    count(distinct user_id) as number_of_unique_users_downloaded,
    count(distinct fd_file_handle_id) as number_of_unique_files_downloaded
FROM
    DEDUP_FILEHANDLE
where
    project_id in (select project_id from public_projects)
group by
    project_id
order by
    downloads_per_project DESC;

-- number of different governance types in synapse
with file_fd as (
    select
        id as file_id, content_size
    from
        synapse_data_warehouse.synapse.file_latest
)
select
    is_public,
    is_controlled,
    is_restricted,
    count(*) as number_of_files,
    sum(content_size) / 1000000000000 as total_size_in_terabytes
from
    synapse_data_warehouse.synapse.node_latest node
left join
    file_fd
on
    node.file_handle_id = file_fd.file_id
where
    node_type = 'file'
group by
    is_public, is_controlled, is_restricted
order by
    number_of_files DESC;

-- get number of DOI calls
select
    count(distinct request_url)
from
    synapse_data_warehouse.synapse.processedaccess
where
    normalized_method_signature = 'GET /doi/async/get/#' and
    success;


-- client
SELECT
    client, count(*) as number_of_calls
FROM
    synapse_data_warehouse.synapse.processedaccess
group by
    client
order by
    number_of_calls DESC;
