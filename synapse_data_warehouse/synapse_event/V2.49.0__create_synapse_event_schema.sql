USE DATABASE {{ database_name }}; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE SCHEMA SYNAPSE_EVENT
    COMMENT = 'Event data is derived from raw data by retaining only the most recent snapshot for each distinct event. The identifier of an event is determined by a subset of columns which uniquely identifies the occurrence or instance of an event.';
