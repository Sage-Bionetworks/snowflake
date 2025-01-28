USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Add table comment
COMMENT ON TABLE verificationsubmissionsnapshots IS 'This table contain snapshots of submissions of user verification data by ACT. Snapshots are taken when a submission is created or updated. Note: Snapshots are also taken periodically and independently of the changes. The snapshot_timestamp records when the snapshot was taken.';

-- Add column comments
COMMENT ON COLUMN verificationsubmissionsnapshots.change_timestamp IS 'The time when the change (created/updated) on a submission is pushed to the queue for snapshotting.';
COMMENT ON COLUMN verificationsubmissionsnapshots.change_type IS 'The type of change that occurred on the submission, e.g., CREATE, UPDATE.';
COMMENT ON COLUMN verificationsubmissionsnapshots.snapshot_timestamp IS 'The time when the snapshot was taken (It is usually after the change happened).';
COMMENT ON COLUMN verificationsubmissionsnapshots.id IS 'The unique identifier of the submission.';
COMMENT ON COLUMN verificationsubmissionsnapshots.created_on IS 'The creation time of the submission.';
COMMENT ON COLUMN verificationsubmissionsnapshots.created_by IS 'The unique identifier of the user who, created the submission';
COMMENT ON COLUMN verificationsubmissionsnapshots.state_history IS 'The sequence of submission states (SUBMITTED, REJECTED, APPROVED) for the submission.';
COMMENT ON COLUMN verificationsubmissionsnapshots.snapshot_date IS 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';
