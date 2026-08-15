SET search_path TO food_delivery;

-- 1. Check warehouse grain and delivery coverage.
SELECT os.status_name, COUNT(*) AS orders,
       COUNT(*) FILTER (WHERE f.delivery_minutes IS NOT NULL) AS orders_with_delivery_data
FROM fact_order f JOIN dim_order_status os USING (order_status_key)
GROUP BY os.status_name ORDER BY orders DESC;

-- 2. Profile core source entities.
SELECT 'customers' AS entity, COUNT(*) AS records FROM dim_customer
UNION ALL SELECT 'restaurants', COUNT(*) FROM dim_restaurant
UNION ALL SELECT 'delivery partners', COUNT(*) FROM dim_delivery_partner
UNION ALL SELECT 'orders', COUNT(*) FROM fact_order;

-- 3. Orders and net order value by city.
SELECT l.city, COUNT(*) FILTER (WHERE os.status_name = 'Delivered') AS delivered_orders,
       ROUND(SUM(f.net_order_value_inr) FILTER (WHERE os.status_name = 'Delivered'), 2) AS net_order_value_inr
FROM fact_order f
JOIN dim_location l USING (location_key)
JOIN dim_order_status os USING (order_status_key)
GROUP BY l.city ORDER BY net_order_value_inr DESC;

-- 4. Restaurants with the most cancelled orders.
SELECT r.restaurant_name, COUNT(*) AS cancelled_orders
FROM fact_order f JOIN dim_restaurant r USING (restaurant_key)
JOIN dim_order_status os USING (order_status_key)
WHERE os.status_name = 'Cancelled'
GROUP BY r.restaurant_name ORDER BY cancelled_orders DESC, r.restaurant_name;
