USE ROLE ACCOUNTADMIN;
USE DATABASE GITPROJ;
USE SCHEMA BRONZE;
USE WAREHOUSE GITPROJ_WH;


-- COMMENTS
COPY INTO BRONZE.comments (
    raw_json,
    source_file
)
FROM (
    SELECT
        $1,
        METADATA$FILENAME
    FROM @GITPROJ_BRONZE_STAGE/comments
)
FILE_FORMAT = JSON_FMT;


--ISSUES
COPY INTO BRONZE.issues (
    raw_json,
    source_file
)
FROM (
    SELECT
        $1,
        METADATA$FILENAME
    FROM @GITPROJ_BRONZE_STAGE/issues
)
FILE_FORMAT = JSON_FMT;

-- LABELS
COPY INTO BRONZE.labels (
    raw_json,
    source_file
)
FROM (
    SELECT
        $1,
        METADATA$FILENAME
    FROM @GITPROJ_BRONZE_STAGE/labels
)
FILE_FORMAT = JSON_FMT;

-- MILESTONES
COPY INTO BRONZE.milestones (
    raw_json,
    source_file
)
FROM (
    SELECT
        $1,
        METADATA$FILENAME
    FROM @GITPROJ_BRONZE_STAGE/milestones
)
FILE_FORMAT = JSON_FMT;
