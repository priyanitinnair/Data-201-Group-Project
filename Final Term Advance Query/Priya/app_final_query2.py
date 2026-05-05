from flask import Flask, render_template
from db_final_query2 import query  # Importing your existing helper function

app = Flask(__name__)
app.config['TEMPLATES_AUTO_RELOAD'] = True

@app.route('/')
def index():
    # SQL query to analyze spending habits and consistency
    # This calculates average spend and standard deviation (volatility) per group
    sql_query = """
    Select customer_id,order_id,order_date,
Lag(order_date) Over (Partition By customer_id Order By order_date) As previous_order,
DATEDIFF(
order_date,
Lag(order_date) OVER(Partition BY customer_id 
Order BY order_date)
) AS days_between_orders
FROM orders
    """
    
    # Execute the analysis using your db.py helper
    chart_data = query(sql_query)
    
    # Pass the data to your template for visualization
    return render_template('final_query2.html', chart_data=chart_data)

if __name__ == '__main__':
    app.run(debug=True)