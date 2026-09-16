with dim_milestones as (
    select
        milestone_id,
        "number",
        title,
        "description",
        "state",
        duo_on,
        created_at,
        updated_at,
        source_file,
        ingestion_timestamp
    from {{ ref('silver_milestones')}}
)
select * from dim_milestones