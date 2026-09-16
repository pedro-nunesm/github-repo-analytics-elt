with dim_users as (
    select
        user_id,
        username,
        "type",
        site_admin,
        source_file,
        ingestion_timestamp
    from {{ ref('silver_users')}}
)
select * from dim_users