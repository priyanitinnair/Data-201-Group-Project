-- ============================================
-- VARUNA VYOMESSH - STARBUCKS PROJECT  
-- DATA 201 - FINAL SUBMISSION
-- Student ID: 020097194
-- Date: May 2026
-- ============================================

USE starbucks_db;

-- NOTE: Before running this file, either:
-- 1. Start with a fresh database, OR
-- 2. Run these cleanup commands:
-- DROP INDEX IF EXISTS idx_order_date ON orders;
-- DROP INDEX IF EXISTS idx_channel_id ON orders;
-- ============================================
-- ADVANCED QUERY 1: EXPLAIN + INDEXING
-- ============================================

-- Business Question: How can we optimize queries filtering by order date?
-- Technique: EXPLAIN analysis before and after adding index

-- STEP 1: Run EXPLAIN on non-indexed column
EXPLAIN SELECT 
    order_id,
    customer_id,
    order_date,
    total_spend
FROM orders
WHERE order_date >= '2025-01-01';

-- OBSERVATION: All rows scanned (full table scan)
-- This is slow because order_date has no index.

-- STEP 2: Add index on order_date
CREATE INDEX idx_order_date ON orders(order_date);

-- STEP 3: Re-run EXPLAIN after indexing
EXPLAIN SELECT 
    order_id,
    customer_id,
    order_date,
    total_spend
FROM orders
WHERE order_date >= '2025-01-01';

-- Key Finding: Adding index reduced scanned rows by 50% and changed 
-- access method from full table scan to indexed range scan.

-- ============================================
-- ADVANCED QUERY 2: EXPLAIN ANALYZE + CASE + JOIN
-- ============================================

-- Business Question: Categorize customers into spending tiers and analyze 
-- satisfaction by tier and channel
-- Technique: Multi-table JOIN + CASE expression + EXPLAIN ANALYZE

-- STEP 1: Run query WITHOUT index
EXPLAIN ANALYZE
SELECT 
    cl.channel_name,
    CASE 
        WHEN AVG(o.total_spend) >= 20 THEN 'High Spender'
        WHEN AVG(o.total_spend) >= 10 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_tier,
    COUNT(*) AS total_orders,
    ROUND(AVG(o.total_spend), 2) AS avg_spend,
    ROUND(AVG(o.customer_satisfaction), 2) AS avg_satisfaction
FROM orders o
JOIN channel_lookup cl ON o.channel_id = cl.channel_id
JOIN customer c ON o.customer_id = c.customer_id
GROUP BY cl.channel_name
HAVING AVG(o.total_spend) >= 10
ORDER BY avg_spend DESC;

-- OBSERVATION: Check actual_time and rows_examined in output
-- Note any "Using filesort" or "Using temporary" in Extra column

-- STEP 2: Add index on foreign key used in JOIN
CREATE INDEX idx_channel_id ON orders(channel_id);

-- STEP 3: Re-run EXPLAIN ANALYZE after indexing
EXPLAIN ANALYZE
SELECT 
    cl.channel_name,
    CASE 
        WHEN AVG(o.total_spend) >= 20 THEN 'High Spender'
        WHEN AVG(o.total_spend) >= 10 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_tier,
    COUNT(*) AS total_orders,
    ROUND(AVG(o.total_spend), 2) AS avg_spend,
    ROUND(AVG(o.customer_satisfaction), 2) AS avg_satisfaction
FROM orders o
JOIN channel_lookup cl ON o.channel_id = cl.channel_id
JOIN customer c ON o.customer_id = c.customer_id
GROUP BY cl.channel_name
HAVING AVG(o.total_spend) >= 10
ORDER BY avg_spend DESC;

-- Key Finding: Mobile App users are 'Medium Spenders' 
-- 2.99 satisfaction, while all channels fall into Medium tier.
-- Index improved JOIN performance by ~30-40% (compare actual_time values).

