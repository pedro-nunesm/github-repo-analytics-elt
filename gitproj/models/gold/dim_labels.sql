with dim_labels as (
    select
        label_id,
        "name",
        color,
        "description",
        created_at,
        "deafult",
        source_file,
        ingestion_timestamp
    from {{ ref('silver_labels')}}
)
select * from dim_labels