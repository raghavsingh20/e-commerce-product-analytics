-- Query 1: What are the store's headline KPIs: users, buyers, conversion, orders, revenue and AOV?

Select
Count(Distinct user_pseudo_id) as users,
Count(Distinct Case When event_name = 'purchase' Then user_pseudo_id End) as buyers,
Round(100 * Count(Distinct Case When event_name = 'purchase' Then user_pseudo_id End)
/ Count(Distinct user_pseudo_id), 2) as user_conversion_pct,
Count(Distinct transaction_id) as orders,
Round(Sum(revenue), 2) as revenue_usd,
Round(Sum(revenue) / Count(Distinct transaction_id), 2) as avg_order_value_usd
From `product-analytics-ga4-515415.analytics.events_clean`;


-- Query 2: How did users, buyers and revenue change week over week?

With weekly_metrics as (
Select
Date_Trunc(dt, Week(Monday)) as week,
Count(Distinct user_pseudo_id) as users,
Count(Distinct Case When event_name = 'purchase' Then user_pseudo_id End) as buyers,
Coalesce(Sum(revenue), 0) as revenue_usd
From `product-analytics-ga4-515415.analytics.events_clean`
Group by Date_Trunc(dt, Week(Monday))
),
weekly_with_prev as (
Select
week,
users,
buyers,
revenue_usd,
Lag(revenue_usd) Over (Order by week) as prev_week_revenue_usd
From weekly_metrics
)
Select
week,
users,
buyers,
Round(revenue_usd, 2) as revenue_usd,
Round(prev_week_revenue_usd, 2) as prev_week_revenue_usd,
Round(100 * (revenue_usd - prev_week_revenue_usd)
/ Nullif(prev_week_revenue_usd, 0), 1) as revenue_growth_pct
From weekly_with_prev
Order by week;


-- Query 3: How did conversion and revenue per day change across the holiday season?

With holiday_periods as (
Select
dt,
session_key,
event_name,
revenue,
Case
When dt < Date '2020-11-27' Then '1. Before Black Friday'
When dt <= Date '2020-11-30' Then '2. Black Friday to Cyber Monday'
When dt <= Date '2020-12-24' Then '3. December until Christmas'
Else '4. After Christmas'
End as period
From `product-analytics-ga4-515415.analytics.events_clean`
)
Select
period,
Count(Distinct dt) as days,
Count(Distinct session_key) as visits,
Round(100 * Count(Distinct Case When event_name = 'purchase' Then session_key End)
/ Count(Distinct session_key), 2) as visit_conversion_pct,
Round(Coalesce(Sum(revenue), 0) / Count(Distinct dt), 2) as revenue_per_day_usd
From holiday_periods
Group by period
Order by period;


-- Query 4: At which funnel step do the most users drop off?

With funnel_steps as (
Select
Case event_name
When 'session_start'    Then 1
When 'view_item'        Then 2
When 'add_to_cart'      Then 3
When 'begin_checkout'   Then 4
When 'add_payment_info' Then 5
When 'purchase'         Then 6
End as step_no,
event_name,
Count(Distinct user_pseudo_id) as users
From `product-analytics-ga4-515415.analytics.events_clean`
Where event_name In ('session_start', 'view_item', 'add_to_cart',
'begin_checkout', 'add_payment_info', 'purchase')
Group by event_name
),
funnel_with_prev as (
Select
step_no,
event_name,
users,
Lag(users) Over (Order by step_no) as prev_step_users
From funnel_steps
)
Select
step_no,
event_name,
users,
prev_step_users,
Round(100 - 100 * users / prev_step_users, 1) as drop_off_pct
From funnel_with_prev
Order by step_no;


-- Query 5: What % of users added to cart but never bought?

With cart_users as (
Select Distinct user_pseudo_id
From `product-analytics-ga4-515415.analytics.events_clean`
Where event_name = 'add_to_cart' And user_pseudo_id is Not Null
),
buyers as (
Select Distinct user_pseudo_id
From `product-analytics-ga4-515415.analytics.events_clean`
Where event_name = 'purchase'
),
abandoners as (
Select Count(*) as never_bought
From cart_users c
Left Join buyers b on b.user_pseudo_id = c.user_pseudo_id
Where b.user_pseudo_id is Null
)
Select
(Select Count(*) From cart_users) as cart_users,
never_bought,
Round(100 * never_bought / (Select Count(*) From cart_users), 1) as abandon_pct
From abandoners;


