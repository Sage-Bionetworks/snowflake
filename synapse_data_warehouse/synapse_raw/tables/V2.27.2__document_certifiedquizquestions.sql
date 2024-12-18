USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Add table comment
COMMENT ON TABLE certifiedquizquestions IS 'This table contain records of the questions of the certification quiz. Each record in the table is question answered by the user in the quiz.';

-- Add column comments
COMMENT ON COLUMN certifiedquizquestions.response_id IS 'The unique identifier of a response wherein a user submitted a set of answers while participating in the quiz.';
COMMENT ON COLUMN certifiedquizquestions.question_index IS 'The position of the question within the quiz.';
COMMENT ON COLUMN certifiedquizquestions.is_correct IS 'If true, the answer to the question was correct.';
COMMENT ON COLUMN certifiedquizquestions.stack IS 'The stack (prod, dev) on which the quiz question record was processed.';
COMMENT ON COLUMN certifiedquizquestions.instance IS 'The version of the stack that processed the quiz question record.';
