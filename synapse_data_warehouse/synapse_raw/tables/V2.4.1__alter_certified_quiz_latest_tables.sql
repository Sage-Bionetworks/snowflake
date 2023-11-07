USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP
CREATE OR REPLACE TABLE certifiedquiz_latest (
    change_type STRING,
    change_timestamp TIMESTAMP,
    snapshot_timestamp TIMESTAMP,
    response_id NUMBER,
    user_id NUMBER,
    passed BOOLEAN,
    passed_on TIMESTAMP,
    stack STRING,
    instance STRING,
    snapshot_date DATE
)

CREATE OR REPLACE TABLE certifiedquizquestionsnapshots (
    change_type STRING,
    change_timestamp TIMESTAMP,
    change_user_id NUMBER,
    snapshot_timestamp TIMESTAMP,
    response_id NUMBER,
    question_index NUMBER,
    is_correct BOOLEAN,
    stack STRING,
    instance STRING,
    snapshot_date DATE
);
