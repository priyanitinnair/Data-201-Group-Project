from flask import Flask, render_template_string
import pymysql

app = Flask(__name__)

# Database connection
def get_db_connection():
    return pymysql.connect(
        host='localhost',
        user='root',
        password='',  # Add your password if needed
        database='starbucks_db',
        cursorclass=pymysql.cursors.DictCursor
    )

@app.route('/')
def rankings():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Query with Window Function (RANK)
    query = """
    SELECT 
        customer_id,
        customer_age_group,
        total_spend,
        spending_rank,
        age_group_avg
    FROM (
        SELECT 
            c.customer_id,
            c.customer_age_group,
            ROUND(SUM(o.total_spend), 2) AS total_spend,
            RANK() OVER (
                PARTITION BY c.customer_age_group 
                ORDER BY SUM(o.total_spend) DESC
            ) AS spending_rank,
            ROUND(AVG(SUM(o.total_spend)) OVER (
                PARTITION BY c.customer_age_group
            ), 2) AS age_group_avg
        FROM orders o
        JOIN customer c ON o.customer_id = c.customer_id
        GROUP BY c.customer_id, c.customer_age_group
    ) ranked_customers
    WHERE spending_rank <= 5
    ORDER BY customer_age_group, spending_rank
    """
    
    cursor.execute(query)
    results = cursor.fetchall()
    cursor.close()
    conn.close()
    
    # Organize data by age group
    age_groups = {}
    for row in results:
        age = row['customer_age_group']
        if age not in age_groups:
            age_groups[age] = []
        age_groups[age].append(row)
    
    html = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Top Customer Rankings by Age Group</title>
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        <style>
            body {
                font-family: Arial, sans-serif;
                max-width: 1400px;
                margin: 50px auto;
                padding: 20px;
                background: #f5f5f5;
            }
            h1 {
                color: #00704A;
                text-align: center;
                margin-bottom: 10px;
            }
            .subtitle {
                text-align: center;
                color: #666;
                margin-bottom: 40px;
                font-size: 14px;
            }
            .age-group-section {
                background: white;
                padding: 25px;
                margin-bottom: 30px;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }
            .age-group-title {
                font-size: 20px;
                font-weight: bold;
                color: #00704A;
                margin-bottom: 20px;
                border-bottom: 3px solid #00704A;
                padding-bottom: 10px;
            }
            canvas {
                max-height: 300px;
            }
            .insight {
                background: #e8f5e9;
                padding: 12px;
                margin-top: 15px;
                border-radius: 4px;
                font-size: 14px;
                color: #2e7d32;
            }
        </style>
    </head>
    <body>
        <h1>Top Customer Spending Rankings by Age Group</h1>
        <div class="subtitle">
            SQL Query: RANK() window function with PARTITION BY age group
        </div>
        
        {% for age, customers in age_groups.items() %}
        <div class="age-group-section">
            <div class="age-group-title">Age Group: {{ age }}</div>
            <canvas id="chart_{{ age|replace('-','_')|replace('+','plus') }}"></canvas>
            <div class="insight">
                Top spender: {{ customers[0]['customer_id'] }} with ${{ customers[0]['total_spend'] }}
                ({{ ((customers[0]['total_spend'] / customers[0]['age_group_avg'] - 1) * 100)|round(1) }}% above age group average)
            </div>
        </div>
        {% endfor %}
        
        <script>
        {% for age, customers in age_groups.items() %}
            const ctx_{{ age|replace('-','_')|replace('+','plus') }} = document.getElementById('chart_{{ age|replace('-','_')|replace('+','plus') }}').getContext('2d');
            new Chart(ctx_{{ age|replace('-','_')|replace('+','plus') }}, {
                type: 'bar',
                data: {
                    labels: {{ customers|map(attribute='customer_id')|list|tojson }},
                    datasets: [{
                        label: 'Total Spend ($)',
                        data: {{ customers|map(attribute='total_spend')|list|tojson }},
                        backgroundColor: 'rgba(0, 112, 74, 0.6)',
                        borderColor: 'rgba(0, 112, 74, 1)',
                        borderWidth: 2
                    }, {
                        label: 'Age Group Average',
                        data: Array({{ customers|length }}).fill({{ customers[0]['age_group_avg'] }}),
                        type: 'line',
                        borderColor: 'rgba(255, 99, 132, 1)',
                        borderWidth: 2,
                        borderDash: [5, 5],
                        fill: false,
                        pointRadius: 0
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: true,
                    scales: {
                        y: {
                            beginAtZero: true,
                            ticks: {
                                callback: function(value) {
                                    return '$' + value;
                                }
                            }
                        }
                    }
                }
            });
        {% endfor %}
        </script>
    </body>
    </html>
    """
    
    return render_template_string(html, age_groups=age_groups)

if __name__ == '__main__':
    app.run(debug=True, port=5002)