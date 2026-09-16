with silver_milestones as(
    select 
        raw_json:id::varchar as milestone_id,
        raw_json:"number"::integer as "number",
        raw_json:title::varchar as title,
        raw_json:"description"::varchar as "description",
        raw_json:"state"::varchar as "state",
        raw_json:duo_on::timestamp_tz as duo_on,
        raw_json:created_at::timestamp_tz as created_at,
        raw_json:updated_at::timestamp_tz as updated_at,
        raw_json:closed_at::timestamp_tz as closed_at,
        source_file,
        ingestion_timestamp
    
    from {{ source('bronze', 'milestones')}}

)
select * from silver_milestones