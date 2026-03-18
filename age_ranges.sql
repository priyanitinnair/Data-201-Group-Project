USE coffee_patterns;

SELECT customer_age_group, COUNT(*) AS total_orders
FROM starbucks_customer_ordering_patterns
GROUP BY customer_age_group
ORDER BY total_orders DESC