{% set result_table = var('rejection_result_table', 'DATA_ACCESS_REJECTION_CLASSIFICATION_10') %}

WITH categories AS (
    SELECT category.value:label::VARCHAR AS category
    FROM TABLE(FLATTEN(INPUT => {{ data_access_rejection_categories() }})) AS category
),
assignments AS (
    SELECT
        results.data_access_submission_id,
        label.value::VARCHAR AS category
    FROM {{ target.database }}.RDS_RAW.{{ result_table }} AS results,
        LATERAL FLATTEN(INPUT => results.classification:value:labels) AS label
),
sample_totals AS (
    SELECT COUNT(*) AS sampled_submissions
    FROM {{ target.database }}.RDS_RAW.{{ result_table }}
)

SELECT
    categories.category,
    COUNT(DISTINCT assignments.data_access_submission_id) AS submission_count,
    sample_totals.sampled_submissions,
    ROUND(
        100.0 * COUNT(DISTINCT assignments.data_access_submission_id)
        / NULLIF(sample_totals.sampled_submissions, 0),
        2
    ) AS percent_of_sample
FROM categories
LEFT JOIN assignments ON categories.category = assignments.category
CROSS JOIN sample_totals
GROUP BY categories.category, sample_totals.sampled_submissions
ORDER BY submission_count DESC, categories.category
