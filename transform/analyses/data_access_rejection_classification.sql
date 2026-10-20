{% set sample_size = var('rejection_sample_size', 10) | int %}
{% set sample_seed = var('rejection_sample_seed', 406) | int %}

WITH sampled_rejections AS (
    SELECT
        data_access_submission_id,
        rejection_reason
    FROM {{ ref('stg_synapse__data_access_submission_rejection') }}
    WHERE NULLIF(TRIM(rejection_reason), '') IS NOT NULL
    ORDER BY
        HASH(data_access_submission_id, {{ sample_seed }}),
        data_access_submission_id
    LIMIT {{ sample_size }}
)

SELECT
    data_access_submission_id,
    rejection_reason,
    AI_CLASSIFY(
        rejection_reason,
        {{ data_access_rejection_categories() }},
        {
            'task_description': 'Classify explicitly stated rejection reasons. DUC means Data Use Certification; IDU means Intended Data Use. Select all independent problems, using the most specific label per problem. Distinguish inadequate explanations from prohibited research. Exclude boilerplate and hypothetical requirements. Use Other for unmapped or unclear reasons.',
            'output_mode': 'multi'
        },
        TRUE
    ) AS classification
FROM sampled_rejections
