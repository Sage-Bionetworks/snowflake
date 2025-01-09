-- Configure environment
USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP,CP02

-- Add the table and column comments
ALTER DYNAMIC TABLE CERTIFIEDQUIZQUESTION_LATEST SET COMMENT = 'This table contains the latest snapshots of the questions of the certification quiz. With each entry representing a question answered by the user during the quiz.';

ALTER DYNAMIC TABLE CERTIFIEDQUIZQUESTION_LATEST ALTER COLUMN change_type COMMENT 'The change type is always as CREATE since each instance of a user submitting a quiz results in a new submission of the quiz.';
ALTER DYNAMIC TABLE CERTIFIEDQUIZQUESTION_LATEST ALTER COLUMN change_timestamp COMMENT 'The time when the user submitted the quiz.';
ALTER DYNAMIC TABLE CERTIFIEDQUIZQUESTION_LATEST ALTER COLUMN change_user_id COMMENT 'The unique identifier of the user that submitted the quiz.';
ALTER DYNAMIC TABLE CERTIFIEDQUIZQUESTION_LATEST ALTER COLUMN response_id COMMENT 'The unique identifier of a response wherein a user submitted a set of answers while participating in the quiz.';
ALTER DYNAMIC TABLE CERTIFIEDQUIZQUESTION_LATEST ALTER COLUMN snapshot_timestamp COMMENT 'The time when the snapshot was taken (It is usually after the change happened).';
ALTER DYNAMIC TABLE CERTIFIEDQUIZQUESTION_LATEST ALTER COLUMN question_index COMMENT 'The position of the question within the quiz.';
ALTER DYNAMIC TABLE CERTIFIEDQUIZQUESTION_LATEST ALTER COLUMN is_correct COMMENT 'If true, the answer to the question was correct.';
ALTER DYNAMIC TABLE CERTIFIEDQUIZQUESTION_LATEST ALTER COLUMN stack COMMENT 'The stack (prod, dev) on which the quiz question record was processed.';
ALTER DYNAMIC TABLE CERTIFIEDQUIZQUESTION_LATEST ALTER COLUMN instance COMMENT 'The version of the stack that processed the quiz question record.';
ALTER DYNAMIC TABLE CERTIFIEDQUIZQUESTION_LATEST ALTER COLUMN snapshot_date COMMENT 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';
