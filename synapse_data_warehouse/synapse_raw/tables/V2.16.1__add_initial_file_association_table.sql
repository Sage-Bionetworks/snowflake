USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
USE WAREHOUSE COMPUTE_MEDIUM;
CREATE TABLE IF NOT EXISTS filehandleassociationsnapshots (
    associateid INT COMMENT 'The unique identifier of the Synapse object that wraps the file.',
    associatetype STRING COMMENT 'The type of the Synapse object that wraps the file.',
    filehandleid INT COMMENT 'The unique identifier of the file handle.',
    instance STRING COMMENT 'The version of the stack that processed the file association.',
    stack STRING COMMENT 'The stack (prod, dev) on which the file handle association processed.',
    timestamp TIMESTAMP COMMENT 'The time when the association data was collected.'
)
COMMENT='The table contains file handle association records that are weekly scanned. A FileHandleAssociation record is a FileHandle (identified by its id) along with a Synapse object (identified by its id and type).'
CLUSTER BY (instance);

copy into
    filehandleassociationsnapshots
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
