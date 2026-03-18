USE coffee_patterns;

WITH age_group_spend AS (
	SELECT customer_age_group, AVG(total_spend) AS average_spendings
    FROM starbucks_customer_ordering_patterns
    GROUP BY customer_age_group
),
ranked_age_groups AS (
	SELECT 
		customer_age_group, 
        average_spendings,
        RANK () OVER (ORDER BY average_spendings DESC) AS rank_spend
	FROM age_group_spend
)
SELECT customer_age_group, average_spendings
FROM ranked_age_groups
WHERE rank_spend = 1