USE SCHEMA {{ database_name }}.citations;

-- do stuff
CREATE TABLE synapse_doi_raw (
  RECORD_ID VARCHAR DEFAULT UUID_STRING() NOT NULL UNIQUE COMMENT 'AUTO-GENERATED. Unique UUID4 identifier.',
  CREATED_ON TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP COMMENT 'AUTO-GENERATED. When this record was added to this table.',
  SOURCE_TYPE VARCHAR COMMENT 'Identifies which pipeline or tool generated the data. Possible values: ID_MINER, PUBMED_CRAWLER, DATACITE.',
  TARGET_SYNAPSE_ID VARCHAR COMMENT 'Links the DOI data to a specific Synapse entity.',
  RAW_DATA VARIANT COMMENT 'Stores the complete, original JSON data provided by the source.'
);
COMMENT ON TABLE synapse_doi IS 'This table contains Synapse DOI data. DOI data is collected from three potential sources: ID_MINER, PUBMED_CRAWLER, and DATACITE.

Records are appended for each run of a source\'s associated workflow. The data is intended to be deduplicated before being used in any analyses.';
