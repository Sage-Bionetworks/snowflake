USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

COMMENT ON TABLE CERTIFIEDQUIZ_LATEST IS 'This table contains the most recent snapshot of submissions of user verification data by ACT. Snapshots are taken when a submission is created or updated. Note: Snapshots are also taken periodically and independently of the changes. The snapshot_timestamp records when the snapshot was taken.';
COMMENT ON COLUMN CERTIFIEDQUIZ_LATEST.change_type IS 'The change type is always as CREATE since each instance of a user submitting a quiz results in a new submission of the quiz.';
COMMENT ON COLUMN CERTIFIEDQUIZ_LATEST.change_timestamp IS 'The time when the user submitted the quiz.';
COMMENT ON COLUMN CERTIFIEDQUIZ_LATEST.snapshot_timestamp IS 'The time when the snapshot was taken (It is usually after the change happened).';
COMMENT ON COLUMN CERTIFIEDQUIZ_LATEST.response_id IS 'The unique identifier of a response wherein a user submitted a set of answers while participating in the quiz.';
COMMENT ON COLUMN CERTIFIEDQUIZ_LATEST.user_id IS 'The unique identifier of the user who submitted the quiz.';
COMMENT ON COLUMN CERTIFIEDQUIZ_LATEST.passed IS 'If true, the user passed the quiz.';
COMMENT ON COLUMN CERTIFIEDQUIZ_LATEST.passed_on IS 'The date on which the user submit the quiz, regardless of whether user passed or failed the test.';
COMMENT ON COLUMN CERTIFIEDQUIZ_LATEST.stack IS 'The stack (prod, dev) on which the quiz record was processed.';
COMMENT ON COLUMN CERTIFIEDQUIZ_LATEST.instance IS 'The version of the stack that processed the quiz record.';
COMMENT ON COLUMN CERTIFIEDQUIZ_LATEST.revoked IS 'If true, the record was revoked by an ACT member.';
COMMENT ON COLUMN CERTIFIEDQUIZ_LATEST.revoked_on IS 'The date/time when the record was revoked, can be null if the record was never revoked.';
COMMENT ON COLUMN CERTIFIEDQUIZ_LATEST.certified IS 'If true the user is certified through this record, can be true iif passed is true and revoked is false.';
COMMENT ON COLUMN CERTIFIEDQUIZ_LATEST.snapshot_date IS 'The snapshot_timestamp field is converted into a date and stored in the snapshot_date field.';
