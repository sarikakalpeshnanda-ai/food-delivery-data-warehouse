-- Full-refresh ETL from operational records into the star schema.
SET search_path TO food_delivery;

TRUNCATE fact_order, dim_date, dim_customer, dim_restaurant,
         dim_delivery_partner, dim_location, dim_order_status RESTART IDENTITY;

INSERT INTO dim_date (date_key, full_date, month_start, month_name, calendar_year, calendar_month, day_of_week, is_weekend)
SELECT to_char(d, 'YYYYMMDD')::INTEGER, d, date_trunc('month', d)::DATE,
       to_char(d, 'Mon YYYY'), EXTRACT(YEAR FROM d)::INTEGER, EXTRACT(MONTH FROM d)::INTEGER,
       to_char(d, 'Day'), EXTRACT(ISODOW FROM d) IN (6, 7)
FROM generate_series('2024-11-01'::DATE, '2025-06-30'::DATE, interval '1 day') AS g(d);

INSERT INTO dim_customer (customer_id, customer_name, signup_date, city)
SELECT customer_id, customer_name, signup_date, city FROM raw_customers;

INSERT INTO dim_restaurant (restaurant_id, restaurant_name, cuisine, commission_rate)
SELECT restaurant_id, restaurant_name, cuisine, commission_rate FROM raw_restaurants;

INSERT INTO dim_delivery_partner (partner_id, partner_name, vehicle_type)
SELECT partner_id, partner_name, vehicle_type FROM raw_delivery_partners;

INSERT INTO dim_location (city)
SELECT DISTINCT city FROM raw_customers
UNION
SELECT DISTINCT city FROM raw_restaurants;

INSERT INTO dim_order_status (status_name)
SELECT DISTINCT order_status FROM raw_orders;

INSERT INTO fact_order (
  order_id, order_date_key, customer_key, restaurant_key, delivery_partner_key,
  location_key, order_status_key, order_ts, subtotal_inr, delivery_fee_inr,
  discount_inr, net_order_value_inr, commission_inr, delivery_minutes,
  promised_minutes, delivery_variance_minutes, is_on_time, customer_rating
)
SELECT
  o.order_id,
  to_char(o.order_ts::DATE, 'YYYYMMDD')::INTEGER,
  c.customer_key, r.restaurant_key, dp.delivery_partner_key, l.location_key,
  os.order_status_key, o.order_ts, o.subtotal_inr, o.delivery_fee_inr, o.discount_inr,
  o.subtotal_inr + o.delivery_fee_inr - o.discount_inr,
  ROUND(o.subtotal_inr * r.commission_rate, 2),
  ROUND(EXTRACT(EPOCH FROM (d.delivered_ts - o.order_ts)) / 60.0, 2),
  d.promised_minutes,
  ROUND(EXTRACT(EPOCH FROM (d.delivered_ts - o.order_ts)) / 60.0 - d.promised_minutes, 2),
  CASE WHEN d.order_id IS NULL THEN NULL
       WHEN d.delivered_ts <= o.order_ts + d.promised_minutes * interval '1 minute' THEN TRUE ELSE FALSE END,
  d.customer_rating
FROM raw_orders o
JOIN dim_customer c ON c.customer_id = o.customer_id
JOIN dim_restaurant r ON r.restaurant_id = o.restaurant_id
JOIN dim_location l ON l.city = c.city
JOIN dim_order_status os ON os.status_name = o.order_status
LEFT JOIN raw_deliveries d ON d.order_id = o.order_id
LEFT JOIN dim_delivery_partner dp ON dp.partner_id = d.partner_id;
