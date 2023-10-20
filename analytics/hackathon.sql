USE ROLE PUBLIC;
USE DATABASE SYNAPSE_DATA_WAREHOUSE;
USE SCHEMA SYNAPSE;

-- Latest user profiles

SELECT
    *
FROM
    userprofile_latest
where
    user_name = 'thomas.yu';

-- what if you wanted to get all the sage users?

SELECT
    *
FROM
    userprofile_latest
where
    email like ('%sagebase.org');

-- How about distribution of emails
-- Type into copilot: Distribution of emails in the userprofile_latest table in SQL
-- Type into copilot: order the results in descending order
SELECT
    email,
    COUNT(*) as email_count
FROM
    userprofile_latest
GROUP BY
    email
ORDER BY
    email_count DESC;

-- If you joined a certain time, the certified quiz table hasn't been backfilled enough
-- You'll see I'm not part of this list
-- I confirmed within Athena
-- This is a good example of a Jira ticket to Platform
SELECT
    *
FROM
    CERTIFIEDQUIZ_LATEST
where
    USER_ID = 3324230;


SELECT
    *
FROM
    user_certified
WHERE
    email like '%@sagebase.org' and
    PASSED;

-- tables in portal
SHOW TABLES IN sage.portal_raw;


-- GENIE - data mesh with public portal data
-- Data up to October 18th
--
with test AS (
    select
        distinct user_id, file_handle_id
    from
        synapse_data_warehouse.synapse.filedownload
)
select genie."id", genie."name", genie."version", count(*) as number_of_downloads
from sage.portal_raw.genie genie
LEFT JOIN
    synapse_data_warehouse.synapse.filedownload fd
ON
    genie."dataFileHandleId" = fd.file_handle_id
GROUP BY
    genie."id", genie."name", genie."version"
ORDER BY
    genie."version" DESC
;

-- Download counts for AD files
-- Data up to September 1st
select ad."id", ad."name", ad."study", count(*) as number_of_downloads
from sage.portal_raw.ad
LEFT JOIN
    synapse_data_warehouse.synapse.filedownload fd
ON
    ad."dataFileHandleId" = fd.file_handle_id
GROUP BY
    ad."id", ad."name", ad."study"
ORDER BY
    number_of_downloads DESC
;

-- Number of downloads per study
select ad."study", count(*) as number_of_downloads
from sage.portal_raw.ad
LEFT JOIN
    synapse_data_warehouse.synapse.filedownload fd
ON
    ad."dataFileHandleId" = fd.file_handle_id
GROUP BY
    ad."study"
ORDER BY
    number_of_downloads DESC
;

-- elite portal
WITH elite_transform AS (
    SELECT *, CAST(REPLACE("id", 'syn', '') AS INTEGER) as syn_id
    FROM sage.portal_raw.elite
),
node_latest AS (
    SELECT *
    FROM synapse_data_warehouse.synapse.node_latest
),
download_count AS (
    SELECT *
    FROM elite_transform
    LEFT JOIN
        node_latest
    ON
        elite_transform.syn_id = node_latest.id
    INNER JOIN
        synapse_data_warehouse.synapse.filedownload fd
    ON
        node_latest.file_handle_id = fd.file_handle_id
)
SELECT "id", "name", "study", count(*) as number_of_downloads
FROM download_count
GROUP BY
    "id", "name", "study"
ORDER BY
    number_of_downloads DESC
;

-- HTAN
WITH htan_transform AS (
    SELECT *, CAST(REPLACE("entityId", 'syn', '') AS INTEGER) as syn_id
    FROM sage.portal_raw.htan
),
node_latest AS (
    SELECT *
    FROM synapse_data_warehouse.synapse.node_latest
),
download_count AS (
    SELECT *
    FROM htan_transform
    LEFT JOIN
        node_latest
    ON
        htan_transform.syn_id = node_latest.id
    INNER JOIN
        synapse_data_warehouse.synapse.filedownload fd
    ON
        node_latest.file_handle_id = fd.file_handle_id
)
SELECT "entityId", "Component", count(*) as number_of_downloads
FROM download_count
GROUP BY
    "entityId", "Component"
ORDER BY
    number_of_downloads DESC
;

-- NF
WITH nf_transform AS (
    SELECT *, CAST(REPLACE("id", 'syn', '') AS INTEGER) as syn_id
    FROM sage.portal_raw.nf
),
node_latest AS (
    SELECT *
    FROM synapse_data_warehouse.synapse.node_latest
),
download_count AS (
    SELECT *
    FROM nf_transform
    LEFT JOIN
        node_latest
    ON
        nf_transform.syn_id = node_latest.id
    INNER JOIN
        synapse_data_warehouse.synapse.filedownload fd
    ON
        node_latest.file_handle_id = fd.file_handle_id
)
SELECT "studyName", count(*) as number_of_downloads
FROM download_count
GROUP BY
    "studyName"
ORDER BY
    number_of_downloads DESC
;

-- psychencode
WITH psychencode_transform AS (
    SELECT *, CAST(REPLACE("id", 'syn', '') AS INTEGER) as syn_id
    FROM sage.portal_raw.psychencode
),
node_latest AS (
    SELECT *
    FROM synapse_data_warehouse.synapse.node_latest
),
download_count AS (
    SELECT *
    FROM
        psychencode_transform
    LEFT JOIN
        node_latest
    ON
        psychencode_transform.syn_id = node_latest.id
    INNER JOIN
        synapse_data_warehouse.synapse.filedownload fd
    ON
        node_latest.file_handle_id = fd.file_handle_id
)
SELECT
    value, count(*) as number_of_downloads
FROM
    download_count,
    LATERAL FLATTEN("study") flattened
group by
    value
order by
    number_of_downloads DESC    
;

-- most expensive s3 pricing option: 0.023 per GB
-- GENIE storage only costs
WITH genie_with_cost AS (
    select "id", "name", "version", ("dataFileSizeBytes" / 1000000000) * 0.023 * 12 as price_per_year
    FROM sage.portal_raw.genie
)
SELECT sum(price_per_year)
FROM genie_with_cost;

-- AD storage costs
select sum("dataFileSizeBytes" / 1000000000)
FROM sage.portal_raw.ad;
-- 766 Terabytes of data

WITH ad_with_cost AS (
    select "id", "name", ("dataFileSizeBytes" / 1000000000) * 0.023 * 12 as price_per_year
    FROM sage.portal_raw.ad
)
SELECT sum(price_per_year)
FROM ad_with_cost;

-- NOTE: The cost of for sage could be lower because...
--     it's over 500TB (0.021 per GB)
--     it's in external bucket that sage doesn't pay for 
--     files are in cold storage
