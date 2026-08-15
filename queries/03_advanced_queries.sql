SET search_path TO food_delivery;

-- 1. Monthly customer retention cohorts. Cohort month is the customer's first delivered order.
WITH delivered_orders AS (
  SELECT f.customer_key, d.month_start AS order_month
  FROM fact_order f JOIN dim_date d ON d.date_key = f.order_date_key
  JOIN dim_order_status s USING (order_status_key)
  WHERE s.status_name = 'Delivered'
), cohorts AS (
  SELECT customer_key, MIN(order_month) AS cohort_month
  FROM delivered_orders GROUP BY customer_key
), activity AS (
  SELECT c.cohort_month, o.order_month,
         (EXTRACT(YEAR FROM age(o.order_month, c.cohort_month)) * 12 +
          EXTRACT(MONTH FROM age(o.order_month, c.cohort_month)))::INTEGER AS months_since_first_order,
         o.customer_key
  FROM delivered_orders o JOIN cohorts c USING (customer_key)
), cohort_sizes AS (
  SELECT cohort_month, COUNT(*) AS cohort_customers FROM cohorts GROUP BY cohort_month
)
SELECT a.cohort_month, a.months_since_first_order,
       COUNT(DISTINCT a.customer_key) AS active_customers,
       cs.cohort_customers,
       ROUND(100.0 * COUNT(DISTINCT a.customer_key) / cs.cohort_customers, 2) AS retention_rate_pct
FROM activity a JOIN cohort_sizes cs USING (cohort_month)
GROUP BY a.cohort_month, a.months_since_first_order, cs.cohort_customers
ORDER BY a.cohort_month, a.months_since_first_order;

-- 2. Rank delivery partners within city, based on on-time rate and volume.
WITH partner_performance AS (
  SELECT l.city, p.partner_name, COUNT(*) AS deliveries,
         ROUND(100.0 * AVG(CASE WHEN f.is_on_time THEN 1 ELSE 0 END), 2) AS on_time_rate_pct,
         ROUND(AVG(f.delivery_minutes), 2) AS avg_delivery_minutes
  FROM fact_order f JOIN dim_delivery_partner p USING (delivery_partner_key)
  JOIN dim_location l USING (location_key)
  JOIN dim_order_status s USING (order_status_key)
  WHERE s.status_name = 'Delivered'
  GROUP BY l.city, p.partner_name
)
SELECT *, DENSE_RANK() OVER (PARTITION BY city ORDER BY on_time_rate_pct DESC, deliveries DESC) AS city_rank
FROM partner_performance
ORDER BY city, city_rank;

-- 3. Repeat purchase and customer lifetime value snapshot.
SELECT c.customer_name, l.city, COUNT(*) AS delivered_orders,
       ROUND(SUM(f.net_order_value_inr), 2) AS lifetime_net_order_value_inr,
       ROUND(AVG(f.net_order_value_inr), 2) AS avg_order_value_inr,
       MAX(f.order_ts)::DATE AS most_recent_order_date
FROM fact_order f JOIN dim_customer c USING (customer_key)
JOIN dim_location l USING (location_key)
JOIN dim_order_status s USING (order_status_key)
WHERE s.status_name = 'Delivered'
GROUP BY c.customer_name, l.city
ORDER BY lifetime_net_order_value_inr DESC;
