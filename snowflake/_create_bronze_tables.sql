USE ROLE ACCOUNTADMIN;
USE DATABASE GITPROJ;
USE SCHEMA BRONZE;


CREATE OR REPLACE TABLE BRONZE.comments (
    raw_json VARIANT,
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    source_file VARCHAR
);


CREATE OR REPLACE TABLE BRONZE.issues(
    raw_json VARIANT,
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    source_file VARCHAR
    
);

CREATE OR REPLACE TABLE BRONZE.labels(
    raw_json VARIANT,
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    source_file VARCHAR
    
);

CREATE OR REPLACE TABLE BRONZE.milestones(
    raw_json VARIANT,
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    source_file VARCHAR
    
);
