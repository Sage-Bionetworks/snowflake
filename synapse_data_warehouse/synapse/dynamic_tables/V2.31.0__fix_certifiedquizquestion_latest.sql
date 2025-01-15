USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

WITH latest_change_type AS (
    SELECT
        response_id,
        MAX(change_type) AS change_type
    FROM
        {{database_name}}.synapse_raw.certifiedquizquestionsnapshots
    GROUP BY
        response_id
),
relevant_snapshots AS (
    SELECT
        s.*
    FROM
        {{database_name}}.synapse_raw.certifiedquizquestionsnapshots s
    JOIN
        latest_change_type l
    ON
        s.response_id = l.response_id
    WHERE
        s.change_type = l.change_type
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY s.response_id, s.question_index
        ORDER BY
            CASE WHEN s.change_type = 'CREATE' THEN s.change_timestamp END ASC NULLS LAST,
            CASE WHEN s.change_type = 'UPDATE' THEN s.snapshot_timestamp END DESC NULLS LAST
    ) = 1
)
SELECT *
FROM relevant_snapshots;
