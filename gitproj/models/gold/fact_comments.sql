{{config(materialized='incremental', unique_key='comment_id', incremental_strategy='merge', on_schema_change='append_new_columns')}}
with fact_comments as (
    select
        c.comment_id,
        i.issue_id,
        c.user_id,
        c.author_association,
        c.body,
        c.created_at,
        c.updated_at,
        TO_NUMBER(TO_CHAR(c.created_at, 'YYYYMMDD')) AS created_date_key,
        TO_NUMBER(TO_CHAR(c.updated_at, 'YYYYMMDD')) AS updated_date_key,
        c.ingestion_timestamp
    from {{ ref('silver_comments')}} c
    left join {{ ref('silver_issues')}} i using (issue_url)
)
select * from fact_comments
{% if is_incremental() %}
    where ingestion_timestamp > (select coalesce(max(ingestion_timestamp), '1900-01-01'::timestamp) from {{ this }})
{% endif %}
