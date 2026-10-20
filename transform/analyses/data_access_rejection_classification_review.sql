{% set result_table = var('rejection_result_table', 'DATA_ACCESS_REJECTION_CLASSIFICATION_10') %}

SELECT
    data_access_submission_id,
    rejection_reason,
    classification:value:labels AS categories,
    classification:error::VARCHAR AS classification_error
FROM {{ target.database }}.RDS_RAW.{{ result_table }}
WHERE
    classification:value:labels IS NULL
    OR ARRAY_SIZE(classification:value:labels) = 0
    OR classification:error::VARCHAR IS NOT NULL
    OR ARRAY_CONTAINS(
        'Other - Unmapped or unclear reason'::VARIANT,
        classification:value:labels
    )
ORDER BY data_access_submission_id
