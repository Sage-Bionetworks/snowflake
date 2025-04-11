USE SCHEMA {{ database_name }}.SYNAPSE_AGGREGATE; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE TABLE dummy_table (
    id INT,
    name STRING,
    department STRING,
    salary NUMBER(10,2)
);
INSERT INTO dummy_table (id, name, department, salary) VALUES
    (1, 'Alice', 'Engineering', 95000.00),
    (2, 'Bob', 'Marketing', 72000.00),
    (3, 'Charlie', 'Sales', 68000.00),
    (4, 'Diana', 'HR', 62000.00);
