with comment_metrics as (
    select 
        issue_id,
        COUNT(*) as comment_counts,
        COUNT(DISTINCT user_id) as unique_commenters,
        MIN(created_at) as first_comment_at,
        MAX(created_at) as last_comment_at
    from {{ref('fact_comments')}}
    GROUP BY issue_id
),
---74 NULLS para issue_id


label_metrics as(
    select
        i.issue_id,
        COUNT(*) as label_count,
        LISTAGG(l."name", ', ') WITHIN GROUP (ORDER BY l."name") as labels
    from {{ref('dim_issues_labels')}} i
    INNER JOIN  {{ref('dim_labels')}} l 
        ON i.label_id = l.label_id
    GROUP BY i.issue_id

)

select 
    i.issue_id,
    i.title,
    i."state",
    i.locked,

    i.created_at,
    i.updated_at,
    i.closed_at,

    COALESCE(cm.comment_counts, 0) AS comment_count,
    COALESCE(cm.unique_commenters, 0) AS unique_commenters,
    cm.first_comment_at,
    cm.last_comment_at,

    COALESCE(lm.label_count, 0) AS label_count,
    lm.labels,

    -- Time to first iteraction
    CASE
        WHEN cm.first_comment_at IS NOT NULL
        THEN DATEDIFF(
            'second',
            i.created_at,
            cm.first_comment_at
        ) / 3600.0
    END AS hours_to_first_comment

    FROM {{ref('fact_issues')}} i
    LEFT JOIN comment_metrics cm ON i.issue_id = cm.issue_id
    LEFT JOIN label_metrics lm ON i.issue_id = lm.issue_id



