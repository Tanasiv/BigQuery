WITH session_start AS (
SELECT 
user_pseudo_id,
(SELECT value.int_value FROM UNNEST(event_params) WHERE key = "ga_session_id") AS session_id,
(SELECT value.string_value FROM UNNEST(event_params) WHERE key = "page_location") AS page_location,
REGEXP_EXTRACT(
(SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location'),
   r'(?:\w+\:\/\/)?[^\/]+\/([^\?#]*)') AS page_path
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE 
event_name = 'session_start'
AND _TABLE_SUFFIX BETWEEN '20200101' AND '20201231'
),

purchases AS (
SELECT DISTINCT
user_pseudo_id,
event_name,
(SELECT value.int_value FROM UNNEST(event_params) WHERE key = "ga_session_id") AS session_id
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE 
event_name = 'purchase'
AND _TABLE_SUFFIX BETWEEN '20200101' AND '20201231'
)

SELECT 
s.page_path,
COUNT(DISTINCT CONCAT(s.user_pseudo_id, '-', s.session_id)) AS unique_sessions,
COUNT(DISTINCT IF(p.session_id IS NOT NULL, CONCAT(s.user_pseudo_id, '-', s.session_id),NULL)) AS purchases,
SAFE_DIVIDE(COUNT(DISTINCT IF(p.session_id IS NOT NULL, CONCAT(s.user_pseudo_id, '-', s.session_id),NULL)), COUNT(DISTINCT CONCAT(s.user_pseudo_id, '-', s.session_id))) AS conversion_rate
FROM session_start AS s
LEFT JOIN purchases AS p
ON s.user_pseudo_id = p.user_pseudo_id AND s.session_id = p.session_id
GROUP BY 1
ORDER BY 4 DESC

