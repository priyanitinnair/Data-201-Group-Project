import pymysql

def get_connection():
    return pymysql.connect(
        host="127.0.0.1",
        port=3306,
        user="flaskuser",
        password="flaskpass123",
        database="starbucks_customer_ordering_pattern",
        cursorclass=pymysql.cursors.DictCursor
    )

def query(sql, params=None):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            return cur.fetchall()
    finally:
        conn.close()