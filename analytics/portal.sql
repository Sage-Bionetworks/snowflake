USE ROLE SYSADMIN;
USE DATABASE SYNAPSE_DATA_WAREHOUSE;
USE SCHEMA SYNAPSE;
-- Data up to October 18th for now

-- Total number of downloads in synapse
WITH dedup_filehandle AS (
    select
        distinct user_id, file_handle_id as fd_file_handle_id, record_date
    from
        synapse_data_warehouse.synapse.filedownload
)
select
    count(*)
from
    dedup_filehandle;
WITH dedup_filehandle AS (
    select
        distinct user_id, file_handle_id as fd_file_handle_id, record_date
    from
        synapse_data_warehouse.synapse.filedownload
)
select
    DATE_TRUNC('MONTH', record_date) as month,
    count(*) as number_of_downloads
from
    dedup_filehandle
group by
    month
order by
    month DESC;
-- * Number of files within each portal in snowflake
USE SCHEMA sage.portal_raw;
SELECT
    table_name,
    row_count
FROM
    INFORMATION_SCHEMA.TABLES
WHERE
    TABLE_SCHEMA = 'PORTAL_RAW'
order by
    row_count DESC;

-- When do file download records begin?
select
    distinct record_date
from
    synapse_data_warehouse.synapse_raw.filedownload
order by
    record_date ASC;

-- * Metrics for AD portal
CREATE TABLE ad_downloads AS (
with dedup_filedownload AS (
    select
        distinct user_id, file_handle_id as fd_file_handle_id, record_date
    from
        synapse_data_warehouse.synapse.filedownload
)
select
    *
from
    sage.portal_raw.ad
LEFT JOIN
    dedup_filedownload fd
ON
    ad."dataFileHandleId" = fd.fd_file_handle_id
);
-- Total download count for AD portal
select
    count(*)
from
    ad_downloads;
-- distribution of AD portal downloads per month
select
    DATE_TRUNC('MONTH', record_date) as month,
    count(*) as number_of_downloads
from
    ad_downloads
group by
    month
order by
    month DESC;

select
    count(distinct user_id)
from 
    ad_downloads;

-- * GENIE
-- All download counts over time
CREATE TABLE genie_downloads AS (
with dedup_filedownload AS (
    select
        distinct user_id, file_handle_id as fd_file_handle_id, record_date
    from
        synapse_data_warehouse.synapse.filedownload
)
select
    *
from
    sage.portal_raw.genie genie
LEFT JOIN
    dedup_filedownload fd
ON
    genie."dataFileHandleId" = fd.fd_file_handle_id
);
select
    count(*)
from
    genie_downloads;

select
    DATE_TRUNC('MONTH', record_date) as month,
    count(*) as number_of_downloads
from
    genie_downloads
group by
    month
order by
    month DESC;

select
    count(distinct user_id)
from 
    genie_downloads;
-- * ELITE
CREATE TABLE elite_downloads AS (
WITH elite_transform AS (
    SELECT
        *, CAST(REPLACE("id", 'syn', '') AS INTEGER) as syn_id
    FROM
        sage.portal_raw.elite
),
dedup_filedownload AS (
    select
        distinct user_id, file_handle_id as fd_file_handle_id, record_date
    from
        synapse_data_warehouse.synapse.filedownload
),
download_count AS (
    SELECT *
    FROM elite_transform
    LEFT JOIN
        synapse_data_warehouse.synapse.node_latest node_latest
    ON
        elite_transform.syn_id = node_latest.id
    INNER JOIN
        dedup_filedownload fd
    ON
        node_latest.file_handle_id = fd.fd_file_handle_id
)
SELECT
    *
FROM
    download_count
);

select
    count(*)
from    
    elite_downloads;
select
    DATE_TRUNC('MONTH', record_date) as month,
    count(*) as number_of_downloads
from
    elite_downloads
group by
    month
order by
    month DESC;

select
    count(distinct user_id)
from 
    elite_downloads;

-- * NF
-- Total downloads
CREATE TABLE nf_downloads AS (
WITH nf_transform AS (
    SELECT
        *, CAST(REPLACE("id", 'syn', '') AS INTEGER) as syn_id
    FROM
        sage.portal_raw.nf
),
dedup_filedownload AS (
    select
        distinct user_id, file_handle_id as fd_file_handle_id, record_date
    from
        synapse_data_warehouse.synapse.filedownload
),
download_count AS (
    SELECT
        *
    FROM
        nf_transform
    LEFT JOIN
        synapse_data_warehouse.synapse.node_latest node_latest
    ON
        nf_transform.syn_id = node_latest.id
    INNER JOIN
        dedup_filedownload fd
    ON
        node_latest.file_handle_id = fd.fd_file_handle_id
)
SELECT
    *
FROM
    download_count
);

select
    count(*)
from
    nf_downloads;
select
    DATE_TRUNC('MONTH', record_date) as month,
    count(*) as number_of_downloads
from
    nf_downloads
group by
    month
order by
    month DESC;
select
    count(distinct user_id)
from 
    nf_downloads;

-- psychencode
CREATE TABLE psychencode_downloads AS (
WITH psychencode_transform AS (
    SELECT
        *, CAST(REPLACE("id", 'syn', '') AS INTEGER) as syn_id
    FROM
        sage.portal_raw.psychencode
),
dedup_filedownload AS (
    select
        distinct user_id, file_handle_id as fd_file_handle_id, record_date
    from
        synapse_data_warehouse.synapse.filedownload
),
download_count AS (
    SELECT *
    FROM
        psychencode_transform
    LEFT JOIN
        synapse_data_warehouse.synapse.node_latest node_latest
    ON
        psychencode_transform.syn_id = node_latest.id
    INNER JOIN
        dedup_filedownload fd
    ON
        node_latest.file_handle_id = fd.fd_file_handle_id
)
SELECT
    *
FROM
    download_count
);
select
    count(*)
from
    psychencode_downloads;

select
    DATE_TRUNC('MONTH', record_date) as month,
    count(*) as number_of_downloads
from
    psychencode_downloads
group by
    month
order by
    month DESC;
select
    count(distinct user_id)
from 
    psychencode_downloads;
-- HTAN
CREATE TABLE htan_downloads AS (
WITH htan_transform AS (
    SELECT
        *, CAST(REPLACE("entityId", 'syn', '') AS INTEGER) as syn_id
    FROM
        sage.portal_raw.htan
),
dedup_filedownload AS (
    select
        distinct user_id, file_handle_id as fd_file_handle_id, record_date
    from
        synapse_data_warehouse.synapse.filedownload
),
download_count AS (
    SELECT
        *
    FROM
        htan_transform
    LEFT JOIN
        synapse_data_warehouse.synapse.node_latest node_latest
    ON
        htan_transform.syn_id = node_latest.id
    INNER JOIN
        dedup_filedownload fd
    ON
        node_latest.file_handle_id = fd.fd_file_handle_id
)
SELECT
    *
FROM
    download_count
);

select
    count(*)
from
    htan_downloads;

select
    DATE_TRUNC('MONTH', record_date) as month,
    count(*) as number_of_downloads
from
    htan_downloads
group by
    month
order by
    month DESC;

select
    count(distinct user_id)
from 
    htan_downloads;
