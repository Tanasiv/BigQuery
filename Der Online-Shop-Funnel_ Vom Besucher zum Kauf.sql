WITH sessions_info AS (
SELECT
  user_pseudo_id,
  (SELECT value.int_value FROM e.event_params WHERE KEY = 'ga_session_id') AS session_id,
  user_pseudo_id || CAST((SELECT value.int_value FROM e.event_params WHERE KEY = 'ga_session_id') AS STRING) AS user_session_id,
  REGEXP_EXTRACT((SELECT value.string_value FROM e.event_params WHERE KEY = 'page_location'), r'(?:https:\/\/)?[^\/]+\/(.*)') AS landing_page_location,
  geo.country,
  device.category AS device_category,
  device.language AS device_language,
  device.operating_system,
  traffic_source.source,
  traffic_source.medium,
  traffic_source.name AS campaign
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` e
WHERE
  event_name = 'session_start'
),

events as (
SELECT 
  TIMESTAMP_MICROS(event_timestamp) AS event_timestamp,
  event_name,
  user_pseudo_id || CAST((SELECT value.int_value FROM e.event_params WHERE KEY = 'ga_session_id') AS STRING) AS user_session_id
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` e
WHERE
  event_name IN ('session_start', 'view_item', 'add_to_cart', 'begin_checkout', 'add_shipping_info', 'add_payment_info',  'purchase')
)

SELECT 
  s.*, 
  e.event_timestamp,
  e.event_name
FROM sessions_info s
LEFT JOIN events e USING(user_session_id)