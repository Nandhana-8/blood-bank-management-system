#!/usr/bin/env python3
"""
Blood Bank Management System (BBMS) - Interactive Command Line Showcase
Allows presenting and explaining the entire database architecture directly in the terminal.
"""

import os
import sys
import db
# Tabular formatter is implemented natively below

def print_header(title):
    print("\n" + "=" * 70)
    print(f"  {title.upper()}")
    print("=" * 70)

def format_table(rows):
    if not rows:
        print("  (No records found)")
        return
    headers = list(rows[0].keys())
    # Calculate column widths
    widths = {h: len(str(h)) for h in headers}
    for r in rows:
        for h in headers:
            val_str = str(r.get(h, '')) if r.get(h) is not None else 'NULL'
            widths[h] = max(widths[h], len(val_str))
    
    # Header row
    header_line = " | ".join(f"{h:<{widths[h]}}" for h in headers)
    separator = "-+-".join("-" * widths[h] for h in headers)
    print("  " + header_line)
    print("  " + separator)
    for r in rows:
        line = " | ".join(f"{str(r.get(h, '') if r.get(h) is not None else 'NULL'):<{widths[h]}}" for h in headers)
        print("  " + line)
    print(f"\n  Total Records: {len(rows)}")

def show_db_overview():
    print_header("Database Architecture Overview")
    status = db.test_connection()
    print(f"  Connected Host   : {status['host']}")
    print(f"  Database Name    : {status['database']}")
    print(f"  MySQL Version    : {status['version']}")
    print(f"  User             : {status['user']}\n")
    
    print("  --- Base Tables ---")
    for t in status['tables']:
        print(f"   [TABLE] {t}")
        
    print("\n  --- SQL Views ---")
    for v in status['views']:
        print(f"   [VIEW]  {v}")

    # Fetch Procedures, Functions, Triggers
    conn = db.get_connection()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute("SHOW PROCEDURE STATUS WHERE Db = %s", (status['database'],))
        procs = [r['Name'] for r in cur.fetchall()]
        print("\n  --- Stored Procedures ---")
        for p in procs:
            print(f"   [PROC]  {p}")

        cur.execute("SHOW FUNCTION STATUS WHERE Db = %s", (status['database'],))
        funcs = [r['Name'] for r in cur.fetchall()]
        print("\n  --- Stored Functions ---")
        for f in funcs:
            print(f"   [FUNC]  {f}")

        cur.execute("SHOW TRIGGERS FROM blood_bank_db")
        trigs = [f"{r['Trigger']} (ON {r['Table']} - {r['Timing']} {r['Event']})" for r in cur.fetchall()]
        print("\n  --- Database Triggers ---")
        for tg in trigs:
            print(f"   [TRIG]  {tg}")
        cur.close()
    finally:
        conn.close()

def view_table_schema():
    print_header("Inspect Table Schema (DESCRIBE)")
    table = input("  Enter table name (donors, blood_stock, donations, blood_requests, blood_groups): ").strip()
    if not table:
        return
    try:
        rows = db.execute_query(f"DESCRIBE {table};")
        format_table(rows)
    except Exception as e:
        print(f"  [ERROR] {e}")

def view_donors():
    print_header("Donor Details (View: donor_details_view)")
    rows = db.execute_query("SELECT donor_id, full_name, blood_group_name, age, city FROM donor_details_view;")
    format_table(rows)

def view_stock():
    print_header("Current Blood Stock (View: blood_stock_view)")
    rows = db.execute_query("SELECT blood_group_name, available_units, stock_status FROM blood_stock_view;")
    format_table(rows)

def view_donations():
    print_header("Donation Records (View: donation_history_view)")
    rows = db.execute_query("SELECT donation_id, donor_name, blood_group_name, units, donation_date FROM donation_history_view LIMIT 10;")
    format_table(rows)

def view_requests():
    print_header("Blood Requests (View: blood_requests_view)")
    rows = db.execute_query("SELECT request_id, hospital_name, blood_group_name, units_requested, status FROM blood_requests_view;")
    format_table(rows)

def run_cursor_audit():
    print_header("Stored Procedure with Cursor (sp_blood_stock_audit_cursor)")
    print("  Executing: CALL sp_blood_stock_audit_cursor();")
    print("  Cursor iterates over each blood group row-by-row, calculates critical metrics, and flags shortage.")
    res = db.call_procedure('sp_blood_stock_audit_cursor')
    if res['results']:
        format_table(res['results'])
    else:
        print("  Procedure executed.")

