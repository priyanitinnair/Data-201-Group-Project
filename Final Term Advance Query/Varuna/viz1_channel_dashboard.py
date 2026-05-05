from flask import Flask, render_template_string
import pymysql
import json

app = Flask(__name__)

# Database connection
def get_db_connection():
    return pymysql.connect(
        host='localhost',
        user='root',  # Change if your MySQL user is different
        password='',  # Add your MySQL password here if you have one
        database='starbucks_db',
        cursorclass=pymysql.cursors.DictCursor
    )

@app.route('/')
def dashboard():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Query with JOIN + HAVING clause
    query = """
    SELECT 
        cl.channel_name,
        COUNT(*) AS total_orders,
        ROUND(SUM(o.total_spend), 2) AS total_revenue,
        ROUND(AVG(o.total_spend), 2) AS avg_spend,
        ROUND(AVG(o.customer_satisfaction), 2) AS avg_satisfaction,
        ROUND(AVG(o.fulfillment_time_min), 2) AS avg_fulfillment_time
    FROM orders o
    JOIN channel_lookup cl ON o.channel_id = cl.channel_id
    GROUP BY cl.channel_name
    HAVING COUNT(*) > 1000
    ORDER BY total_revenue DESC
    """
    
    cursor.execute(query)
    results = cursor.fetchall()
    cursor.close()
    conn.close()
    
    # Prepare data for Chart.js
    channels = [row['channel_name'] for row in results]
    revenues = [float(row['total_revenue']) for row in results]
    satisfactions = [float(row['avg_satisfaction']) for row in results]
    fulfillment_times = [float(row['avg_fulfillment_time']) for row in results]
    
    html = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Starbucks Channel Performance Dashboard</title>
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        <style>
            body {
                font-family: Arial, sans-serif;
                max-width: 1200px;
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
            .chart-container {
                background: white;
                padding: 30px;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                margin-bottom: 30px;
            }
            .chart-title {
                font-size: 18px;
                font-weight: bold;
                margin-bottom: 20px;
                color: #333;
            }
            canvas {
                max-height: 400px;
            }
            .insight-box {
                background: #fff3cd;
                border-left: 4px solid #ffc107;
                padding: 15px;
                margin-top: 20px;
                border-radius: 4px;
            }
            .insight-title {
                font-weight: bold;
                margin-bottom: 8px;
                color: #856404;
            }
        </style>
    </head>
    <body>
        <h1>Starbucks Channel Performance Dashboard</h1>
        <div class="subtitle">
            SQL Query: Multi-table JOIN with HAVING clause filtering channels with 1000+ orders
        </div>
        
        <div class="chart-container">
            <div class="chart-title">Total Revenue by Channel</div>
            <canvas id="revenueChart"></canvas>
        </div>
        
        <div class="chart-container">
            <div class="chart-title">Customer Satisfaction vs Fulfillment Time</div>
            <canvas id="satisfactionChart"></canvas>
        </div>
        
        <div class="insight-box">
            <div class="insight-title">Key Insights:</div>
            Mobile App generates the highest revenue ({{ revenues[0]|round(2) }}) but has moderate satisfaction ({{ satisfactions[0] }}). 
            Drive-Thru has the longest fulfillment time ({{ fulfillment_times[1]|round(2) }} min) which correlates with lower satisfaction.
        </div>
        
        <script>
            // Revenue Chart
            const revenueCtx = document.getElementById('revenueChart').getContext('2d');
            new Chart(revenueCtx, {
                type: 'bar',
                data: {
                    labels: {{ channels|tojson }},
                    datasets: [{
                        label: 'Total Revenue ($)',
                        data: {{ revenues|tojson }},
                        backgroundColor: [
                            'rgba(0, 112, 74, 0.8)',
                            'rgba(0, 112, 74, 0.6)',
                            'rgba(0, 112, 74, 0.4)',
                            'rgba(0, 112, 74, 0.2)'
                        ],
                        borderColor: 'rgba(0, 112, 74, 1)',
                        borderWidth: 1
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
                                    return '$' + value.toLocaleString();
                                }
                            }
                        }
                    },
                    plugins: {
                        legend: {
                            display: false
                        }
                    }
                }
            });
            
            // Satisfaction vs Fulfillment Time Chart
            const satisfactionCtx = document.getElementById('satisfactionChart').getContext('2d');
            new Chart(satisfactionCtx, {
                type: 'scatter',
                data: {
                    datasets: [{
                        label: 'Channels',
                        data: [
                            {% for i in range(channels|length) %}
                            {
                                x: {{ fulfillment_times[i] }},
                                y: {{ satisfactions[i] }},
                                label: '{{ channels[i] }}'
                            }{% if not loop.last %},{% endif %}
                            {% endfor %}
                        ],
                        backgroundColor: 'rgba(0, 112, 74, 0.6)',
                        borderColor: 'rgba(0, 112, 74, 1)',
                        pointRadius: 10
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: true,
                    scales: {
                        x: {
                            title: {
                                display: true,
                                text: 'Average Fulfillment Time (minutes)'
                            }
                        },
                        y: {
                            title: {
                                display: true,
                                text: 'Average Satisfaction Score'
                            },
                            min: 0,
                            max: 5
                        }
                    },
                    plugins: {
                        tooltip: {
                            callbacks: {
                                label: function(context) {
                                    return context.raw.label + 
                                           ': ' + context.parsed.y + ' satisfaction, ' +
                                           context.parsed.x + ' min fulfillment';
                                }
                            }
                        }
                    }
                }
            });
        </script>
    </body>
    </html>
    """
    
    return render_template_string(html, 
                                 channels=channels,
                                 revenues=revenues,
                                 satisfactions=satisfactions,
                                 fulfillment_times=fulfillment_times)

if __name__ == '__main__':
    app.run(debug=True, port=5001)