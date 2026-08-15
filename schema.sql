-- Food Delivery Data Warehouse | PostgreSQL 14+
-- Run this file before seed_data.sql and etl.sql.

DROP SCHEMA IF EXISTS food_delivery CASCADE;
CREATE SCHEMA food_delivery;
SET search_path TO food_delivery;

-- Raw operational layer ------------------------------------------------------
CREATE TABLE raw_customers (
    customer_id       INTEGER PRIMARY KEY,
    customer_name     TEXT NOT NULL,
    signup_date       DATE NOT NULL,
    city              TEXT NOT NULL
);

CREATE TABLE raw_restaurants (
    restaurant_id     INTEGER PRIMARY KEY,
    restaurant_name   TEXT NOT NULL,
    cuisine           TEXT NOT NULL,
    city              TEXT NOT NULL,
    commission_rate   NUMERIC(5,4) NOT NULL CHECK (commission_rate BETWEEN 0 AND 1)
);

CREATE TABLE raw_delivery_partners (
    partner_id        INTEGER PRIMARY KEY,
    partner_name      TEXT NOT NULL,
    vehicle_type      TEXT NOT NULL CHECK (vehicle_type IN ('Bike', 'Scooter', 'Bicycle')),
    city              TEXT NOT NULL
);

CREATE TABLE raw_orders (
    order_id          INTEGER PRIMARY KEY,
    customer_id       INTEGER NOT NULL REFERENCES raw_customers(customer_id),
    restaurant_id     INTEGER NOT NULL REFERENCES raw_restaurants(restaurant_id),
    order_ts          TIMESTAMP NOT NULL,
    order_status      TEXT NOT NULL CHECK (order_status IN ('Delivered', 'Cancelled')),
    subtotal_inr      NUMERIC(10,2) NOT NULL CHECK (subtotal_inr >= 0),
    delivery_fee_inr  NUMERIC(10,2) NOT NULL CHECK (delivery_fee_inr >= 0),
    discount_inr      NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (discount_inr >= 0)
);

CREATE TABLE raw_deliveries (
    order_id              INTEGER PRIMARY KEY REFERENCES raw_orders(order_id),
    partner_id            INTEGER NOT NULL REFERENCES raw_delivery_partners(partner_id),
    assigned_ts           TIMESTAMP NOT NULL,
    picked_up_ts          TIMESTAMP NOT NULL,
    delivered_ts          TIMESTAMP NOT NULL,
    promised_minutes      INTEGER NOT NULL CHECK (promised_minutes > 0),
    customer_rating       NUMERIC(2,1) CHECK (customer_rating BETWEEN 1 AND 5)
);

-- Dimensional warehouse ------------------------------------------------------
CREATE TABLE dim_date (
    date_key           INTEGER PRIMARY KEY, -- YYYYMMDD
    full_date          DATE NOT NULL UNIQUE,
    month_start        DATE NOT NULL,
    month_name         TEXT NOT NULL,
    calendar_year      INTEGER NOT NULL,
    calendar_month     INTEGER NOT NULL,
    day_of_week        TEXT NOT NULL,
    is_weekend         BOOLEAN NOT NULL
);

CREATE TABLE dim_customer (
    customer_key       SERIAL PRIMARY KEY,
    customer_id        INTEGER NOT NULL UNIQUE,
    customer_name      TEXT NOT NULL,
    signup_date        DATE NOT NULL,
    city               TEXT NOT NULL
);

CREATE TABLE dim_restaurant (
    restaurant_key     SERIAL PRIMARY KEY,
    restaurant_id      INTEGER NOT NULL UNIQUE,
    restaurant_name    TEXT NOT NULL,
    cuisine            TEXT NOT NULL,
    commission_rate    NUMERIC(5,4) NOT NULL
);

CREATE TABLE dim_delivery_partner (
    delivery_partner_key SERIAL PRIMARY KEY,
    partner_id         INTEGER NOT NULL UNIQUE,
    partner_name       TEXT NOT NULL,
    vehicle_type       TEXT NOT NULL
);

CREATE TABLE dim_location (
    location_key       SERIAL PRIMARY KEY,
    city               TEXT NOT NULL UNIQUE
);

CREATE TABLE dim_order_status (
    order_status_key   SERIAL PRIMARY KEY,
    status_name        TEXT NOT NULL UNIQUE
);

CREATE TABLE fact_order (
    order_id              INTEGER PRIMARY KEY,
    order_date_key        INTEGER NOT NULL REFERENCES dim_date(date_key),
    customer_key          INTEGER NOT NULL REFERENCES dim_customer(customer_key),
    restaurant_key        INTEGER NOT NULL REFERENCES dim_restaurant(restaurant_key),
    delivery_partner_key  INTEGER REFERENCES dim_delivery_partner(delivery_partner_key),
    location_key          INTEGER NOT NULL REFERENCES dim_location(location_key),
    order_status_key      INTEGER NOT NULL REFERENCES dim_order_status(order_status_key),
    order_ts              TIMESTAMP NOT NULL,
    subtotal_inr          NUMERIC(10,2) NOT NULL,
    delivery_fee_inr      NUMERIC(10,2) NOT NULL,
    discount_inr          NUMERIC(10,2) NOT NULL,
    net_order_value_inr   NUMERIC(10,2) NOT NULL,
    commission_inr        NUMERIC(10,2) NOT NULL,
    delivery_minutes      NUMERIC(10,2),
    promised_minutes      INTEGER,
    delivery_variance_minutes NUMERIC(10,2),
    is_on_time            BOOLEAN,
    customer_rating       NUMERIC(2,1)
);

CREATE INDEX ix_fact_order_date ON fact_order(order_date_key);
CREATE INDEX ix_fact_order_customer ON fact_order(customer_key);
CREATE INDEX ix_fact_order_restaurant ON fact_order(restaurant_key);
