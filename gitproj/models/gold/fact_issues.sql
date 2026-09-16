{{config(materialized='incremental', unique_key='issue_id', incremental_strategy='merge', on_schema_change='append_new_columns')}}
with fact_issues as (
    select
        issue_id,
        issue_number,
        issue_url,
        user_id,
        milestone_id,
        "state",
        title,
        body,
        comments,
        locked,
        created_at,
        updated_at,
        closed_at,
        TO_NUMBER(TO_CHAR(created_at, 'YYYYMMDD')) AS created_date_key,
        TO_NUMBER(TO_CHAR(updated_at, 'YYYYMMDD')) AS updated_date_key,
        CASE
            WHEN closed_at IS NOT NULL
                THEN TO_NUMBER(TO_CHAR(closed_at, 'YYYYMMDD'))
        END AS closed_date_key,
        source_file,
        ingestion_timestamp
        
    from {{ ref('silver_issues')}} 
)
select * from fact_issues
{% if is_incremental() %}
    where ingestion_timestamp > (select coalesce(max(ingestion_timestamp), '1900-01-01'::timestamp) from {{ this }})
{% endif %}
