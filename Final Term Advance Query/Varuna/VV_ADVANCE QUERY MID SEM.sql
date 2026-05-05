
-- ============================================
-- VARUNA VYOMESSH - STARBUCKS PROJECT  
-- DATA 201 - MID SEM SUBMISSION
-- Student ID: 020097194
-- ============================================

-- NOTE: To re-run this file:
-- DROP VIEW IF EXISTS underperforming_orders;

USE starbucks_db;

-- ============================================
-- ADVANCED QUERY 1: VIEW + Subqueries
-- ============================================
-- Business Question: Which channels have above-average wait times 
-- and below-average satisfaction?
-- Technique: CREATE VIEW with multi-table JOIN + subqueries for dynamic thresholds

-- STEP 1: Create reusable VIEW
CREATE OR REPLACE VIEW underperforming_orders AS
SELECT
    o.order_id,
    c.customer_id,
    o.total_spend,
    o.fulfillment_time_min,
    o.customer_satisfaction,
    cl.channel_name
FROM orders o
JOIN customer c ON o.customer_id = c.customer_id
JOIN channel_lookup cl ON o.channel_id = cl.channel_id;

-- STEP 2: Query the VIEW with dynamic thresholds
SELECT
    channel_name,
    COUNT(*) AS underperforming_count,
    ROUND(AVG(total_spend), 2) AS avg_spend,
    ROUND(AVG(fulfillment_time_min), 2) AS avg_fulfillment_time,
    ROUND(AVG(customer_satisfaction), 2) AS avg_satisfaction
FROM underperforming_orders
WHERE fulfillment_time_min > (
    SELECT AVG(fulfillment_time_min) FROM orders
)
AND customer_satisfaction < (
    SELECT AVG(customer_satisfaction) FROM orders
)
GROUP BY channel_name
ORDER BY underperforming_count DESC;

-- Key Finding: Drive-Thru leads with 5,031 underperforming orders 
-- and lowest satisfaction (2.22/5), making it the biggest operational risk.


-- ============================================
-- ADVANCED QUERY 2: Chained CTEs
-- ============================================
-- Business Question: Who are the most valuable customers 
-- (above-average spend AND satisfaction)?
-- Technique: Multi-step CTEs with dual filtering conditions

WITH avg_metrics AS (
    -- Step 1: Calculate overall benchmarks
    SELECT
        ROUND(AVG(total_spend), 2) AS avg_spend,
        ROUND(AVG(customer_satisfaction), 2) AS avg_satisfaction
    FROM orders
),
customer_metrics AS (
    -- Step 2: Calculate per-customer totals
    SELECT
        c.customer_id,
        ROUND(SUM(o.total_spend), 2) AS total_spend,
        ROUND(AVG(o.customer_satisfaction), 2) AS avg_satisfaction
    FROM orders o
    JOIN customer c ON o.customer_id = c.customer_id
    GROUP BY c.customer_id
)
-- Step 3: Filter customers exceeding BOTH benchmarks
SELECT
    cm.customer_id,
    cm.total_spend,
    cm.avg_satisfaction,
    am.avg_spend AS benchmark_spend,
    am.avg_satisfaction AS benchmark_satisfaction
FROM customer_metrics cm, avg_metrics am
WHERE cm.total_spend > am.avg_spend
AND cm.avg_satisfaction > am.avg_satisfaction
ORDER BY cm.total_spend DESC
LIMIT 10;

-- Key Finding: CUST_14910 leads with $206.06 total spend 
-- and 4.00 satisfaction, nearly 14x the benchmark spend of $14.83.
-- All top 10 customers score between 3.70-4.20 satisfaction.