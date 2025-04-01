-- Rename certifiedquiz_latest_dynamic to certifiedquiz_latest
USE SCHEMA {{database_name}}.synapse;
ALTER TABLE certifiedquiz_latest_dynamic RENAME TO certifiedquiz_latest;