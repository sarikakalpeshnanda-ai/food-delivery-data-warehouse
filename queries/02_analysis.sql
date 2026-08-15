SET search_path TO food_delivery;

-- Monthly KPI scorecard: GMV is food subtotal before discount; net order value includes delivery fees.
SELECT d.month_start,
       COUNT(*) FILTER (WHERE s.status_name = 'Delivered') AS delivered_orders,
       COUNT(*) FILTER (WHERE s.status_name = 'Cancelled') AS cancelled_orders,
       ROUND(100.0 * COUNT(*) FILTER (WHERE s.status_name = 'Cancelled') / COUNT(*), 2) AS cancellation_rate_pct,
       ROUND(SUM(f.subtotal_inr) FILTER (WHERE s.status_name = 'Delivered'), 2) AS gmv_inr,
       ROUND(SUM(f.net_order_value_inr) FILTER (WHERE s.status_name = 'Delivered'), 2) AS net_order_value_inr,
       ROUND(SUM(f.commission_inr) FILTER (WHERE s.status_name = 'Delivered'), 2) AS commission_revenue_inr,
       ROUND(AVG(f.net_order_value_inr) FILTER (WHERE s.status_name = 'Delivered'), 2) AS avg_order_value_inr
FROM fact_order f JOIN dim_date d ON d.date_key = f.order_date_key
JOIN dim_order_status s USING (order_status_key)
GROUP BY d.month_start ORDER BY d.month_start;

-- Delivery-time analysis by city: late means delivered after the promised time.
SELECT l.city,
       COUNT(*) AS delivered_orders,
       ROUND(AVG(f.delivery_minutes), 2) AS avg_delivery_minutes,
       ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY f.delivery_minutes)::NUMERIC, 2) AS p90_delivery_minutes,
       ROUND(100.0 * AVG(CASE WHEN f.is_on_time THEN 1 ELSE 0 END), 2) AS on_time_rate_pct,
       ROUND(AVG(f.customer_rating), 2) AS avg_customer_rating
FROM fact_order f JOIN dim_location l USING (location_key)
JOIN dim_order_status s USING (order_status_key)
WHERE s.status_name = 'Delivered'
GROUP BY l.city ORDER BY on_time_rate_pct, avg_delivery_minutes DESC;

-- Restaurant performance with a minimum volume threshold.
SELECT r.restaurant_name, r.cuisine, COUNT(*) AS delivered_orders,
       ROUND(SUM(f.net_order_value_inr), 2) AS net_order_value_inr,
       ROUND(AVG(f.delivery_minutes), 2) AS avg_delivery_minutes,
       ROUND(AVG(f.customer_rating), 2) AS avg_rating
FROM fact_order f JOIN dim_restaurant r USING (restaurant_key)
JOIN dim_order_status s USING (order_status_key)
WHERE s.status_name = 'Delivered'
GROUP BY r.restaurant_name, r.cuisine
HAVING COUNT(*) >= 10
ORDER BY net_order_value_inr DESC;
