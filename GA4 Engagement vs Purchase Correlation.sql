WITH raw_events AS (
SELECT
user_pseudo_id,
event_name,
(SELECT value.int_value FROM UNNEST(event_params)
WHERE key = "ga_session_id") AS session_id,
(SELECT value.int_value FROM UNNEST(event_params)
WHERE key = "engagement_time_msec") AS engagement_time_msec,
(SELECT value.string_value FROM UNNEST(event_params)
WHERE key = "session_engaged") AS session_engaged
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20200101' AND '20201231'
),

session_date AS (
SELECT
user_pseudo_id,
session_id,
MAX(CAST(session_engaged AS INT64)) AS is_engaged,
SUM(COALESCE(engagement_time_msec, 0)) AS total_engagement_time_msec,
MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS made_purchase
FROM raw_events
GROUP BY 1,2
)

SELECT 
CORR(is_engaged, made_purchase) AS corr_engaged_purchase,
CORR(total_engagement_time_msec, made_purchase) AS corr_time_purchase
FROM session_date