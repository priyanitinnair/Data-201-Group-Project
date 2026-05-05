#BasicQuery 

#1
SELECT 
    d.drink_category_name,
    COUNT(*) AS total_orders
FROM cart_details c
JOIN drink_category_lookup d
    ON c.drink_category_id = d.drink_category_id
GROUP BY d.drink_category_name
ORDER BY total_orders ASC
LIMIT 1;

#2
SELECT 
    c.channel_name,
    COUNT(o.order_id) AS total_orders
FROM orders o
JOIN channel_lookup c
    ON o.channel_id = c.channel_id
GROUP BY c.channel_name;

#3
SELECT 
    s.store_location_type,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_spend), 2) AS total_revenue,
    ROUND(AVG(o.total_spend), 2) AS avg_order_value
FROM store s
JOIN orders o
    ON s.store_id = o.store_id
GROUP BY s.store_location_type
ORDER BY total_revenue DESC; 

#4
SELECT 
    cd.has_food_item,
    COUNT(o.order_id) AS total_orders,
    ROUND(AVG(o.total_spend), 2) AS avg_spend,
    ROUND(SUM(o.total_spend), 2) AS total_revenue
FROM orders o
JOIN cart_details cd
    ON o.order_id = cd.order_id
GROUP BY cd.has_food_item
ORDER BY avg_spend DESC;

#5
SELECT 
    s.region,
    COUNT(o.order_id) AS total_orders,
    ROUND(AVG(o.fulfillment_time_min), 2) AS avg_fulfillment_time,
    ROUND(AVG(o.customer_satisfaction), 2) AS avg_satisfaction
FROM store s
JOIN orders o
    ON s.store_id = o.store_id
GROUP BY s.region
ORDER BY avg_fulfillment_time DESC
LIMIT 10;

#AdvanceQuery

#1
WITH monthly_sales AS (
    SELECT
        YEAR(o.order_date) AS sales_year,
        MONTH(o.order_date) AS sales_month,
        MONTHNAME(o.order_date) AS month_name,
        SUM(o.total_spend) AS total_sales,
        AVG(o.total_spend) AS avg_customer_spend
    FROM orders o
    GROUP BY
        YEAR(o.order_date),
        MONTH(o.order_date),
        MONTHNAME(o.order_date)
),
ranked_months AS (
    SELECT
        sales_year,
        sales_month,
        month_name,
        total_sales,
        avg_customer_spend,
        RANK() OVER (
            PARTITION BY sales_year
            ORDER BY total_sales DESC
        ) AS month_rank
    FROM monthly_sales
),
top_month_per_year AS (
    SELECT
        sales_year,
        sales_month,
        month_name,
        total_sales,
        avg_customer_spend
    FROM ranked_months
    WHERE month_rank = 1
),
drink_counts AS (
    SELECT
        YEAR(o.order_date) AS sales_year,
        MONTH(o.order_date) AS sales_month,
        d.drink_category_name,
        COUNT(*) AS total_orders,
        RANK() OVER (
            PARTITION BY YEAR(o.order_date), MONTH(o.order_date)
            ORDER BY COUNT(*) DESC
        ) AS drink_rank
    FROM orders o
    JOIN cart_details c
        ON o.order_id = c.order_id
    JOIN drink_category_lookup d
        ON c.drink_category_id = d.drink_category_id
    GROUP BY
        YEAR(o.order_date),
        MONTH(o.order_date),
        d.drink_category_name
),
top_drink_per_month AS (
    SELECT
        sales_year,
        sales_month,
        drink_category_name,
        total_orders
    FROM drink_counts
    WHERE drink_rank = 1
)
SELECT
    t.sales_year AS year,
    t.month_name AS top_selling_month,
    t.total_sales,
    t.avg_customer_spend,
    d.drink_category_name AS most_preferred_drink
FROM top_month_per_year t
JOIN top_drink_per_month d
    ON t.sales_year = d.sales_year
   AND t.sales_month = d.sales_month
ORDER BY t.sales_year;

#2
SELECT 
    s.store_id,
    s.region,
    s.store_location_type,
    ROUND(SUM(o.total_spend), 2) AS store_revenue
FROM store s
JOIN orders o
    ON s.store_id = o.store_id
GROUP BY 
    s.store_id, 
    s.region, 
    s.store_location_type
HAVING SUM(o.total_spend) > (
    SELECT AVG(store_total)
    FROM (
        SELECT 
            store_id,
            SUM(total_spend) AS store_total
        FROM orders
        GROUP BY store_id
    ) AS store_avg
)
ORDER BY store_revenue DESC
LIMIT 10;

#3
WITH customer_spending AS (
    SELECT
        customer_id,
        ROUND(SUM(total_spend), 2) AS total_spending
    FROM orders
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_spending,
    CASE
        WHEN total_spending >= 280 THEN 'High Value'
        WHEN total_spending >= 270 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM customer_spending
ORDER BY total_spending DESC
LIMIT 10;

#4
WITH store_satisfaction AS (
    SELECT 
        s.region,
        s.store_id,
        s.store_location_type,
        ROUND(AVG(o.customer_satisfaction), 2) AS avg_satisfaction,
        COUNT(o.order_id) AS total_orders
    FROM store s
    JOIN orders o
        ON s.store_id = o.store_id
    GROUP BY s.region, s.store_id, s.store_location_type
),
ranked_stores AS (
    SELECT 
        region,
        store_id,
        store_location_type,
        avg_satisfaction,
        total_orders,
        RANK() OVER (
            PARTITION BY region
            ORDER BY avg_satisfaction DESC
        ) AS satisfaction_rank
    FROM store_satisfaction
)
SELECT 
    region,
    store_id,
    store_location_type,
    avg_satisfaction,
    total_orders,
    satisfaction_rank
FROM ranked_stores
WHERE satisfaction_rank <= 3
ORDER BY region, satisfaction_rank;

#5
#Before Index

EXPLAIN
SELECT 
    order_id,
    store_id,
    order_date,
    order_ahead,
    fulfillment_time_min,
    customer_satisfaction
FROM orders
WHERE order_ahead = 'True'
  AND fulfillment_time_min > 10
ORDER BY fulfillment_time_min DESC;

#Create Index
CREATE INDEX idx_orderahead_fulfillment
ON orders(order_ahead, fulfillment_time_min);

#After Index
EXPLAIN
SELECT 
    order_id,
    store_id,
    order_date,
    order_ahead,
    fulfillment_time_min,
    customer_satisfaction
FROM orders
WHERE order_ahead = 'True'
  AND fulfillment_time_min > 10
ORDER BY fulfillment_time_min DESC;

GRANT ALL PRIVILEGES ON starbucks_customer_ordering_pattern.* 
TO 'flaskuser'@'127.0.0.1';

GRANT ALL PRIVILEGES ON starbucks_customer_ordering_pattern.* 
TO 'flaskuser'@'localhost';

FLUSH PRIVILEGES;

