USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Add table comment
COMMENT ON TABLE certifiedquizquestion IS 'This table contain records of the questions of the certification quiz. Each record in the table is question answered by the user in the quiz.';

-- Add column comments
COMMENT ON COLUMN certifiedquizquestion.response_id IS 'The unique identifier of a response wherein a user submitted a set of answers while participating in the quiz.';
COMMENT ON COLUMN certifiedquizquestion.question_index IS 'The position of the question within the quiz.';
COMMENT ON COLUMN certifiedquizquestion.is_correct IS 'If true, the answer to the question was correct.';
COMMENT ON COLUMN certifiedquizquestion.stack IS 'The stack (prod, dev) on which the quiz question record was processed.';
COMMENT ON COLUMN certifiedquizquestion.instance IS 'The version of the stack that processed the quiz question record.';
COMMENT ON COLUMN certifiedquizquestion.record_date IS 'The data is partitioned for fast and cost effective queries. The timestamp field is converted into a date and stored in the record_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';
