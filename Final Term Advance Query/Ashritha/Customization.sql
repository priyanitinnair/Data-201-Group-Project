USE coffee_patterns;

WITH customization_groups AS (
    SELECT
        CASE
            WHEN num_customizations = 0 THEN 'No Customizations'
            WHEN num_customizations BETWEEN 1 AND 2 THEN 'Low Customization'
            WHEN num_customizations BETWEEN 3 AND 4 THEN 'Medium Customization'
            ELSE 'High Customization'
        END AS customization_level,
        COUNT(*) AS total_orders,
        ROUND(SUM(total_spend), 2) AS total_revenue,
        ROUND(AVG(total_spend), 2) AS avg_order_value,
        ROUND(AVG(fulfillment_time_min), 2) AS avg_fulfillment_time,
        ROUND(AVG(customer_satisfaction), 2) AS avg_satisfaction
    FROM orders
    GROUP BY
        CASE
            WHEN num_customizations = 0 THEN 'No Customizations'
            WHEN num_customizations BETWEEN 1 AND 2 THEN 'Low Customization'
            WHEN num_customizations BETWEEN 3 AND 4 THEN 'Medium Customization'
            ELSE 'High Customization'
        END
)

SELECT
    customization_level,
    total_orders,
    total_revenue,
    avg_order_value,
    avg_fulfillment_time,
    avg_satisfaction
FROM customization_groups
ORDER BY
    CASE
        WHEN customization_level = 'No Customizations' THEN 1
        WHEN customization_level = 'Low Customization' THEN 2
        WHEN customization_level = 'Medium Customization' THEN 3
        WHEN customization_level = 'High Customization' THEN 4
    END;
    
    