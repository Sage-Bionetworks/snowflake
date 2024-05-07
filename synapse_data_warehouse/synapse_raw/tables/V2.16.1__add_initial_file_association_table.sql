USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
USE WAREHOUSE COMPUTE_MEDIUM;
CREATE TABLE IF NOT EXISTS filehandle_association (
    associateid int,
    associatetype string,
    filehandleid INT,
    instance string,
    stack string,
    timestamp timestamp
)
CLUSTER BY (instance);

copy into
    filehandle_association
from (
    select
        $1:associateid as associateid,
        $1:associatetype as associatetype,
        $1:filehandleid as filehandleid,
        $1:instance as instance,
        $1:stack as stack,
        $1:timestamp as timestamp
    from
        @synapse_filehandles_stage --noqa: TMP
);
