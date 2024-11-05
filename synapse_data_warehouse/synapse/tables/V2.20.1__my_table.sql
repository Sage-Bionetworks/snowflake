USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

-- Create the dummy table with example columns
CREATE TABLE IF NOT EXISTS my_table (
    id INT,
    name STRING,
    created_at TIMESTAMP,
    value FLOAT
);

-- Insert arbitrary rows into the dummy table
INSERT INTO my_table (id, name, created_at, value) VALUES 
    (1, 'Alpha', CURRENT_TIMESTAMP, 10.5),
    (2, 'Beta', CURRENT_TIMESTAMP, 20.0),
    (3, 'Gamma', CURRENT_TIMESTAMP, 30.75),
    (4, 'Delta', CURRENT_TIMESTAMP, 40.1),
    (5, 'Epsilon', CURRENT_TIMESTAMP, 50.9);