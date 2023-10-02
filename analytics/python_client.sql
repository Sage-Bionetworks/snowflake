USE ROLE PUBLIC;
USE WAREHOUSE COMPUTE_ORG;
USE DATABASE synapse_data_warehouse;
USE SCHEMA synapse;

// Distinct client calls this month
SELECT distinct(client)
FROM processedaccess
WHERE DATE(record_date) > DATE('2023-09-01');

// distribution of different client calls


SELECT client, count(*) as num_api_calls
FROM processedaccess
WHERE
    DATE(record_date) >= DATE('2023-08-01') and
    DATE(record_date) < DATE('2023-09-01')
GROUP BY client
ORDER BY num_api_calls DESC
;

SELECT USER_AGENT, count(*) as num_api_calls
FROM processedaccess
WHERE
    DATE(record_date) >= DATE('2023-08-01') and
    DATE(record_date) < DATE('2023-09-01') and
    client = 'UNKNOWN'
GROUP BY USER_AGENT
ORDER BY num_api_calls DESC

;
// Distribution of normalized API calls this month
SELECT normalized_method_signature, count(*) as num_api_calls
FROM processedaccess
WHERE
    DATE(record_date) >= DATE('2023-08-01') and
    DATE(record_date) < DATE('2023-09-01') and
    client = 'PYTHON'
GROUP BY normalized_method_signature
ORDER BY num_api_calls DESC
;

// Distribution of Python API calls this month
SELECT normalized_method_signature, count(*) as num_api_calls
FROM processedaccessrecord
WHERE
    DATE(record_date) > DATE('2023-09-01') and
    client = 'PYTHON'
GROUP BY normalized_method_signature
ORDER BY num_api_calls DESC;


SELECT normalized_method_signature, count(*) as num_api_calls
FROM processedaccess
WHERE
    DATE(record_date) >= DATE('2023-08-01') and
    DATE(record_date) < DATE('2023-09-01') and
    client = 'SYNAPSER'
GROUP BY normalized_method_signature
ORDER BY num_api_calls DESC
;

// Number of Python calls per user
with U
as (
    SELECT user_id, count(*) as user_calls
    FROM processedaccess
    WHERE
        DATE(record_date) > DATE('2023-09-01') and
        client = 'PYTHON'
    group by user_id
),
T as (
    SELECT distinct id, user_name, email
    FROM userprofile_latest
)
select *
FROM U
LEFT JOIN T
ON U.user_id = T.id
ORDER BY user_calls DESC
;
   
// Number of client calls per month
SELECT client, month(record_date) as month_called , count(*) as num_api_calls
FROM processedaccess
WHERE
    DATE(record_date) >= DATE('2023-01-01')
GROUP BY client, month(record_date)
ORDER BY month_called ASC, num_api_calls DESC
;

// User agents of user agents for clients that are unknown.
SELECT user_agent, count(*) as user_agent_count
FROM processedaccess
WHERE
    DATE(record_date) > DATE('2023-09-01') and client = 'UNKNOWN'
GROUP BY user_agent
ORDER BY user_agent_count DESC
;

// User agents that are using the Python aiohttp package 
SELECT *
FROM processedaccess
WHERE
    user_agent = 'Python/3.7 aiohttp/3.7.4.post0' and
    DATE(record_date) > DATE('2023-09-01')
;

// Different client versions for synapse R
SELECT distinct(user_agent)
FROM processedaccess
WHERE
    DATE(record_date) > DATE('2023-09-01') and
    client = 'SYNAPSER'
;
