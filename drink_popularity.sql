USE coffee_patterns;

SELECT drink_category, COUNT(*) AS total_orders
FROM starbucks_customer_ordering_patterns
GROUP BY drink_category
ORDER BY total_orders DESC