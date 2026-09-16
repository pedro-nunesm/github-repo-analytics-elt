with dates AS (

    {{ dbt_utils.date_spine(
        datepart = "day",
        start_date = "cast('2010-01-01' as date)",
        end_date = "cast('2036-01-01' as date)"
    ) }}

)

SELECT
    TO_NUMBER(TO_CHAR(date_day, 'YYYYMMDD')) AS date_key,

    date_day AS full_date,

    YEAR(date_day) AS year,
    QUARTER(date_day) AS quarter,
    MONTH(date_day) AS month,
    MONTHNAME(date_day) AS month_name,

    WEEKOFYEAR(date_day) AS week_of_year,

    DAY(date_day) AS day,
    DAYOFWEEKISO(date_day) AS day_of_week,
    DAYNAME(date_day) AS day_name,

    DAYOFWEEKISO(date_day) IN (6, 7) AS is_weekend,

    DATE_TRUNC('month', date_day) AS month_start_date,
    LAST_DAY(date_day, 'month') AS month_end_date,

    DATE_TRUNC('quarter', date_day) AS quarter_start_date,
    LAST_DAY(date_day, 'quarter') AS quarter_end_date

FROM dates