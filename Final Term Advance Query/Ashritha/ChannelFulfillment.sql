USE coffee_patterns;

WITH channel_fulfillment AS (
    SELECT
        oc.order_channel_name,
        COUNT(*) AS total_orders,
        ROUND(SUM(o.total_spend), 2) AS total_revenue,
        ROUND(AVG(o.total_spend), 2) AS avg_order_value,
        ROUND(AVG(o.fulfillment_time_min), 2) AS avg_fulfillment_time,
        ROUND(AVG(o.customer_satisfaction), 2) AS avg_satisfaction
    FROM orders o
    JOIN order_channels oc
        ON o.order_channel_id = oc.order_channel_id
    GROUP BY
        oc.order_channel_name
)

SELECT
    order_channel_name,
    total_orders,
    total_revenue,
    avg_order_value,
    avg_fulfillment_time,
    avg_satisfaction,
    RANK() OVER (
        ORDER BY avg_fulfillment_time ASC
    ) AS speed_rank,
    RANK() OVER (
        ORDER BY avg_satisfaction DESC
    ) AS satisfaction_rank
FROM channel_fulfillment
ORDER BY speed_rank;