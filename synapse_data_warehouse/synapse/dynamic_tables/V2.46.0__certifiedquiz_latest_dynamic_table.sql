USE SCHEMA {{database_name}}.SYNAPSE; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE DYNAMIC TABLE CERTIFIEDQUIZ_LATEST_DYNAMIC
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    COMMENT = 'This table, indexed by USER_ID, contains the latest snapshot of the certification quiz submissions by a Synapse user.'
    (
        CHANGE_TYPE VARCHAR(10) COMMENT 'The type of change to the record e.g., CREATE, UPDATE. CREATE indicates an user submitting a quiz results in a new submission of the quiz while UPDATE indicates a change to the pre-existing user record usually to indicate it being revoked. There are no DELETE changes.',
        CHANGE_TIMESTAMP TIMESTAMP_NTZ(9) COMMENT 'The time when the change happened. For CREATE changes, it is when the user submitted the quiz. For UPDATE changes, it is when the pre-existing user record changed (e.g. got revoked)',
        SNAPSHOT_TIMESTAMP TIMESTAMP_NTZ(9) COMMENT 'The time when the snapshot was taken (It is usually after the change happened).',
        RESPONSE_ID NUMBER(38,0) COMMENT 'The unique identifier of a response wherein a user submitted a set of answers while participating in the quiz.',
        USER_ID NUMBER(38,0) COMMENT 'The unique identifier of the user who submitted the quiz.',
        PASSED BOOLEAN COMMENT 'If true, the user passed the quiz.',
        PASSED_ON TIMESTAMP_NTZ(9) COMMENT 'The date on which the user submit the quiz, regardless of whether user passed or failed the test.',
        STACK VARCHAR(10) COMMENT 'The stack (prod, dev) on which the quiz record was processed.',
        INSTANCE VARCHAR(10) COMMENT 'The version of the stack that processed the quiz record.',
        SNAPSHOT_DATE DATE COMMENT 'The snapshot_timestamp field is converted into a date and stored in the snapshot_date field.',
        REVOKED BOOLEAN COMMENT 'If true, the record was revoked by an ACT member.',
        REVOKED_ON TIMESTAMP_NTZ(9) COMMENT 'The date/time when the record was revoked, can be null if the record was never revoked.',
        CERTIFIED BOOLEAN COMMENT 'If true the user is certified through this record, can be true if passed is true and revoked is false.'
    )
    AS
        WITH latest_unique_rows AS (
            SELECT
                CHANGE_TYPE,
                CHANGE_TIMESTAMP,
                SNAPSHOT_TIMESTAMP,
                RESPONSE_ID,
                USER_ID,
                PASSED,
                PASSED_ON,
                STACK,
                INSTANCE,
                SNAPSHOT_DATE,
                REVOKED,
                REVOKED_ON,
                CERTIFIED
            FROM
                {{database_name}}.SYNAPSE_RAW.CERTIFIEDQUIZSNAPSHOTS --noqa: TMP
            WHERE
                SNAPSHOT_TIMESTAMP >= CURRENT_TIMESTAMP - INTERVAL '14 DAYS'
            QUALIFY ROW_NUMBER() OVER (
                    PARTITION BY USER_ID
                    ORDER BY RESPONSE_ID DESC, CHANGE_TIMESTAMP DESC, SNAPSHOT_TIMESTAMP DESC
                ) = 1
        )
        SELECT
            *
        FROM
            latest_unique_rows;
