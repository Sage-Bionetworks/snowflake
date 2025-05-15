USE SCHEMA {{ database_name }}.synapse_event; --noqa: JJ01,PRS,TMP

-- 1) Create a dummy events table
CREATE OR REPLACE TABLE dummy_event (
  event_id          STRING        NOT NULL,
  user_id           STRING        NOT NULL,
  event_type        STRING        NOT NULL,
  event_timestamp   TIMESTAMP_NTZ NOT NULL,
  metadata          VARIANT       DEFAULT '{}'::VARIANT,
  PRIMARY KEY (event_id)
);

-- 2) Insert some sample rows
INSERT INTO dummy_event (
  event_id, user_id, event_type, event_timestamp, metadata
) VALUES
  ('evt_0001', 'user_123', 'UPLOAD',   '2025-05-01 10:15:00', PARSE_JSON('{"file":"data.csv","size":2048}')),
  ('evt_0002', 'user_456', 'DOWNLOAD', '2025-05-02 14:30:00', PARSE_JSON('{"file":"report.pdf","size":512000}')),
  ('evt_0003', 'user_123', 'VIEW',     '2025-05-03 09:05:00', PARSE_JSON('{"page":"dashboard"}')),
  ('evt_0004', 'user_789', 'LOGIN',    '2025-05-04 08:00:00', PARSE_JSON('{"ip":"192.0.2.1"}')),
  ('evt_0005', 'user_456', 'LOGOUT',   '2025-05-04 17:45:00', PARSE_JSON('{"session_duration":3450}'));
