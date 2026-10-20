{% set result_table = var('rejection_result_table', 'DATA_ACCESS_REJECTION_CLASSIFICATION_10') %}

WITH results AS (
    SELECT
        data_access_submission_id,
        rejection_reason,
        {{ data_access_rejection_effective_labels('classification') }} AS categories,
        classification:value:labels AS raw_categories,
        ARRAY_SIZE(classification:value:labels) = 0 AS used_other_fallback,
        classification:error::VARCHAR AS classification_error
    FROM {{ target.database }}.RDS_RAW.{{ result_table }}
)

SELECT *
FROM results
WHERE
    categories IS NULL
    OR TYPEOF(categories) <> 'ARRAY'
    OR ARRAY_SIZE(categories) = 0
    OR classification_error IS NOT NULL
    OR ARRAY_CONTAINS(
        'Other - Unmapped or unclear reason'::VARIANT,
        categories
    )
ORDER BY data_access_submission_id
