Create Or Replace Table `product-analytics-ga4-515415.analytics.events_clean` as
With base_events as (
Select
Parse_Date('%Y%m%d', event_date) as dt,
Timestamp_Micros(event_timestamp) as ts,
event_name,
user_pseudo_id,
Date(Timestamp_Micros(user_first_touch_timestamp)) as first_visit_date,
Concat(user_pseudo_id, '-', Cast(
(Select value.int_value From Unnest(event_params) Where key = 'ga_session_id') as String)
) as session_key,
(Select value.int_value From Unnest(event_params) Where key = 'ga_session_number') as session_number,
device.category as device,
geo.country as country,
traffic_source.medium as medium,
Nullif(Nullif(ecommerce.transaction_id, '(not set)'), '') as transaction_id,
ecommerce.purchase_revenue_in_usd as order_revenue
From `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
)
Select
dt, ts, event_name, user_pseudo_id, first_visit_date, session_key, session_number,
device, country, medium, transaction_id,
Case
When event_name = 'purchase'
And transaction_id is Not Null
And Row_Number() Over (Partition by transaction_id Order by ts) = 1
Then order_revenue
End as revenue
From base_events;
