USE coffee_patterns;

SELECT region, COUNT(*) AS total_orders
FROM starbucks_customer_ordering_patterns
GROUP BY region
ORDER BY total_orders DESC