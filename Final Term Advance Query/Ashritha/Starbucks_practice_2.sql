USE coffee_patterns;

WITH channel_revenue AS (
	SELECT s.region, oc.order_channel_name, SUM(o.total_spend) AS total_rev
    FROM orders o
    JOIN stores s
    ON o.store_id = s.store_id
    JOIN order_channels oc
    ON o.order_channel_id = oc.order_channel_id
    GROUP BY s.region, oc.order_channel_name
)
SELECT 
	region, 
    order_channel_name, 
    total_rev,
    RANK() OVER (
		PARTITION BY region
        ORDER BY total_rev DESC
	) AS rev_rank
FROM channel_revenue;

