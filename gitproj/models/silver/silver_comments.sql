select 
    raw_json:id::varchar as comment_id,
    raw_json:user.id::varchar as user_id,
    raw_json:author_association::varchar as author_association,
    raw_json:body::varchar as body,
    raw_json:created_at::timestamp_tz as created_at,
    raw_json:updated_at::timestamp_tz as updated_at,
    source_file,
    ingestion_timestamp

from {{ source('bronze', 'comments')}}