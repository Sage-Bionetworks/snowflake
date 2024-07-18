-- Create target table for download records from Dec 2018 - Dec 2021
USE ROLE AD;
USE WAREHOUSE COMPUTE_XSMALL;
USE DATABASE SAGE;
USE SCHEMA AD;

CREATE OR REPLACE TABLE PRE_SNOWFLAKE_DOWNLOAD_RECORDS (
    INEXPLICABLE_FILE_COLUMN INTEGER,
    USER_ID STRING,
    ID STRING,
    RECORD_DATE DATE,
    RECORD_TIMESTAMP STRING,
    NODE_TYPE STRING,
    FILE_NAME STRING,
    RECORD_TYPE STRING,
    INEXPLICABLE_SECOND_DATE STRING,
    DATE_GROUPING STRING,
    MONTH_YEAR STRING
);

-- Create file format object
CREATE OR REPLACE FILE FORMAT CSVFORMAT
TYPE = 'CSV'
FIELD_DELIMITER = ','
SKIP_HEADER = 1
//some file names enclosed by double quotes
FIELD_OPTIONALLY_ENCLOSED_BY = '"';

-- Create a stage
CREATE OR REPLACE STAGE TEST_CSV_STAGE
    FILE_FORMAT = CSVFORMAT;

-- Upload csv file
-- csv file comes from: https://www.synapse.org/#!Synapse:syn53446399
PUT file:///Users/alinden/Desktop/ADKP_download_records_dec2018-dec2021.csv @test_csv_stage AUTO_COMPRESS = TRUE;

-- Load data into the table
COPY INTO PRE_SNOWFLAKE_DOWNLOAD_RECORDS
FROM @test_csv_stage/ADKP_download_records_dec2018-dec2021.csv.gz
FILE_FORMAT = (FORMAT_NAME = CSVFORMAT)
ON_ERROR = 'skip_file';
