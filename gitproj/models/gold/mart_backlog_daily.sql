WITH repository_period AS (
    SELECT
        MIN(created_at::DATE) AS start_date,

        GREATEST(
            MAX(created_at::DATE),
            MAX(updated_at::DATE),
            COALESCE(MAX(closed_at::DATE), MAX(updated_at::DATE))
        ) AS end_date

    FROM {{ ref('fact_issues') }}

),



dates as (
    select
        d.date_key,
        d.full_date
    from {{ref('dim_dates')}} as d
    INNER JOIN repository_period as rp ON d.full_date BETWEEN rp.start_date AND rp.end_date

),

created as (
    select
        created_date_key as date_key,
        COUNT(*) as issues_created
    from {{ref('fact_issues')}}
    GROUP BY created_date_key

),

closed as (
    select
        closed_date_key as date_key,
        COUNT(*) as issues_closed
    from {{ref('fact_issues')}}
    WHERE closed_date_key IS NOT NULL
    GROUP BY closed_date_key
),

daily as (
    select
        d.date_key,
        d.full_date,
        COALESCE(c.issues_created, 0) as issues_created,
        COALESCE(cl.issues_closed, 0) as issues_closed
    from dates as d
    LEFT JOIN created c ON d.date_key = c.date_key
    LEFT JOIN closed cl ON d.date_key = cl.date_key
    
    ),

final as (
    select
        date_key,
        full_date,
        issues_created,
        issues_closed,
        issues_created - issues_closed as net_change,
        SUM(issues_created) OVER (ORDER BY full_date) as cumulative_created,        
        SUM(issues_closed) OVER (ORDER BY full_date) as cumulative_closed        
    from daily

)

select
    date_key,
    full_date,
    issues_created,
    issues_closed,
    net_change,
    cumulative_created,
    cumulative_closed,
    cumulative_created - cumulative_closed as backlog
from final

