with dim_issues_labels as (
    select
        issue_id,
        label_id
    from {{ ref('silver_issues_labels')}}
)
select * from dim_issues_labels