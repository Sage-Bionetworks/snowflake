WITH rejected_submissions AS (
    SELECT
        submission_id AS data_access_submission_id,
        -- Older status records can contain invalid UTF-8, as in the status staging model.
        CASE
            WHEN TO_TIMESTAMP_NTZ(created_on / 1000) >= '2019-01-01'
                THEN TO_VARCHAR(reason, 'utf-8')
        END AS rejection_reason
    FROM {{ source('rds', 'data_access_submission_status') }}
    WHERE UPPER(state) = 'REJECTED'
)

SELECT
    data_access_submission_id,
    rejection_reason
FROM rejected_submissions
