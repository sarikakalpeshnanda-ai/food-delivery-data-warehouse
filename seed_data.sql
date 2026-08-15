SET search_path TO food_delivery;

INSERT INTO raw_customers (customer_id, customer_name, signup_date, city) VALUES
 (1, 'Aarav Shah', '2024-11-12', 'Mumbai'), (2, 'Diya Patel', '2024-12-04', 'Mumbai'),
 (3, 'Kabir Mehta', '2025-01-08', 'Bengaluru'), (4, 'Ananya Rao', '2025-01-14', 'Bengaluru'),
 (5, 'Vivaan Singh', '2025-02-01', 'Delhi'), (6, 'Ishita Verma', '2025-02-11', 'Delhi'),
 (7, 'Arjun Iyer', '2025-03-03', 'Chennai'), (8, 'Meera Nair', '2025-03-17', 'Chennai'),
 (9, 'Reyansh Gupta', '2025-04-05', 'Mumbai'), (10, 'Saanvi Kapoor', '2025-04-20', 'Delhi'),
 (11, 'Aditya Joshi', '2025-05-02', 'Bengaluru'), (12, 'Kiara Das', '2025-05-15', 'Chennai');

INSERT INTO raw_restaurants (restaurant_id, restaurant_name, cuisine, city, commission_rate) VALUES
 (1, 'Spice Route', 'North Indian', 'Mumbai', 0.22), (2, 'Coastal Bowl', 'South Indian', 'Mumbai', 0.20),
 (3, 'Garden Wok', 'Chinese', 'Bengaluru', 0.23), (4, 'Pasta Piazza', 'Italian', 'Bengaluru', 0.20),
 (5, 'Delhi Darbar', 'Mughlai', 'Delhi', 0.24), (6, 'Green Fork', 'Healthy', 'Delhi', 0.18),
 (7, 'Dosa District', 'South Indian', 'Chennai', 0.21), (8, 'Biryani Bay', 'Biryani', 'Chennai', 0.25);

INSERT INTO raw_delivery_partners (partner_id, partner_name, vehicle_type, city) VALUES
 (1, 'Rohan Kumar', 'Bike', 'Mumbai'), (2, 'Nikhil Jain', 'Scooter', 'Mumbai'),
 (3, 'Manoj S', 'Bike', 'Bengaluru'), (4, 'Priya K', 'Scooter', 'Bengaluru'),
 (5, 'Sahil Khan', 'Bike', 'Delhi'), (6, 'Neha Singh', 'Scooter', 'Delhi'),
 (7, 'Karthik R', 'Bike', 'Chennai'), (8, 'Divya M', 'Bicycle', 'Chennai');

-- 480 orders, evenly distributed across Jan-Jun 2025. Every 17th order is cancelled.
INSERT INTO raw_orders (order_id, customer_id, restaurant_id, order_ts, order_status, subtotal_inr, delivery_fee_inr, discount_inr)
SELECT
  n,
  ((n - 1) % 12) + 1,
  CASE ((n - 1) % 12) + 1
    WHEN 1 THEN 1 WHEN 2 THEN 2 WHEN 9 THEN 1
    WHEN 3 THEN 3 WHEN 4 THEN 4 WHEN 11 THEN 3
    WHEN 5 THEN 5 WHEN 6 THEN 6 WHEN 10 THEN 5
    WHEN 7 THEN 7 WHEN 8 THEN 8 WHEN 12 THEN 7
  END,
  timestamp '2025-01-01 11:00:00' + ((n - 1) % 181) * interval '1 day' + ((n % 9) * interval '1 hour'),
  CASE WHEN n % 17 = 0 THEN 'Cancelled' ELSE 'Delivered' END,
  180 + ((n * 37) % 520),
  25 + ((n * 7) % 45),
  CASE WHEN n % 5 = 0 THEN 40 ELSE CASE WHEN n % 9 = 0 THEN 75 ELSE 0 END END
FROM generate_series(1, 480) AS n;

INSERT INTO raw_deliveries (order_id, partner_id, assigned_ts, picked_up_ts, delivered_ts, promised_minutes, customer_rating)
SELECT
  o.order_id,
  CASE o.restaurant_id
    WHEN 1 THEN 1 WHEN 2 THEN 2 WHEN 3 THEN 3 WHEN 4 THEN 4
    WHEN 5 THEN 5 WHEN 6 THEN 6 WHEN 7 THEN 7 WHEN 8 THEN 8
  END,
  o.order_ts + interval '5 minutes',
  o.order_ts + (12 + (o.order_id % 14)) * interval '1 minute',
  o.order_ts + (25 + (o.order_id % 28) + CASE WHEN o.order_id % 11 = 0 THEN 16 ELSE 0 END) * interval '1 minute',
  38 + (o.order_id % 8),
  CASE WHEN o.order_id % 13 = 0 THEN 3.0 WHEN o.order_id % 7 = 0 THEN 4.0 ELSE 5.0 END
FROM raw_orders o
WHERE o.order_status = 'Delivered';
