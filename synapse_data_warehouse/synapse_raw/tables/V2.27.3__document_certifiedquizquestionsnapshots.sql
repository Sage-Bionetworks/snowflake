USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Add table comment
COMMENT ON TABLE certifiedquizquestionsnapshots IS 'This table contain snapshots of the questions of the certification quiz. With each entry representing a question answered by the user during the quiz.';

-- Add column comments
COMMENT ON COLUMN certifiedquizquestionsnapshots.change_type IS 'The change type is always as CREATE since each instance of a user submitting a quiz results in a new submission of the quiz.';
COMMENT ON COLUMN certifiedquizquestionsnapshots.change_timestamp IS 'The time when the user submitted the quiz.';
COMMENT ON COLUMN certifiedquizquestionsnapshots.change_user_id IS 'The unique identifier of the user that submitted the quiz.';
COMMENT ON COLUMN certifiedquizquestionsnapshots.snapshot_timestamp IS 'The time when the snapshot was taken (It is usually after the change happened).';
COMMENT ON COLUMN certifiedquizquestionsnapshots.response_id IS 'The unique identifier of a response wherein a user submitted a set of answers while participating in the quiz.';
COMMENT ON COLUMN certifiedquizquestionsnapshots.question_index IS 'The position of the question within the quiz.';
COMMENT ON COLUMN certifiedquizquestionsnapshots.is_correct IS 'If true, the answer to the question was correct.';
COMMENT ON COLUMN certifiedquizquestionsnapshots.stack IS 'The stack (prod, dev) on which the quiz question record was processed.';
COMMENT ON COLUMN certifiedquizquestionsnapshots.instance IS 'The version of the stack that processed the quiz question record.';
COMMENT ON COLUMN certifiedquizquestionsnapshots.snapshot_date IS 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';
