with silver_issues as (
    select
        raw_json:id::varchar as issue_id,
        raw_json:"number"::integer as issue_number,
        raw_json:"url"::varchar as issue_url,
        raw_json:user.id::varchar as user_id,
        raw_json:milestone.id::varchar as milestone_id,
        raw_json:"state"::varchar as "state",
        raw_json:title::varchar as title,
        raw_json:body::varchar as body,
        raw_json:comments::integer as comments,
        raw_json:locked::boolean as locked,
        raw_json:created_at::timestamp_tz as created_at,
        raw_json:updated_at::timestamp_tz as updated_at,
        raw_json:closed_at::timestamp_tz as closed_at,
        source_file,
        ingestion_timestamp
    from {{ source('bronze', 'issues')}}
)
select * from silver_issues