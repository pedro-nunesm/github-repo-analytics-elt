with flatten_issues as (
    select
        raw_json:id::varchar issue_id,
        f.value:id::varchar label_id
    from {{ source('bronze', 'issues')}}, 
    lateral flatten(input => raw_json:labels) f

)

select * from flatten_issues