with users_comments as ( 
    select 
        raw_json:user.id::varchar as user_id,
        raw_json:user.login::varchar as username,
        raw_json:user.type::varchar as "type",
        raw_json:user.site_admin::boolean as site_admin,
        source_file,
        ingestion_timestamp
    from {{ source('bronze', 'comments')}}
    ),

users_issues as ( 
    select 
        raw_json:user.id::varchar as user_id,
        raw_json:user.login::varchar as username,
        raw_json:user.type::varchar as "type",
        raw_json:user.site_admin::boolean as site_admin,
        source_file,
        ingestion_timestamp
    from {{ source('bronze', 'issues')}}
    ),

all_users as (
    select * from users_comments
    UNION ALL
    select * from users_issues
),

deduplicated_users as (
    select * from all_users
    qualify row_number() over(partition by user_id order by ingestion_timestamp desc) = 1

)

select * from deduplicated_users


