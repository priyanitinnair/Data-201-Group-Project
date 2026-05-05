
-- ============================================
-- VARUNA VYOMESSH - STARBUCKS PROJECT  
-- DATA 201 - MID SEM SUBMISSION
-- Student ID: 020097194
-- ============================================

USE starbucks_db;

-- ============================================
-- BASIC QUERY 1: Channel Distribution
-- ============================================
-- Business Question: Which ordering channel do customers use most?
-- Expected Output: 4 channels ranked by total order count

SELECT 
    cl.channel_name, 
    COUNT(*) AS total_orders
FROM orders o
JOIN channel_lookup cl ON o.channel_id = cl.channel_id
GROUP BY cl.channel_name
ORDER BY total_orders DESC;

-- Key Finding: Mobile App dominates with 21,104 orders (42%)
-- confirming digital-first strategy is working.


-- ============================================
-- BASIC QUERY 2: Gender Distribution
-- ============================================
-- Business Question: What is the gender distribution of our customer base?
-- Expected Output: Customer counts by gender category

SELECT 
    customer_gender, 
    COUNT(*) AS total_customers
FROM customer
GROUP BY customer_gender
ORDER BY total_customers DESC;

-- Key Finding: Nearly gender-balanced (Female: 6,808, Male: 6,700),
-- with 10% identifying as Non-binary or preferring not to disclose.


-- ============================================
-- BASIC QUERY 3: Age Group Spending Analysis
-- ============================================
-- Business Question: Which age group spends the most per order?
-- Expected Output: Age groups with order counts and average spend

SELECT 
    c.customer_age_group,
    COUNT(*) AS total_orders,
    ROUND(AVG(o.total_spend), 2) AS avg_spend
FROM orders o
JOIN customer c ON o.customer_id = c.customer_id
GROUP BY c.customer_age_group
ORDER BY avg_spend DESC;

-- Key Finding: 25-34 age group leads in both volume (14,719 orders) 
-- and average spend ($15.54), making them the most valuable segment.
