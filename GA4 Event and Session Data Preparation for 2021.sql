SELECT 
  country,
  source,
  medium,
  campaign,
  device_category,
  COUNT(DISTINCT CONCAT(user_pseudo_id, CAST(session_id AS STRING))) AS user_sessions_count,
  COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart' THEN CONCAT(user_pseudo_id, CAST(session_id AS STRING)) END) AS added_to_cart_count,
  COUNT(DISTINCT CASE WHEN event_name = 'begin_checkout' THEN CONCAT(user_pseudo_id, CAST(session_id AS STRING)) END) AS began_checkout_count,
  COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN CONCAT(user_pseudo_id, CAST(session_id AS STRING)) END) AS purchased_count
FROM (
  SELECT 
    user_pseudo_id,
    CAST((SELECT value.int_value FROM UNNEST(event_params) WHERE key = "ga_session_id") AS INT64) AS session_id,
    event_name,
    geo.country AS country,
    traffic_source.source AS source,
    traffic_source.medium AS medium,
    traffic_source.name AS campaign,
    device.category AS device_category  
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE 
    _TABLE_SUFFIX BETWEEN '20210101' AND '20211231'
    AND event_name IN (
      "session_start",
      "add_to_cart",
      "begin_checkout",
      "purchase"
    )
)
GROUP BY 1,2,3,4,5
