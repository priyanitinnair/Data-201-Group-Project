-- ============================================
-- Name: Priya Nair | SJSU ID: 020057596
-- Project: 3 Basic and 6 Advanced SQL Queries (Final Term SQL Project) 
-- ============================================

-- ============================================
-- 3 Basic Queries  
-- ============================================

-- ============================================
--  Question 1
-- ============================================

Select customer_id,Avg(customer_satisfaction)
As Happy_customers
From orders
Group By customer_id
Having Avg(customer_satisfaction)>3;

-- ============================================
--  Question 2
-- ============================================

Select c.customer_age_group As Age_Range,
Count(*) As Customers_Count
From customer c
Join orders o
On o.customer_id=c.customer_id
Where o.total_spend>10
Group By c.customer_age_group
Order By Age_Range;

-- ============================================
--  Question 3
-- ============================================

Select c.customer_id,Count(*) As Order_Day_count,
o.day_of_week
From customer c
Join orders o
On c.customer_id=o.customer_id
Group By c.customer_id,o.day_of_week;

-- ============================================
-- 6 Advanced Queries  
-- ============================================

-- ============================================
-- Question 1
-- ============================================

WITH customer_orders As (
Select 
c.customer_id,
c.is_rewards_member,
o.order_id,
cd.cart_size,
cd.num_customizations,
c1.channel_name
From customer c
Left Join orders o
On c.customer_id=o.customer_id
Left Join cart_details cd
On o.order_id=cd.order_id
Left Join channel_lookup c1
On o.channel_id=c1.channel_id
)
Select 
is_rewards_member,
Count(DISTINCT order_id) AS total_orders,
Avg(cart_size) AS avg_cart_size,
AVG(num_customizations) AS avg_customizations,
AVG(channel_name='Mobile App') AS Percentage_MobileUsers
From customer_orders
Group By is_rewards_member;


-- ============================================
-- Question 2
-- ============================================

WITH customer_orders AS (
    SELECT
        c.customer_id,
        c.is_rewards_member,
        cd.cart_size
    FROM customer c
    LEFT JOIN orders o
        ON c.customer_id = o.customer_id
    LEFT JOIN cart_details cd
        ON o.order_id = cd.order_id
),

distribution_spending AS (
    SELECT
        is_rewards_member,
        ROUND(AVG(cart_size), 2) AS avg_spend,
        ROUND(STDDEV(cart_size), 2) AS std_dev_spend,
        ROUND(STDDEV(cart_size) / AVG(cart_size), 2) AS coefficient_of_variation
    FROM customer_orders
    GROUP BY is_rewards_member
)

SELECT *
FROM distribution_spending;


-- ============================================
-- (Running EXPLAIN and EXPLAIN ANALYZE without INDEX on Q1)
-- ============================================


EXPLAIN FORMAT = TRADITIONAL
WITH customer_orders AS (
    SELECT
        c.customer_id,
        c.is_rewards_member,
        cd.cart_size
    FROM customer c
    LEFT JOIN orders o
        ON c.customer_id = o.customer_id
    LEFT JOIN cart_details cd
        ON o.order_id = cd.order_id
),

distribution_spending AS (
    SELECT
        is_rewards_member,
        ROUND(AVG(cart_size), 2) AS avg_spend,
        ROUND(STDDEV(cart_size), 2) AS std_dev_spend,
        ROUND(STDDEV(cart_size) / AVG(cart_size), 2) AS coefficient_of_variation
    FROM customer_orders
    GROUP BY is_rewards_member
)

SELECT *
FROM distribution_spending;


EXPLAIN ANALYZE
WITH customer_orders AS (
    SELECT
        c.customer_id,
        c.is_rewards_member,
        cd.cart_size
    FROM customer c
    LEFT JOIN orders o
        ON c.customer_id = o.customer_id
    LEFT JOIN cart_details cd
        ON o.order_id = cd.order_id
),

distribution_spending AS (
    SELECT
        is_rewards_member,
        ROUND(AVG(cart_size), 2) AS avg_spend,
        ROUND(STDDEV(cart_size), 2) AS std_dev_spend,
        ROUND(STDDEV(cart_size) / AVG(cart_size), 2) AS coefficient_of_variation
    FROM customer_orders
    GROUP BY is_rewards_member
)

SELECT *
FROM distribution_spending;



-- ============================================
-- Step 2: Index Creation
-- ============================================

CREATE INDEX idx_orders_customer
ON orders(customer_id);

CREATE INDEX idx_details_order
ON cart_details(order_id);

CREATE INDEX idx_cart_size
ON cart_details(cart_size);

CREATE INDEX idx_member_status
ON customer(is_rewards_member);



-- ============================================
-- Step 4: RUNNING EXPLAIN ANALYZE WTIH INDEX
-- ============================================

EXPLAIN ANALYZE
WITH customer_orders AS (
    SELECT
        c.customer_id,
        c.is_rewards_member,
        cd.cart_size
    FROM customer c
    LEFT JOIN orders o
        ON c.customer_id = o.customer_id
    LEFT JOIN cart_details cd
        ON o.order_id = cd.order_id
),

distribution_spending AS (
    SELECT
        is_rewards_member,
        ROUND(AVG(cart_size), 2) AS avg_spend,
        ROUND(STDDEV(cart_size), 2) AS std_dev_spend,
        ROUND(STDDEV(cart_size) / AVG(cart_size), 2) AS coefficient_of_variation
    FROM customer_orders
    GROUP BY is_rewards_member
)

SELECT *
FROM distribution_spending;

-- ============================================
-- Question 3
-- ============================================

Select 
c.customer_id,
c.is_rewards_member,
CASE
When c.is_rewards_member=1 Then 'Loyal Member'
When Count(o.order_id)>5 And c.is_rewards_member=0 Then 'High Value Rewards Member'
Else 'Casual Non-Member'
End AS loyalty_division
From customer c
Left Join orders o ON c.customer_id=o.customer_id
Group By c.customer_id;

-- ============================================
-- Question 4
-- ============================================


Select customer_id,
order_id,
order_date 
From orders
Where order_id IN (
Select Min(order_id)
From orders
Group By customer_id
);

-- ============================================
-- Question 5
-- ============================================


Select 
c.customer_id,
o.total_spend,
ROW_Number() Over(Partition By o.customer_id Order By o.total_spend DESC) as customer_ranking
From orders o
Join customer c On o.customer_id=c.customer_id;


-- ============================================
-- Question 6
-- ============================================

Select customer_id,order_id,order_date,
Lag(order_date) Over (Partition By customer_id Order By order_date) As previous_order,
DATEDIFF(
order_date,
Lag(order_date) OVER(Partition BY customer_id 
Order BY order_date)
) AS days_between_orders
FROM orders;