-- Query 6: Which devices and traffic sources convert best?

Select segment_type, segment, users, user_conversion_pct
From (
Select 'device' as segment_type, device as segment,
Count(Distinct user_pseudo_id) as users,
Round(100 * Count(Distinct Case When event_name = 'purchase' Then user_pseudo_id End)
/ Count(Distinct user_pseudo_id), 2) as user_conversion_pct
From `product-analytics-ga4-515415.analytics.events_clean`
Group by device
Union All
Select 'traffic source', medium,
Count(Distinct user_pseudo_id),
Round(100 * Count(Distinct Case When event_name = 'purchase' Then user_pseudo_id End)
/ Count(Distinct user_pseudo_id), 2)
From `product-analytics-ga4-515415.analytics.events_clean`
Group by medium
) as segments
Order by segment_type, users Desc;


-- Query 7: Do returning visits convert better than first visits?

With visit_events as (
Select
session_key,
event_name,
Case When session_number = 1 Then 'first visit' Else 'returning visit' End as visit_type
From `product-analytics-ga4-515415.analytics.events_clean`
Where session_number is Not Null
)
Select
visit_type,
Count(Distinct session_key) as visits,
Count(Distinct Case When event_name = 'purchase' Then session_key End) as visits_with_purchase,
Round(100 * Count(Distinct Case When event_name = 'purchase' Then session_key End)
/ Count(Distinct session_key), 2) as visit_conversion_pct
From visit_events
Group by visit_type;


-- Query 8: What % of new visitors bought within 7 days of their first visit?

With user_milestones as (
Select
user_pseudo_id,
Min(first_visit_date) as first_visit_date,
Min(Case When event_name = 'purchase' Then dt End) as first_purchase_date
From `product-analytics-ga4-515415.analytics.events_clean`
Group by user_pseudo_id
)
Select
Count(*) as new_users,
Sum(Case When Date_Diff(first_purchase_date, first_visit_date, Day) <= 7
Then 1 Else 0 End) as bought_within_7_days,
Round(100 * Sum(Case When Date_Diff(first_purchase_date, first_visit_date, Day) <= 7
Then 1 Else 0 End) / Count(*), 2) as activation_pct
From user_milestones
Where first_visit_date Between Date '2020-11-01' And Date '2021-01-24';


-- Query 9: What % of new users came back exactly 1 day and 7 days after their first visit?

With new_users as (
Select user_pseudo_id, Min(first_visit_date) as first_visit_date
From `product-analytics-ga4-515415.analytics.events_clean`
Where first_visit_date Between Date '2020-11-01' And Date '2021-01-24'
Group by user_pseudo_id
),
active_days as (
Select Distinct user_pseudo_id, dt
From `product-analytics-ga4-515415.analytics.events_clean`
),
return_counts as (
Select
Count(Distinct n.user_pseudo_id) as new_users,
Count(Distinct Case When Date_Diff(a.dt, n.first_visit_date, Day) = 1 Then n.user_pseudo_id End) as came_back_day_1,
Count(Distinct Case When Date_Diff(a.dt, n.first_visit_date, Day) = 7 Then n.user_pseudo_id End) as came_back_day_7
From new_users n
Left Join active_days a on a.user_pseudo_id = n.user_pseudo_id
)
Select
new_users,
came_back_day_1,
Round(100 * came_back_day_1 / new_users, 2) as day_1_return_pct,
came_back_day_7,
Round(100 * came_back_day_7 / new_users, 2) as day_7_return_pct
From return_counts;


-- Query 10: What % of each weekly cohort came back in each later week?

With user_cohort as (
Select user_pseudo_id, Date_Trunc(Min(first_visit_date), Week(Monday)) as cohort_week
From `product-analytics-ga4-515415.analytics.events_clean`
Group by user_pseudo_id
Having Min(first_visit_date) >= Date '2020-11-01'
),
cohort_size as (
Select cohort_week, Count(*) as cohort_users
From user_cohort
Group by cohort_week
),
user_activity as (
Select Distinct user_pseudo_id, Date_Trunc(dt, Week(Monday)) as active_week
From `product-analytics-ga4-515415.analytics.events_clean`
),
cohort_activity as (
Select
a.user_pseudo_id,
c.cohort_week,
Date_Diff(a.active_week, c.cohort_week, Week) as weeks_later
From user_cohort c
Join user_activity a on a.user_pseudo_id = c.user_pseudo_id
)
Select
ca.cohort_week,
ca.weeks_later,
Count(*) as users,
Round(100 * Count(*) / s.cohort_users, 1) as return_pct
From cohort_activity ca
Join cohort_size s on s.cohort_week = ca.cohort_week
Where ca.weeks_later >= 0
Group by ca.cohort_week, ca.weeks_later, s.cohort_users
Order by ca.cohort_week, ca.weeks_later;


