{% set sample_size = var('rejection_sample_size', 10) | int %}
{% set sample_seed = var('rejection_sample_seed', 406) | int %}
{% set sample_order = var('rejection_sample_order', 'random') %}

{% if sample_size < 1 %}
    {{ exceptions.raise_compiler_error('rejection_sample_size must be positive') }}
{% endif %}
{% if sample_order not in ['random', 'recent'] %}
    {{ exceptions.raise_compiler_error('rejection_sample_order must be random or recent') }}
{% endif %}

WITH sampled_rejections AS (
    SELECT
        rejections.data_access_submission_id,
        rejections.rejection_reason
    FROM {{ ref('stg_synapse__data_access_submission_rejection') }} AS rejections
    {% if sample_order == 'recent' %}
        INNER JOIN {{ source('rds', 'data_access_submission_status') }} AS status
            ON rejections.data_access_submission_id = status.submission_id
    {% endif %}
    WHERE NULLIF(TRIM(rejections.rejection_reason), '') IS NOT NULL
    ORDER BY
        {% if sample_order == 'recent' %}
            status.modified_on DESC,
            rejections.data_access_submission_id DESC
        {% else %}
            HASH(rejections.data_access_submission_id, {{ sample_seed }}),
            rejections.data_access_submission_id
        {% endif %}
    LIMIT {{ sample_size }}
)

SELECT
    data_access_submission_id,
    rejection_reason,
    AI_CLASSIFY(
        rejection_reason,
        {{ data_access_rejection_categories() }},
        {{ data_access_rejection_classifier_config() }},
        TRUE
    ) AS classification
FROM sampled_rejections
