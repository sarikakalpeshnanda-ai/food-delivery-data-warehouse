# Data Dictionary

## Source layer

| Table | Grain | Purpose |
|---|---|---|
| `raw_customers` | One row per customer | Customer identity, signup date, and home city. |
| `raw_restaurants` | One row per restaurant | Restaurant attributes and platform commission rate. |
| `raw_delivery_partners` | One row per delivery partner | Courier identity, vehicle, and operating city. |
| `raw_orders` | One row per order | Commercial order event and its final status. |
| `raw_deliveries` | One row per delivered order | Courier timestamps, promised time, and rating. |

## Warehouse layer

| Table | Grain | Purpose |
|---|---|---|
| `dim_date` | One row per calendar date | Supports monthly, weekday, and weekend analysis. |
| `dim_customer` | One row per customer | Customer dimension. |
| `dim_restaurant` | One row per restaurant | Restaurant and cuisine dimension. |
| `dim_delivery_partner` | One row per partner | Courier and vehicle dimension. |
| `dim_location` | One row per city | Conformed city dimension. |
| `dim_order_status` | One row per status | Delivered/cancelled status dimension. |
| `fact_order` | One row per order | Central fact for commercial and delivery metrics. |

## Fact metrics

| Column | Definition |
|---|---|
| `subtotal_inr` | Food-item value before discounts or delivery fees. |
| `delivery_fee_inr` | Delivery charge collected from the customer. |
| `discount_inr` | Discount funded by the platform or restaurant. |
| `net_order_value_inr` | `subtotal_inr + delivery_fee_inr - discount_inr`. |
| `commission_inr` | Restaurant subtotal multiplied by the restaurant commission rate. |
| `delivery_minutes` | Minutes from order placement to delivered timestamp. Null for cancelled orders. |
| `delivery_variance_minutes` | Actual delivery minutes minus the promised delivery time. Positive values are late. |
| `is_on_time` | True when delivery completed on or before the promised time. |

## KPI definitions

| KPI | Calculation | Notes |
|---|---|---|
| Delivered orders | Count of `Delivered` orders | Excludes cancellations. |
| GMV | Sum of `subtotal_inr` for delivered orders | Food value before discount. |
| Net order value | Sum of `net_order_value_inr` for delivered orders | Includes delivery fee and discount. |
| Cancellation rate | Cancelled orders / all orders | Measured at the order level. |
| On-time rate | On-time delivered orders / delivered orders | Use only non-null delivery records. |
| Cohort retention | Active cohort customers / original cohort customers | Cohort is assigned from first delivered-order month. |