-- Query 11: How sticky was December: average daily users / monthly users?

With dec_daily_users as (
Select dt, Count(Distinct user_pseudo_id) as daily_users
From `product-analytics-ga4-515415.analytics.events_clean`
Where dt Between Date '2020-12-01' And Date '2020-12-31'
Group by dt
),
dec_monthly_users as (
Select Count(Distinct user_pseudo_id) as monthly_users
From `product-analytics-ga4-515415.analytics.events_clean`
Where dt Between Date '2020-12-01' And Date '2020-12-31'
)
Select
Round(Avg(daily_users)) as avg_daily_users,
(Select monthly_users From dec_monthly_users) as monthly_users,
Round(100 * Avg(daily_users) / (Select monthly_users From dec_monthly_users), 1) as stickiness_pct
From dec_daily_users;


-- Query 12: Of users active in November but not December, what % came back in January?

With nov_users as (
Select Distinct user_pseudo_id
From `product-analytics-ga4-515415.analytics.events_clean`
Where dt < Date '2020-12-01' And user_pseudo_id is Not Null
),
dec_users as (
Select Distinct user_pseudo_id
From `product-analytics-ga4-515415.analytics.events_clean`
Where dt Between Date '2020-12-01' And Date '2020-12-31'
),
jan_users as (
Select Distinct user_pseudo_id
From `product-analytics-ga4-515415.analytics.events_clean`
Where dt >= Date '2021-01-01'
),
lapsed_users as (
Select n.user_pseudo_id
From nov_users n
Left Join dec_users d on d.user_pseudo_id = n.user_pseudo_id
Where d.user_pseudo_id is Null
)
Select
Count(*) as away_in_dec,
Count(j.user_pseudo_id) as came_back_in_jan,
Round(100 * Count(j.user_pseudo_id) / Count(*), 1) as came_back_pct
From lapsed_users l
Left Join jan_users j on j.user_pseudo_id = l.user_pseudo_id;


-- Query 13: What % of buyers ordered more than once?

With buyer_orders as (
Select user_pseudo_id, Count(Distinct transaction_id) as orders
From `product-analytics-ga4-515415.analytics.events_clean`
Where event_name = 'purchase'
Group by user_pseudo_id
)
Select
Count(*) as buyers,
Sum(Case When orders >= 2 Then 1 Else 0 End) as repeat_buyers,
Round(100 * Sum(Case When orders >= 2 Then 1 Else 0 End) / Count(*), 1) as repeat_rate_pct
From buyer_orders;


-- Query 14: Are first orders bigger or smaller than repeat orders?

With orders as (
Select
user_pseudo_id,
transaction_id,
Min(dt) as order_date,
Sum(revenue) as revenue
From `product-analytics-ga4-515415.analytics.events_clean`
Where event_name = 'purchase' And transaction_id is Not Null
Group by user_pseudo_id, transaction_id
),
labelled_orders as (
Select
revenue,
Case
When Row_Number() Over (Partition by user_pseudo_id Order by order_date, transaction_id) = 1
Then 'first order' Else 'repeat order'
End as order_type
From orders
)
Select
order_type,
Count(*) as orders,
Round(Sum(revenue) / Count(*), 2) as avg_order_value_usd
From labelled_orders
Group by order_type;


-- Query 15: Is weekly growth coming from new buyers or returning buyers?

With purchase_days as (
Select Distinct
user_pseudo_id,
dt,
Date_Trunc(dt, Week(Monday)) as purchase_week
From `product-analytics-ga4-515415.analytics.events_clean`
Where event_name = 'purchase'
),
first_purchase as (
Select user_pseudo_id, Min(dt) as first_purchase_date
From purchase_days
Group by user_pseudo_id
)
Select
p.purchase_week,
Count(Distinct Case When p.dt = f.first_purchase_date Then p.user_pseudo_id End) as new_buyers,
Count(Distinct Case When p.dt > f.first_purchase_date Then p.user_pseudo_id End) as returning_buyers
From purchase_days p
Join first_purchase f on f.user_pseudo_id = p.user_pseudo_id
Group by p.purchase_week
Order by p.purchase_week;