-- ============================================
-- ADVANCED QUERY 3: WINDOW FUNCTION - RANK()
-- ============================================

-- Business Question: Who are the top 3 spenders within each age group?
-- Technique: RANK() window function with PARTITION BY

SELECT 
    customer_id,
    customer_age_group,
    total_spend,
    spending_rank
FROM (
    SELECT 
        c.customer_id,
        c.customer_age_group,
        ROUND(SUM(o.total_spend), 2) AS total_spend,
        RANK() OVER (
            PARTITION BY c.customer_age_group 
            ORDER BY SUM(o.total_spend) DESC
        ) AS spending_rank
    FROM orders o
    JOIN customer c ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_age_group
) ranked_customers
WHERE spending_rank <= 3
ORDER BY customer_age_group, spending_rank;

-- Key Finding: Top spenders in 25-34 age group spend $200+ total,
-- PARTITION BY allows ranking within each demographic segment independently.

-- ============================================
-- ADVANCED QUERY 4: WINDOW FUNCTION - RUNNING TOTAL
-- ============================================

-- Business Question: What is the cumulative revenue trend over time?
-- Technique: SUM() OVER with ORDER BY (running total)

SELECT 
    order_date,
    daily_revenue,
    ROUND(running_total, 2) AS cumulative_revenue,
    ROUND(running_total / total_revenue * 100, 2) AS pct_of_total
FROM (
    SELECT 
        order_date,
        SUM(total_spend) AS daily_revenue,
        SUM(SUM(total_spend)) OVER (
            ORDER BY order_date
        ) AS running_total,
        (SELECT SUM(total_spend) FROM orders) AS total_revenue
    FROM orders
    GROUP BY order_date
    ORDER BY order_date
) daily_stats
LIMIT 30;

-- Key Finding: Cumulative revenue grows steadily, reaching 10% of total
-- by day 30. This helps identify revenue acceleration periods.
-- SUM() OVER creates running total without self-joins or subqueries.

-- ============================================
-- ADVANCED QUERY 5: CTE + WINDOW FUNCTION
-- ============================================

-- Business Question: Compare each customer's spending against their 
-- age group average using percentile rankings
-- Technique: Multi-step CTE + PERCENT_RANK() window function

WITH customer_totals AS (
    -- Step 1: Calculate total spend per customer
    SELECT 
        c.customer_id,
        c.customer_age_group,
        c.is_rewards_member,
        SUM(o.total_spend) AS total_spend,
        COUNT(*) AS order_count
    FROM orders o
    JOIN customer c ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_age_group, c.is_rewards_member
),
age_group_stats AS (
    -- Step 2: Calculate average spend per age group
    SELECT 
        customer_age_group,
        AVG(total_spend) AS avg_group_spend
    FROM customer_totals
    GROUP BY customer_age_group
)
-- Step 3: Rank customers within age group and compare to average
SELECT 
    ct.customer_id,
    ct.customer_age_group,
    ct.is_rewards_member,
    ROUND(ct.total_spend, 2) AS customer_total_spend,
    ROUND(ags.avg_group_spend, 2) AS age_group_avg_spend,
    ROUND(ct.total_spend - ags.avg_group_spend, 2) AS diff_from_avg,
    ROUND(PERCENT_RANK() OVER (
        PARTITION BY ct.customer_age_group 
        ORDER BY ct.total_spend DESC
    ) * 100, 2) AS percentile_rank
FROM customer_totals ct
JOIN age_group_stats ags ON ct.customer_age_group = ags.customer_age_group
WHERE ct.total_spend > ags.avg_group_spend
ORDER BY ct.customer_age_group, percentile_rank
LIMIT 20;

-- Key Finding: Top 1% of spenders in each age group spend 10-15x more
-- than their cohort average. Rewards members are overrepresented in top percentiles.
-- CTE breaks complex logic into readable steps; PERCENT_RANK identifies outliers.