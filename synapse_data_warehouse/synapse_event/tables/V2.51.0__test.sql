USE SCHEMA {{ database_name }}.synapse_event; --noqa: JJ01,PRS,TMP

-- 1) Create a really simple events table
CREATE OR REPLACE TABLE dummy_event (
  event_id          VARCHAR     NOT NULL,
  user_id           VARCHAR,
  event_type        VARCHAR,
  event_timestamp   TIMESTAMP_NTZ
);

-- 2) Insert a few dummy rows (no VARIANT or JSON needed)
INSERT INTO dummy_event (
  event_id, user_id, event_type, event_timestamp
) VALUES
  ('evt_001', 'user_123', 'UPLOAD',   '2025-05-01 10:00:00'),
  ('evt_002', 'user_456', 'DOWNLOAD', '2025-05-02 11:30:00'),
  ('evt_003', 'user_789', 'LOGIN',    '2025-05-03 09:00:00');
