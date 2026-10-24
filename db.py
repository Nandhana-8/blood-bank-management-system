#!/usr/bin/env python3
"""
Blood Bank Management System (BBMS) - Database Connection Module
Connects Flask to MySQL using mysql-connector-python and credentials loaded from .env
"""

import os
import mysql.connector
from mysql.connector import Error, errorcode
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# MySQL Database Configuration
MYSQL_HOST = os.getenv('MYSQL_HOST', 'localhost')
MYSQL_PORT = int(os.getenv('MYSQL_PORT', 3306))
MYSQL_USER = os.getenv('MYSQL_USER', 'root')
MYSQL_PASSWORD = os.getenv('MYSQL_PASSWORD', '')
MYSQL_DB = os.getenv('MYSQL_DB', 'blood_bank_db')

def get_connection():
    """
    Creates and returns a connection to the MySQL database using mysql-connector-python.
    """
    try:
        connection = mysql.connector.connect(
            host=MYSQL_HOST,
            port=MYSQL_PORT,
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            database=MYSQL_DB,
            charset='utf8mb4',
            collation='utf8mb4_unicode_ci',
            autocommit=False
        )
        return connection
    except mysql.connector.Error as err:
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
            msg = "MySQL Authentication Error: Invalid username or password."
        elif err.errno == errorcode.ER_BAD_DB_ERROR:
            msg = f"MySQL Database Error: Database '{MYSQL_DB}' does not exist. Please run initialization script."
        else:
            msg = f"MySQL Connection Error [{err.errno}]: {err.msg}"
        print(f"[DB ERROR] {msg}")
        raise RuntimeError(msg) from err

def test_connection():
    """
    Verifies MySQL connectivity and returns status along with existing tables.
    """
    conn = get_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT VERSION() AS version, CURRENT_USER() AS user, DATABASE() AS database_name;")
        server_info = cursor.fetchone()

        cursor.execute("SHOW FULL TABLES WHERE Table_type = 'BASE TABLE';")
        tables = [list(r.values())[0] for r in cursor.fetchall()]

        cursor.execute("SHOW FULL TABLES WHERE Table_type = 'VIEW';")
        views = [list(r.values())[0] for r in cursor.fetchall()]

        cursor.close()
        return {
            'status': 'connected',
            'host': f"{MYSQL_HOST}:{MYSQL_PORT}",
            'database': server_info.get('database_name', MYSQL_DB),
            'version': server_info.get('version', 'Unknown'),
            'user': server_info.get('user', MYSQL_USER),
            'tables': tables,
            'views': views
        }
    finally:
        conn.close()

def execute_query(sql, params=(), commit=False, fetch_one=False, fetch_all=True, return_last_id=False):
    """
    Executes a SQL statement using a dictionary cursor.
    Parameters:
      - sql: Query string
      - params: Tuple of query parameters
      - commit: If True, commits the transaction
      - fetch_one: If True, returns a single dictionary row
      - fetch_all: If True, returns a list of dictionary rows
      - return_last_id: If True and commit=True, returns cursor.lastrowid
    """
    conn = get_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(sql, params)

        if commit:
            conn.commit()
            if return_last_id:
                last_id = cursor.lastrowid
                cursor.close()
                return last_id
            affected = cursor.rowcount
            cursor.close()
            return affected

        if fetch_one:
            result = cursor.fetchone()
            cursor.close()
            return result

        if fetch_all:
            result = cursor.fetchall()
            cursor.close()
            return result

        cursor.close()
        return None
    except Exception as e:
        if commit:
            try:
                conn.rollback()
            except Exception:
                pass
        raise e
    finally:
        conn.close()

def call_procedure(proc_name, params=()):
    """
    Calls a MySQL stored procedure and returns its output parameters and result sets.
    """
    conn = get_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        out_params = cursor.callproc(proc_name, params)
        conn.commit()

        # Capture any result sets returned by the procedure (e.g. from cursors/SELECTs)
        results = []
        for result in cursor.stored_results():
            results.extend(result.fetchall())

        cursor.close()
        return {
            'out_params': out_params,
            'results': results
        }
    except Exception as e:
        try:
            conn.rollback()
        except Exception:
            pass
        raise e
    finally:
        conn.close()
