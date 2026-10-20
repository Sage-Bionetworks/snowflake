{% set result_table = var('rejection_result_table', 'DATA_ACCESS_REJECTION_CLASSIFICATION_10') %}

WITH categories AS (
    SELECT category.value:label::VARCHAR AS category
    FROM TABLE(FLATTEN(INPUT => {{ data_access_rejection_categories() }})) AS category
),
results AS (
    SELECT
        *,
        {{ data_access_rejection_effective_labels('classification') }} AS categories
    FROM {{ target.database }}.RDS_RAW.{{ result_table }}
),
unexpected_labels AS (
    SELECT COUNT(*) AS unexpected_label_count
    FROM results,
        LATERAL FLATTEN(INPUT => results.categories) AS label
    WHERE label.value::VARCHAR NOT IN (SELECT category FROM categories)
)

SELECT
    COUNT(*) AS sampled_submissions,
    COUNT(DISTINCT results.data_access_submission_id) AS distinct_submission_ids,
    COUNT_IF(NULLIF(TRIM(results.rejection_reason), '') IS NULL) AS blank_reasons,
    COUNT_IF(results.classification:error::VARCHAR IS NOT NULL) AS classification_errors,
    COUNT_IF(ARRAY_SIZE(results.classification:value:labels) = 0) AS empty_label_fallbacks,
    COUNT_IF(
        results.categories IS NULL
        OR TYPEOF(results.categories) <> 'ARRAY'
        OR ARRAY_SIZE(results.categories) = 0
    ) AS missing_or_invalid_labels,
    unexpected_labels.unexpected_label_count
FROM results
CROSS JOIN unexpected_labels
GROUP BY unexpected_labels.unexpected_label_count
