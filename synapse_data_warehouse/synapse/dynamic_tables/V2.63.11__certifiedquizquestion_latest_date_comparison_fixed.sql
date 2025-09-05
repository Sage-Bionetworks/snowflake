USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

create or replace dynamic table CERTIFIEDQUIZQUESTION_LATEST(
	CHANGE_TYPE COMMENT 'The change type is always as CREATE since each instance of a user submitting a quiz results in a new submission of the quiz.',
	CHANGE_TIMESTAMP COMMENT 'The time when the user submitted the quiz.',
	CHANGE_USER_ID COMMENT 'The unique identifier of the user that submitted the quiz.',
	SNAPSHOT_TIMESTAMP COMMENT 'The time when the snapshot was taken (It is usually after the change happened).',
	RESPONSE_ID COMMENT 'The unique identifier of a response wherein a user submitted a set of answers while participating in the quiz.',
	QUESTION_INDEX COMMENT 'The position of the question within the quiz.',
	IS_CORRECT COMMENT 'If true, the answer to the question was correct.',
	STACK COMMENT 'The stack (prod, dev) on which the quiz question record was processed.',
	INSTANCE COMMENT 'The version of the stack that processed the quiz question record.',
	SNAPSHOT_DATE COMMENT 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.'
) target_lag = '1 day' refresh_mode = AUTO initialize = ON_CREATE warehouse = COMPUTE_XSMALL
 COMMENT='This table contains the latest snapshots of the questions of the certification quiz taken within the last 14 days. With each entry representing a question answered by the user during the quiz.'
 as
        WITH latest_unique_rows AS (
            SELECT
                *
            FROM
                {{database_name}}.synapse_raw.certifiedquizquestionsnapshots --noqa: TMP
            WHERE
                SNAPSHOT_DATE >= CURRENT_DATE - INTERVAL '14 DAYS'
            QUALIFY ROW_NUMBER() OVER (
                    PARTITION BY response_id, question_index
                    ORDER BY change_timestamp DESC, snapshot_timestamp DESC
                ) = 1
        )
        SELECT
            *
        FROM
            latest_unique_rows
        ORDER BY
            latest_unique_rows.response_id ASC;