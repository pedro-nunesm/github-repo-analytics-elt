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
        TO_NUMBER(TO_CHAR(created_at, 'YYYYMMDD')) AS created_date_key,
        TO_NUMBER(TO_CHAR(updated_at, 'YYYYMMDD')) AS updated_date_key,
        CASE
            WHEN closed_at IS NOT NULL
                THEN TO_NUMBER(TO_CHAR(closed_at, 'YYYYMMDD'))
        END AS closed_date_key,
        CASE
            WHEN duo_on IS NOT NULL
                THEN TO_NUMBER(TO_CHAR(duo_on, 'YYYYMMDD'))
        END AS duo_date_key,
        source_file,
        ingestion_timestamp
    from {{ ref('silver_milestones')}}
)
select * from dim_milestones