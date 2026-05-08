USE coffee_patterns;

WITH food_impact AS (
    SELECT
        dc.drink_category_name,
        o.has_food_item,
        COUNT(*) AS total_orders,
        ROUND(SUM(o.total_spend), 2) AS total_revenue,
        ROUND(AVG(o.total_spend), 2) AS avg_order_value,
        ROUND(AVG(o.customer_satisfaction), 2) AS avg_satisfaction
    FROM orders o
    JOIN drink_categories dc
        ON o.drink_category_id = dc.drink_category_id
    GROUP BY 
        dc.drink_category_name,
        o.has_food_item
)

SELECT
    drink_category_name,
    CASE 
        WHEN has_food_item = 1 THEN 'With Food'
        ELSE 'Drink Only'
    END AS order_type,
    total_orders,
    total_revenue,
    avg_order_value,
    avg_satisfaction
FROM food_impact
ORDER BY 
    drink_category_name,
    avg_order_value DESC;