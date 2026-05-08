USE coffee_patterns;

WITH age_channel_revenue AS (
    SELECT
        c.customer_age_group,
        oc.order_channel_name,
        SUM(o.total_spend) AS total_revenue,
        COUNT(*) AS total_orders,
        ROUND(AVG(o.total_spend), 2) AS avg_order_value
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_channels oc
        ON o.order_channel_id = oc.order_channel_id
    GROUP BY
        c.customer_age_group,
        oc.order_channel_name
)

SELECT
    customer_age_group,
    order_channel_name,
    total_revenue,
    total_orders,
    avg_order_value,
    RANK() OVER (
        PARTITION BY customer_age_group
        ORDER BY total_revenue DESC
    ) AS revenue_rank_within_age_group
FROM age_channel_revenue
ORDER BY
    customer_age_group,
    revenue_rank_within_age_group;