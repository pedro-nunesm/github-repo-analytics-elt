from datetime import datetime
from airflow import DAG
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.providers.standard.operators.bash import BashOperator

DBT = "/opt/airflow/dbt_venv/bin/dbt"
DBT_PROJECT = "/opt/airflow/dbt/gitproj"


COPY_RAW = [
    "USE WAREHOUSE GITPROJ_WH",
    "USE DATABASE GITPROJ",
    "USE SCHEMA BRONZE",
    "COPY INTO GITPROJ.BRONZE.comments (raw_json, source_file) FROM (SELECT $1, METADATA$FILENAME FROM @GITPROJ_BRONZE_STAGE/comments) FILE_FORMAT = JSON_FMT ON_ERROR='CONTINUE'",
    "COPY INTO GITPROJ.BRONZE.issues (raw_json, source_file) FROM (SELECT $1, METADATA$FILENAME FROM @GITPROJ_BRONZE_STAGE/issues) FILE_FORMAT = JSON_FMT ON_ERROR='CONTINUE'",
    "COPY INTO GITPROJ.BRONZE.milestones (raw_json, source_file) FROM (SELECT $1, METADATA$FILENAME FROM @GITPROJ_BRONZE_STAGE/milestones) FILE_FORMAT = JSON_FMT ON_ERROR='CONTINUE'",
    "COPY INTO GITPROJ.BRONZE.labels (raw_json, source_file) FROM (SELECT $1, METADATA$FILENAME FROM @GITPROJ_BRONZE_STAGE/labels) FILE_FORMAT = JSON_FMT ON_ERROR='CONTINUE'",
]

with DAG(
    dag_id="gitproj_batch",
    start_date=datetime(2026, 9, 16),
    schedule="@daily",
    catchup=False,
    tags=["gitproj", "batch", "dbt"],
    doc_md=__doc__,

) as dag:
    reload_raw = SQLExecuteQueryOperator(
        task_id="reload_raw",
        conn_id="snowflake_default",
        sql=COPY_RAW,
        split_statements=True,
        autocommit=True,)

    dbt_build_code = BashOperator(
        task_id="dbt_build_code",
        bash_command=f"{DBT} build --exclude tag:ai --project-dir {DBT_PROJECT} --profiles-dir {DBT_PROJECT}",)

    enrich_reviews = BashOperator(
        task_id="enrich_issues",
        bash_command=f"python /opt/airflow/ai/enrich_issues.py",)


    dbt_build_ai = BashOperator(
        task_id="dbt_build_ai",
        bash_command=f"{DBT} build --select tag:ai --project-dir {DBT_PROJECT} --profiles-dir {DBT_PROJECT}",)


    reload_raw >> dbt_build_code >> enrich_reviews >> dbt_build_ai
