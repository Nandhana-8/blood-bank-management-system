#!/usr/bin/env python3
"""
Blood Bank Management System (BBMS) - Database Setup and Initialization Script
Executes all required SQL files in proper order:
1. schema.sql      (DDL: Database, tables, constraints, indexes)
2. sample_data.sql (DML: Realistic records for all tables)
3. views.sql       (Views: donor_details_view, blood_stock_view, donation_history_view, blood_requests_view)
4. functions.sql   (Stored Functions: fn_get_available_units, fn_get_stock_status_label, fn_check_stock_availability)
5. triggers.sql    (Triggers: inventory sync, donor last_donation_date update, safe decrement/deletion)
6. procedures.sql  (Stored Procedures: record donation, update stock, donor profile, fulfill request)
7. cursor_demo.sql (Cursor Stored Procedure: sp_blood_stock_audit_cursor)
"""

import os
import sys
import shutil
import subprocess
import mysql.connector
from dotenv import load_dotenv

load_dotenv()

MYSQL_HOST = os.getenv('MYSQL_HOST', 'localhost')
MYSQL_PORT = int(os.getenv('MYSQL_PORT', 3306))
MYSQL_USER = os.getenv('MYSQL_USER', 'root')
MYSQL_PASSWORD = os.getenv('MYSQL_PASSWORD', '')
MYSQL_DB = os.getenv('MYSQL_DB', 'blood_bank_db')

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

SQL_FILES = [
    'schema.sql',
    'sample_data.sql',
    'views.sql',
    'functions.sql',
    'triggers.sql',
    'procedures.sql',
    'cursor_demo.sql'
]

def find_mysql_cli():
    """Locate the mysql CLI executable on the system."""
    cli = shutil.which('mysql')
    if cli:
        return cli
    
    # Common Windows paths
    candidates = [
        r"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe",
        r"C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe",
        r"C:\Program Files (x86)\MySQL\MySQL Server 8.0\bin\mysql.exe",
        r"C:\xampp\mysql\bin\mysql.exe",
        r"C:\wamp64\bin\mysql\mysql8.0.34\bin\mysql.exe"
    ]
    for path in candidates:
        if os.path.exists(path):
            return path
    return None

def execute_with_cli(mysql_exe, file_path):
    """Executes a SQL file via mysql CLI to handle complex DELIMITER and routines."""
    cmd = [
        mysql_exe,
        f"--host={MYSQL_HOST}",
        f"--port={MYSQL_PORT}",
        f"--user={MYSQL_USER}",
        f"--password={MYSQL_PASSWORD}",
        "--default-character-set=utf8mb4",
        MYSQL_DB
    ]
    with open(file_path, 'r', encoding='utf-8') as f:
        sql_content = f.read()

    proc = subprocess.run(
        cmd,
        input=sql_content,
        text=True,
        capture_output=True
    )
    if proc.returncode != 0:
        # Ignore insecure password warnings
        err = proc.stderr
        filtered_lines = [l for l in err.splitlines() if "Using a password on the command line interface can be insecure" not in l]
        if filtered_lines:
            raise RuntimeError("\n".join(filtered_lines))
    return True

def run_init():
    print("=" * 75)
    print(" BLOOD BANK MANAGEMENT SYSTEM - DATABASE INITIALIZER")
    print("=" * 75)
    print(f"Connecting to MySQL at {MYSQL_HOST}:{MYSQL_PORT} as user '{MYSQL_USER}'...")

    try:
        # Step 1: Ensure blood_bank_db exists
        server_conn = mysql.connector.connect(
            host=MYSQL_HOST,
            port=MYSQL_PORT,
            user=MYSQL_USER,
            password=MYSQL_PASSWORD
        )
        server_cursor = server_conn.cursor()
        server_cursor.execute(f"CREATE DATABASE IF NOT EXISTS `{MYSQL_DB}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;")
        server_cursor.close()
        server_conn.close()
        print(f"[OK] Database '{MYSQL_DB}' confirmed.")

        # Step 2: Locate CLI or fallback
        mysql_exe = find_mysql_cli()
        if mysql_exe:
            print(f"[OK] Using MySQL CLI at: {mysql_exe}")
            for sql_file in SQL_FILES:
                file_path = os.path.join(BASE_DIR, sql_file)
                print(f"Executing: {sql_file}...")
                execute_with_cli(mysql_exe, file_path)
                print(f"  [SUCCESS] {sql_file} executed successfully.")
        else:
            print("[NOTICE] MySQL CLI not found in PATH; executing via mysql-connector-python...")
            conn = mysql.connector.connect(
                host=MYSQL_HOST,
                port=MYSQL_PORT,
                user=MYSQL_USER,
                password=MYSQL_PASSWORD,
                database=MYSQL_DB
            )
            cursor = conn.cursor()
            for sql_file in SQL_FILES:
                file_path = os.path.join(BASE_DIR, sql_file)
                print(f"Executing: {sql_file}...")
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                for result in cursor.execute(content, multi=True):
                    pass
                conn.commit()
                print(f"  [SUCCESS] {sql_file} executed successfully.")
            cursor.close()
            conn.close()

        # Step 3: Verify all database objects
        print("\n" + "=" * 75)
        print(" DATABASE VERIFICATION SUMMARY")
        print("=" * 75)
        conn = mysql.connector.connect(
            host=MYSQL_HOST,
            port=MYSQL_PORT,
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            database=MYSQL_DB
        )
        cursor = conn.cursor(dictionary=True)

        expected_tables = ['blood_groups', 'blood_stock', 'donors', 'donations', 'blood_requests']
        print("\n  Base Tables:")
        for tbl in expected_tables:
            cursor.execute(f"SELECT COUNT(*) AS c FROM `{tbl}`;")
            cnt = cursor.fetchone()['c']
            print(f"    - {tbl:<20} : {cnt} records")

        expected_views = ['donor_details_view', 'blood_stock_view', 'donation_history_view', 'blood_requests_view']
        print("\n  Views:")
        for view in expected_views:
            cursor.execute(f"SELECT COUNT(*) AS c FROM `{view}`;")
            cnt = cursor.fetchone()['c']
            print(f"    - {view:<22} : Functional ({cnt} rows returned)")

        # Verify stored function
        cursor.execute("SELECT fn_get_available_units(1) AS units, fn_get_stock_status_label(fn_get_available_units(1)) AS label;")
        fn_res = cursor.fetchone()
        print(f"\n  Stored Function Test  : fn_get_available_units(1) = {fn_res['units']} units ({fn_res['label']})")

        # Verify cursor stored procedure
        cursor.callproc('sp_blood_stock_audit_cursor')
        cursor_rows = []
        for res in cursor.stored_results():
            cursor_rows.extend(res.fetchall())
        print(f"  Cursor Procedure Test : sp_blood_stock_audit_cursor() returned {len(cursor_rows)} audited groups.")

        cursor.close()
        conn.close()

        print("\n[READY] All MySQL objects are created, synchronized, and operational!")
        return True

    except Exception as e:
        print(f"\n[FATAL ERROR] Initialization failed: {e}")
        return False

if __name__ == '__main__':
    ok = run_init()
    if not ok:
        sys.exit(1)
