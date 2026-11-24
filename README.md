# E-commerce Product Analytics

## Overview

SQL analysis of Google Analytics 4 (GA4) event data from the Google Merchandise Store, covering 270K+ users between November 2020 and January 2021. The project answers 15 product analytics questions on business health, the purchase funnel, user retention and repeat purchasing.

## Dataset

* **Source:** Google's public BigQuery dataset `bigquery-public-data.ga4_obfuscated_sample_ecommerce`
* **Period:** 1 Nov 2020 – 31 Jan 2021
* **Contents:** User events (page views, add to cart, checkout, purchase) with device, traffic source, session and order details

## Tools

* **BigQuery (SQL):** Data cleaning and Analysis

## Approach

1. **Data preparation:** Turned Google's raw nested event data into one clean table (`events_clean`) with one row per user action.
2. **Analysis:** Wrote 15 SQL queries using CTEs, Joins, CASE statements and Window functions (LAG, ROW_NUMBER).

## Key Findings

| # | Question | Finding |
|---|---|---|
| 1 | What are the store's headline KPIs? | Only 1.64% of 270K users made a purchase, bringing in $307.6K at an average order value of $69.12. |
| 2 | How did users, buyers and revenue change week over week? | Revenue peaked at $59.2K in the week of 7 Dec, then dropped 69% in Christmas week (week of 21 Dec). |
| 3 | How did conversion and revenue per day change across the holiday season? | Black Friday to Cyber Monday had the best conversion (2.24%), while after Christmas it fell to just 0.91%, the lowest of any period. |
| 4 | At which funnel step do the most users drop off? | The weakest step inside checkout is adding payment info, where 40.8% of users who started checkout dropped off. |
| 5 | What % of users added to cart but never bought? | 9,630 users (76.8%) added items to their cart but never completed a purchase. |
| 6 | Which devices and traffic sources convert best? | Conversion barely changes by device (1.55–1.7%), but referral visitors convert almost twice as well as paid search (1.85% vs. 0.98%). |
| 7 | Do returning visits convert better than first visits? | Returning visits are 4.6x more likely to end in a purchase than first visits (3.1% vs. 0.68%). |
| 8 | What % of new visitors bought within 7 days of their first visit? | Only 1.17% of new visitors (2,803 of 238,644) bought within 7 days of their first visit. |
| 9 | What % of new users came back exactly 1 day and 7 days after their first visit? | Only 4.42% of new users came back the next day and just 0.68% were active exactly a week later. |
| 10 | What % of each weekly cohort came back in each later week? | Cohorts that started in the weeks of 7–28 Dec were the least likely to return, with week-1 return of 2.4–3.1% compared with 4.3–5.7% for those starting 2–23 Nov. |
| 11 | How sticky was December (average daily users ÷ monthly users)? | At 3.7% stickiness, an average December user was active on only about one day of the month. |
| 12 | Of users active in November but not December, what % came back in January? | Once users went quiet in December, very few returned: only 0.7% were back in January. |
| 13 | What % of buyers ordered more than once? | Just 10% of buyers placed more than one order during the three months. |
| 14 | Are first orders bigger or smaller than repeat orders? | First orders were bigger than repeat orders ($70.83 vs. $59.27) and made up about 85% of revenue. |
| 15 | Is weekly growth coming from new buyers or returning buyers? | Between 87% and 100% of each week's buyers were new customers, even in the peak week of 7 Dec (680 new vs. 73 returning). |
