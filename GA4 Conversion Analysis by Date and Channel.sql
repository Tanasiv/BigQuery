WITH sessions AS (
SELECT
DATE(TIMESTAMP_MICROS(event_timestamp)) AS event_date,
user_pseudo_id,
(SELECT value.int_value FROM UNNEST(event_params)
WHERE key = "ga_session_id") AS session_id,
traffic_source.source AS source,
traffic_source.medium AS medium,
traffic_source.name AS campaign,
event_name
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE 
event_name = 'session_start'
),

events AS (
SELECT
DATE(TIMESTAMP_MICROS(event_timestamp)) AS event_date,
user_pseudo_id,
(SELECT value.int_value FROM UNNEST(event_params)
WHERE key = "ga_session_id") AS session_id,
event_name
FROM
`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE
event_name IN ('add_to_cart', 'begin_checkout', 'purchase')
),

session_events AS (
SELECT 
s.event_date,
s.user_pseudo_id,
s.session_id,
s.source,
s.medium,
s.campaign,
MAX(CASE WHEN e.event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS has_add_to_cart,
MAX(CASE WHEN e.event_name = 'begin_checkout' THEN 1 ELSE 0 END) AS has_begin_checkout,
MAX(CASE WHEN e.event_name = 'purchase'  THEN 1 ELSE 0 END) AS has_purchase,
FROM sessions AS s
LEFT JOIN events AS e
ON s.user_pseudo_id = e.user_pseudo_id
AND s.session_id = e.session_id
AND s.event_date = e.event_date
GROUP BY 1,2,3,4,5,6
)

SELECT 
event_date,
source,
medium,
campaign,
COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS user_sessions_count,
SAFE_DIVIDE(SUM(has_add_to_cart), COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING)))) AS visit_to_cart,
SAFE_DIVIDE(SUM(has_begin_checkout), COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING)))) AS visit_to_checkout,
SAFE_DIVIDE(SUM(has_purchase), COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING)))) AS visit_to_purchase
FROM session_events
GROUP BY 1,2,3,4
ORDER BY 1 DESC, 2,3,4