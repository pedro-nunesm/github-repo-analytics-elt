select 
    raw_json:id::varchar as label_id,
    raw_json:"name"::varchar as "name",
    raw_json:color::varchar as color,
    raw_json:"description"::varchar as "description",
    raw_json:created_at::timestamp_tz as created_at,
    raw_json:"default"::boolean as "deafult",
    source_file,
    ingestion_timestamp

from {{ source('bronze', 'labels')}}