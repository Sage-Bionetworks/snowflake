USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Add table comment
COMMENT ON TABLE certifiedquizsnapshots IS 'This table contain snapshots of the certification quiz submitted by a Synapse user. Snapshots are taken when a user submit the quiz. Note: Snapshots are also taken periodically and independently of the changes. The snapshot_timestamp records when the snapshot was taken.';

-- Add column comments
COMMENT ON COLUMN certifiedquizsnapshots.change_type IS 'The change type is always as CREATE since each instance of a user submitting a quiz results in a new submission of the quiz.';
COMMENT ON COLUMN certifiedquizsnapshots.change_timestamp IS 'The latest time when the change message was sent to the queue for snapshotting.';
COMMENT ON COLUMN certifiedquizsnapshots.snapshot_timestamp IS 'The time when the snapshot was taken (It is usually after the change happened).';
COMMENT ON COLUMN certifiedquizsnapshots.response_id IS 'The unique identifier of a response wherein a user submitted a set of answers while participating in the quiz.';
COMMENT ON COLUMN certifiedquizsnapshots.user_id IS 'The unique identifier of the user who submitted the quiz.';
COMMENT ON COLUMN certifiedquizsnapshots.passed IS 'If true, the user passed the quiz.';
COMMENT ON COLUMN certifiedquizsnapshots.passed_on IS 'The date on which the user submit the quiz, regardless of whether user passed or failed the test.';
COMMENT ON COLUMN certifiedquizsnapshots.stack IS 'The stack (prod, dev) on which the quiz record was processed.';
COMMENT ON COLUMN certifiedquizsnapshots.instance IS 'The version of the stack that processed the quiz record.';
COMMENT ON COLUMN certifiedquizsnapshots.revoked IS 'If true, the record was revoked by an ACT member.';
COMMENT ON COLUMN certifiedquizsnapshots.revoked_on IS 'The date/time when the record was revoked, can be null if the record was never revoked.';
COMMENT ON COLUMN certifiedquizsnapshots.certified IS 'If true the user is certified through this record, can be true iif passed is true and revoked is false.';
