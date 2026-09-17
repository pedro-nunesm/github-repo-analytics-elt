{{config(tags=['ai'])}}
select
    issue_id,
    title,
    body,
    severity,
    confidence,
    reasoning,
    evidence,
    model_name,
    enriched_at 

from {{source('ai', 'issues_enrich')}}