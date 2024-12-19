USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Add table comment
COMMENT ON TABLE certifiedquiz IS 'This table contain records of the certification quiz taken by a Synapse user.';

-- Add column comments
COMMENT ON COLUMN certifiedquiz.response_id IS 'The unique identifier of a response wherein a user submitted a set of answers while participating in the quiz.';
COMMENT ON COLUMN certifiedquiz.user_id IS 'The unique identifier of the user who took the quiz.';
COMMENT ON COLUMN certifiedquiz.passed IS 'If true, the user passed the quiz.';
COMMENT ON COLUMN certifiedquiz.passed_on IS 'The date on which the user took the quiz, regardless of whether user passed or failed the test.';
COMMENT ON COLUMN certifiedquiz.stack IS 'The stack (prod, dev) on which the quiz record was processed.';
COMMENT ON COLUMN certifiedquiz.instance IS 'The version of the stack that processed the quiz record.';
COMMENT ON COLUMN certifiedquiz.record_date IS 'The data is partitioned for fast and cost effective queries. The timestamp field is converted into a date and stored in the record_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';
