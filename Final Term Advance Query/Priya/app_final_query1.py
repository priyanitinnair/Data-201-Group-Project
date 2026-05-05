from flask import Flask, render_template, jsonify
from db_final_query1 import query 

app = Flask(__name__)
app.config['TEMPLATES_AUTO_RELOAD'] = True

STAT_SQL = """
WITH customer_orders AS (
    SELECT c.customer_id, c.is_rewards_member, cd.cart_size
    FROM customer c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    LEFT JOIN cart_details cd ON o.order_id = cd.order_id
),
distribution_spending AS (
    SELECT is_rewards_member,
    ROUND(AVG(cart_size), 2) AS avg_spend,
    ROUND(STDDEV(cart_size), 2) AS std_dev_spend
    FROM customer_orders
    GROUP BY is_rewards_member
)
SELECT * FROM distribution_spending;
"""

@app.route('/')
def index():
    try:
        # --- PHASE 1: CLEAN UP ---
        try:
            query("ALTER TABLE orders DROP INDEX idx_cust_id_only;")
        except:
            pass 
        
        # --- PHASE 2: NO INDEX (SLOW) ---
        explain_no_index = query(f"EXPLAIN {STAT_SQL}")
        analyze_no_index = query(f"EXPLAIN ANALYZE {STAT_SQL}")

        # --- PHASE 3: WITH INDEX (FAST) ---
        query("CREATE INDEX idx_cust_id_only ON orders(customer_id);")
        analyze_with_index = query(f"EXPLAIN ANALYZE {STAT_SQL}")
        
        # --- PHASE 4: DATA FOR CHART ---
        chart_data = query(STAT_SQL)

        # CRITICAL: Return the template with all variables
        return render_template('final_query1.html', 
                               explain_no_index=explain_no_index,
                               no_index_results=analyze_no_index, 
                               with_index_results=analyze_with_index,
                               chart_data=chart_data)

    except Exception as e:
        return f"Database Error: {e}"

if __name__ == "__main__":
    app.run(debug=True)