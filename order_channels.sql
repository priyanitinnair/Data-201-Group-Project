USE coffee_patterns;

SELECT order_channel, COUNT(*) AS total_orders
FROM starbucks_customer_ordering_patterns
GROUP BY order_channel
ORDER BY total_orders DESC