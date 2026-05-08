USE coffee_patterns;

WITH rewards_age_summary AS (
    SELECT
        c.customer_age_group,
        c.is_rewards_member,
        COUNT(*) AS total_orders,
        ROUND(SUM(o.total_spend), 2) AS total_revenue,
        ROUND(AVG(o.total_spend), 2) AS avg_order_value,
        ROUND(AVG(o.customer_satisfaction), 2) AS avg_satisfaction
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    GROUP BY
        c.customer_age_group,
        c.is_rewards_member
)

SELECT
    customer_age_group,
    CASE
        WHEN is_rewards_member = 1 THEN 'Rewards Member'
        ELSE 'Non-Rewards Member'
    END AS membership_status,
    total_orders,
    total_revenue,
    avg_order_value,
    avg_satisfaction
FROM rewards_age_summary
ORDER BY
    customer_age_group,
    total_revenue DESC;