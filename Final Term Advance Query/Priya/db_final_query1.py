
import pymysql

def get_connection():
    return pymysql.connect(
        host="127.0.0.1",
        port=3306,
        user="root",
        password="ved0331", 
        database="starbucks coffee",  # <-- UPDATED to match your project
        cursorclass=pymysql.cursors.DictCursor
    )

def query(sql, params=None):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            # For EXPLAIN ANALYZE, fetchall() will return a list 
            # containing the long execution string.
            return cur.fetchall()
    finally:
        conn.close()