def test_live_trigger():
    print_header("Demonstrating Live MySQL Trigger (trg_after_donation_insert)")
    print("  1. Checking stock before donation (Blood Group 1):")
    rows_before = db.execute_query("SELECT blood_group_id, available_units FROM blood_stock WHERE blood_group_id = 1;")
    format_table(rows_before)
    
    print("\n  2. Inserting 1 donation for Blood Group 1 (Donor 1)...")
    try:
        ins_sql = """
            INSERT INTO donations (donor_id, blood_group_id, donation_date, units, notes)
            VALUES (1, 1, CURDATE(), 1, 'Live CLI Trigger Demonstration');
        """
        donation_id = db.execute_query(ins_sql, commit=True, return_last_id=True)
        print(f"  [SUCCESS] Inserted Donation ID: {donation_id}")
        
        print("\n  3. Checking stock immediately after donation (Trigger auto-incremented units!):")
        rows_after = db.execute_query("SELECT blood_group_id, available_units FROM blood_stock WHERE blood_group_id = 1;")
        format_table(rows_after)
        
        # Cleanup
        print("\n  4. Cleaning up demonstration record (Trigger will auto-decrement units!)...")
        db.execute_query("DELETE FROM donations WHERE id = %s", (donation_id,), commit=True)
        print("  [SUCCESS] Deleted demonstration record and stock safely restored.")
    except Exception as e:
        print(f"  [ERROR] {e}")

def test_stored_function():
    print_header("Executing Stored Functions")
    print("  Executing: SELECT blood_group_name, fn_get_available_units(id) AS units, fn_get_stock_status_label(fn_get_available_units(id)) AS status FROM blood_groups;")
    rows = db.execute_query("SELECT blood_group_name, fn_get_available_units(id) AS units, fn_get_stock_status_label(fn_get_available_units(id)) AS status FROM blood_groups;")
    format_table(rows)

def run_custom_sql():
    print_header("Run Custom SQL Query")
    query = input("  SQL> ").strip()
    if not query:
        return
    try:
        is_select = query.strip().upper().startswith(('SELECT', 'SHOW', 'DESCRIBE', 'EXPLAIN'))
        if is_select:
            rows = db.execute_query(query)
            format_table(rows)
        else:
            affected = db.execute_query(query, commit=True)
            print(f"  [SUCCESS] Query executed. Rows affected: {affected}")
    except Exception as e:
        print(f"  [ERROR] {e}")

def main():
    while True:
        print("\n" + "=" * 70)
        print("   BLOOD BANK MANAGEMENT SYSTEM (BBMS) - COMMAND LINE CLIENT")
        print("=" * 70)
        print("  1. Show Complete Database Overview (Tables, Views, Procedures, Triggers)")
        print("  2. View Table Schema / Structure (DESCRIBE <table_name>)")
        print("  3. View Donor Registry (donor_details_view)")
        print("  4. View Blood Stock Inventory (blood_stock_view)")
        print("  5. View Donation History (donation_history_view)")
        print("  6. View Blood Requests & Urgency (blood_requests_view)")
        print("  7. Run Stored Procedure with Cursor (sp_blood_stock_audit_cursor)")
        print("  8. Test Live Trigger (trg_after_donation_insert & trg_before_donation_delete)")
        print("  9. Test Stored Functions (fn_get_available_units, fn_get_stock_status_label)")
        print(" 10. Execute Custom SQL Query")
        print("  0. Exit")
        print("-" * 70)
        choice = input("  Select an option (0-10): ").strip()

        if choice == '1':
            show_db_overview()
        elif choice == '2':
            view_table_schema()
        elif choice == '3':
            view_donors()
        elif choice == '4':
            view_stock()
        elif choice == '5':
            view_donations()
        elif choice == '6':
            view_requests()
        elif choice == '7':
            run_cursor_audit()
        elif choice == '8':
            test_live_trigger()
        elif choice == '9':
            test_stored_function()
        elif choice == '10':
            run_custom_sql()
        elif choice == '0':
            print("\n  Exiting Command Line Showcase. Goodbye!\n")
            sys.exit(0)
        else:
            print("  Invalid choice. Please select from 0 to 10.")

if __name__ == '__main__':
    main()
