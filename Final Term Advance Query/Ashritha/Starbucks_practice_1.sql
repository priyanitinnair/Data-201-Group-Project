USE coffee_patterns;

WITH category_revenue AS (
	SELECT s.region, dc.drink_category_name, SUM(o.total_spend) AS total_revenue
	FROM orders o
	JOIN stores s
	ON o.store_id = s.store_id
	JOIN drink_categories dc
	ON o.drink_category_id = dc.drink_category_id
	GROUP BY s.region, dc.drink_category_name
)
SELECT 
	region,
    drink_category_name, 
    total_revenue,
    RANK() OVER (
		PARTITION BY region
        ORDER BY total_revenue DESC
	) AS revenue_rank
FROM category_revenue;

