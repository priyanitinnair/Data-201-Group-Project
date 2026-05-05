from flask import Flask, render_template
from db import query

app = Flask(__name__)

@app.route("/")
def dashboard():

    least_popular_drink = query("""
        SELECT 
            d.drink_category_name,
            COUNT(*) AS total_orders
        FROM cart_details c
        JOIN drink_category_lookup d
            ON c.drink_category_id = d.drink_category_id
        GROUP BY d.drink_category_name
        ORDER BY total_orders ASC
        LIMIT 1;
    """)

    orders_by_channel = query("""
        SELECT 
            c.channel_name,
            COUNT(o.order_id) AS total_orders
        FROM orders o
        JOIN channel_lookup c
            ON o.channel_id = c.channel_id
        GROUP BY c.channel_name
        ORDER BY total_orders DESC;
    """)

    revenue_by_location = query("""
        SELECT 
            s.store_location_type,
            COUNT(o.order_id) AS total_orders,
            ROUND(SUM(o.total_spend), 2) AS total_revenue,
            ROUND(AVG(o.total_spend), 2) AS avg_order_value
        FROM store s
        JOIN orders o
            ON s.store_id = o.store_id
        GROUP BY s.store_location_type
        ORDER BY total_revenue DESC;
    """)

    food_vs_spend = query("""
        SELECT 
            CASE 
                WHEN cd.has_food_item = 'True' OR cd.has_food_item = 1 THEN 'Food Item Included'
                ELSE 'Drink Only'
            END AS food_label,
            COUNT(o.order_id) AS total_orders,
            ROUND(AVG(o.total_spend), 2) AS avg_spend,
            ROUND(SUM(o.total_spend), 2) AS total_revenue
        FROM orders o
        JOIN cart_details cd
            ON o.order_id = cd.order_id
        GROUP BY food_label
        ORDER BY avg_spend DESC;
    """)

    fulfillment_by_region = query("""
        SELECT 
            s.region,
            COUNT(o.order_id) AS total_orders,
            ROUND(AVG(o.fulfillment_time_min), 2) AS avg_fulfillment_time,
            ROUND(AVG(o.customer_satisfaction), 2) AS avg_satisfaction
        FROM store s
        JOIN orders o
            ON s.store_id = o.store_id
        GROUP BY s.region
        ORDER BY avg_fulfillment_time DESC;
    """)

    top_month_year = query("""
        WITH monthly_sales AS (
            SELECT
                YEAR(o.order_date) AS sales_year,
                MONTH(o.order_date) AS sales_month,
                MONTHNAME(o.order_date) AS month_name,
                SUM(o.total_spend) AS total_sales,
                AVG(o.total_spend) AS avg_customer_spend
            FROM orders o
            GROUP BY YEAR(o.order_date), MONTH(o.order_date), MONTHNAME(o.order_date)
        ),
        ranked_months AS (
            SELECT
                sales_year,
                sales_month,
                month_name,
                total_sales,
                avg_customer_spend,
                RANK() OVER (
                    PARTITION BY sales_year
                    ORDER BY total_sales DESC
                ) AS month_rank
            FROM monthly_sales
        ),
        top_month_per_year AS (
            SELECT *
            FROM ranked_months
            WHERE month_rank = 1
        ),
        drink_counts AS (
            SELECT
                YEAR(o.order_date) AS sales_year,
                MONTH(o.order_date) AS sales_month,
                d.drink_category_name,
                COUNT(*) AS total_orders,
                RANK() OVER (
                    PARTITION BY YEAR(o.order_date), MONTH(o.order_date)
                    ORDER BY COUNT(*) DESC
                ) AS drink_rank
            FROM orders o
            JOIN cart_details c
                ON o.order_id = c.order_id
            JOIN drink_category_lookup d
                ON c.drink_category_id = d.drink_category_id
            GROUP BY YEAR(o.order_date), MONTH(o.order_date), d.drink_category_name
        ),
        top_drink_per_month AS (
            SELECT *
            FROM drink_counts
            WHERE drink_rank = 1
        )
        SELECT
            t.sales_year AS year,
            t.month_name AS top_selling_month,
            ROUND(t.total_sales, 2) AS total_sales,
            ROUND(t.avg_customer_spend, 2) AS avg_customer_spend,
            d.drink_category_name AS most_preferred_drink
        FROM top_month_per_year t
        JOIN top_drink_per_month d
            ON t.sales_year = d.sales_year
           AND t.sales_month = d.sales_month
        ORDER BY t.sales_year;
    """)

    top_stores = query("""
        SELECT 
            s.store_id,
            s.region,
            s.store_location_type,
            ROUND(SUM(o.total_spend), 2) AS store_revenue
        FROM store s
        JOIN orders o
            ON s.store_id = o.store_id
        GROUP BY s.store_id, s.region, s.store_location_type
        HAVING SUM(o.total_spend) > (
            SELECT AVG(store_total)
            FROM (
                SELECT 
                    store_id,
                    SUM(total_spend) AS store_total
                FROM orders
                GROUP BY store_id
            ) AS store_avg
        )
        ORDER BY store_revenue DESC
        LIMIT 10;
    """)

    customer_segments = query("""
        WITH customer_spending AS (
            SELECT
                customer_id,
                ROUND(SUM(total_spend), 2) AS total_spending
            FROM orders
            GROUP BY customer_id
        )
        SELECT
            customer_id,
            total_spending,
            CASE
                WHEN total_spending >= 280 THEN 'High Value'
                WHEN total_spending >= 270 THEN 'Medium Value'
                ELSE 'Low Value'
            END AS customer_segment
        FROM customer_spending
        ORDER BY total_spending DESC
        LIMIT 10;
    """)

    top_satisfaction_stores = query("""
        WITH store_satisfaction AS (
            SELECT 
                s.region,
                s.store_id,
                s.store_location_type,
                ROUND(AVG(o.customer_satisfaction), 2) AS avg_satisfaction,
                COUNT(o.order_id) AS total_orders
            FROM store s
            JOIN orders o
                ON s.store_id = o.store_id
            GROUP BY s.region, s.store_id, s.store_location_type
        ),
        ranked_stores AS (
            SELECT 
                region,
                store_id,
                store_location_type,
                avg_satisfaction,
                total_orders,
                RANK() OVER (
                    PARTITION BY region
                    ORDER BY avg_satisfaction DESC
                ) AS satisfaction_rank
            FROM store_satisfaction
        )
        SELECT *
        FROM ranked_stores
        WHERE satisfaction_rank <= 3
        ORDER BY region, satisfaction_rank;
    """)

    return render_template(
        "dashboard2.html",
        least_popular_drink=least_popular_drink,
        orders_by_channel=orders_by_channel,
        revenue_by_location=revenue_by_location,
        food_vs_spend=food_vs_spend,
        fulfillment_by_region=fulfillment_by_region,
        top_month_year=top_month_year,
        top_stores=top_stores,
        customer_segments=customer_segments,
        top_satisfaction_stores=top_satisfaction_stores
    )

if __name__ == "__main__":
    app.run(debug=True)