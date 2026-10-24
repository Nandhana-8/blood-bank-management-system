#!/usr/bin/env python3
"""
Blood Bank Management System (BBMS) - Flask Web Application
Connected directly to MySQL database 'blood_bank_db' using mysql-connector-python.
All credentials stored in .env and loaded via python-dotenv.
"""

import os
from datetime import date, datetime
from flask import (
    Flask, render_template, request, redirect, 
    url_for, jsonify, flash
)
from dotenv import load_dotenv
import db

# Load environment configuration
load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv('SECRET_KEY', 'bbms_flask_super_secure_secret_key_2026')

# -----------------------------------------------------------------------------
# Global Context Processor: Injects common data across all templates
# -----------------------------------------------------------------------------
@app.context_processor
def inject_global_data():
    today_str = date.today().strftime('%Y-%m-%d')
    pending_count = 0
    try:
        res = db.execute_query(
            "SELECT COUNT(*) AS cnt FROM blood_requests WHERE status = 'Pending';",
            fetch_one=True
        )
        if res:
            pending_count = res.get('cnt', 0)
    except Exception:
        pending_count = 0

    return {
        'today_date': today_str,
        'pending_requests_count': pending_count
    }

# -----------------------------------------------------------------------------
# Global Error Handler: Clean user-friendly database messages without exposing credentials
# -----------------------------------------------------------------------------
@app.errorhandler(RuntimeError)
def handle_runtime_error(e):
    return render_template(
        'error.html', 
        error_title="Database Connection Error", 
        error_message=str(e),
        tip="Ensure that the MySQL service is running and credentials in .env are correct."
    ), 500

@app.errorhandler(404)
def handle_404(e):
    return render_template(
        'error.html', 
        error_title="Page Not Found", 
        error_message="The requested URL was not found on this server.",
        tip="Use the navigation menu to visit Dashboard, Donors, Stock, Donations, Requests, or Reports."
    ), 404

# -----------------------------------------------------------------------------
# Route 1: Dashboard
# -----------------------------------------------------------------------------
@app.route('/')
@app.route('/dashboard')
def dashboard():
    try:
        # 1. Total Donors
        res_donors = db.execute_query("SELECT COUNT(*) AS cnt FROM donors;", fetch_one=True)
        total_donors = res_donors.get('cnt', 0) if res_donors else 0

        # 2. Total Blood Units
        res_units = db.execute_query("SELECT COALESCE(SUM(available_units), 0) AS cnt FROM blood_stock;", fetch_one=True)
        total_units = res_units.get('cnt', 0) if res_units else 0

        # 3. Available Blood Groups (>0 units)
        res_groups = db.execute_query("SELECT COUNT(*) AS cnt FROM blood_stock WHERE available_units > 0;", fetch_one=True)
        available_groups_count = res_groups.get('cnt', 0) if res_groups else 0

        # 4. Total Requests & Pending Requests
        res_req = db.execute_query("SELECT COUNT(*) AS total, SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS pending FROM blood_requests;", fetch_one=True)
        total_requests = res_req.get('total', 0) if res_req else 0
        pending_requests = res_req.get('pending', 0) if res_req and res_req.get('pending') is not None else 0

        # 5. Blood Stock Overview (using blood_stock_view)
        stock_summary = db.execute_query("SELECT * FROM blood_stock_view ORDER BY blood_group_id ASC;")

        # 6. Recent 5 Donations (using donation_history_view)
        recent_donations = db.execute_query("SELECT * FROM donation_history_view ORDER BY donation_date DESC, donation_id DESC LIMIT 5;")

        # 7. Recent 5 Blood Requests (using blood_requests_view)
        recent_requests = db.execute_query("SELECT * FROM blood_requests_view ORDER BY request_date DESC, request_id DESC LIMIT 5;")

        # 8. All blood groups for modal dropdowns
        blood_groups = db.execute_query("SELECT * FROM blood_groups ORDER BY id ASC;")

        # 9. All donors for quick donation modal
        donors_list = db.execute_query("SELECT id, full_name, blood_group_id FROM donors ORDER BY full_name ASC;")

        stats = {
            'total_donors': total_donors,
            'total_units': total_units,
            'available_groups_count': available_groups_count,
            'total_requests': total_requests,
            'pending_requests': pending_requests
        }

        return render_template(
            'dashboard.html',
            active_page='dashboard',
            stats=stats,
            stock_summary=stock_summary,
            recent_donations=recent_donations,
            recent_requests=recent_requests,
            blood_groups=blood_groups,
            donors_list=donors_list
        )
    except Exception as e:
        flash(f"Database query error: {e}", "danger")
        return render_template('dashboard.html', active_page='dashboard', stats={}, stock_summary=[], recent_donations=[], recent_requests=[], blood_groups=[], donors_list=[])

# -----------------------------------------------------------------------------
# Route 2: Donor Management (Add, View, Edit, Delete)
# -----------------------------------------------------------------------------
@app.route('/donors')
def donors():
    try:
        search_query = request.args.get('search', '').strip()
        group_filter = request.args.get('group', '').strip()

        sql = "SELECT * FROM donor_details_view WHERE 1=1"
        params = []

        if search_query:
            sql += " AND (full_name LIKE %s OR contact LIKE %s OR city LIKE %s OR email LIKE %s)"
            wildcard = f"%{search_query}%"
            params.extend([wildcard, wildcard, wildcard, wildcard])

        if group_filter:
            sql += " AND blood_group_name = %s"
            params.append(group_filter)

        sql += " ORDER BY donor_id DESC;"

        donors_list = db.execute_query(sql, tuple(params))
        blood_groups = db.execute_query("SELECT * FROM blood_groups ORDER BY id ASC;")

        return render_template(
            'donors.html',
            active_page='donors',
            donors=donors_list,
            blood_groups=blood_groups,
            search_query=search_query,
            group_filter=group_filter
        )
    except Exception as e:
        flash(f"Error loading donors: {e}", "danger")
        return render_template('donors.html', active_page='donors', donors=[], blood_groups=[])

@app.route('/donors/add', methods=['POST'])
def add_donor():
    full_name = request.form.get('full_name', '').strip()
    blood_group_id = request.form.get('blood_group_id')
    age = request.form.get('age')
    gender = request.form.get('gender')
    contact = request.form.get('contact', '').strip()
    email = request.form.get('email', '').strip()
    city = request.form.get('city', '').strip()
    address = request.form.get('address', '').strip()
    remarks = request.form.get('remarks', '').strip()

    # Validations
    if not full_name or not blood_group_id or not age or not gender or not contact:
        flash("Please fill in all mandatory donor fields (Name, Blood Group, Age, Gender, Contact).", "warning")
        return redirect(url_for('donors'))

    try:
        age_int = int(age)
        if age_int < 18 or age_int > 65:
            flash("Donor age must be between 18 and 65 years.", "danger")
            return redirect(url_for('donors'))
    except ValueError:
        flash("Invalid age format. Please enter an integer between 18 and 65.", "danger")
        return redirect(url_for('donors'))

    try:
        # Check if contact already exists
        existing = db.execute_query("SELECT id FROM donors WHERE contact = %s;", (contact,), fetch_one=True)
        if existing:
            flash(f"A donor with contact number '{contact}' is already registered.", "warning")
            return redirect(url_for('donors'))

        # Insert new donor into MySQL
        donor_id = db.execute_query(
            """
            INSERT INTO donors (full_name, blood_group_id, age, gender, contact, email, address, city, remarks)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s);
            """,
            (full_name, int(blood_group_id), age_int, gender, contact, email or None, address or None, city or None, remarks or None),
            commit=True,
            return_last_id=True
        )
        flash(f"Donor '{full_name}' successfully registered with Donor ID #{donor_id} in MySQL!", "success")
    except Exception as e:
        flash(f"Failed to register donor: {e}", "danger")

    return redirect(url_for('donors'))

@app.route('/donors/edit/<int:donor_id>', methods=['POST'])
def edit_donor(donor_id):
    full_name = request.form.get('full_name', '').strip()
    blood_group_id = request.form.get('blood_group_id')
    age = request.form.get('age')
    gender = request.form.get('gender')
    contact = request.form.get('contact', '').strip()
    email = request.form.get('email', '').strip()
    city = request.form.get('city', '').strip()
    address = request.form.get('address', '').strip()
    remarks = request.form.get('remarks', '').strip()

    if not full_name or not blood_group_id or not age or not gender or not contact:
        flash("All mandatory fields must be completed.", "warning")
        return redirect(url_for('donors'))

    try:
        age_int = int(age)
        if age_int < 18 or age_int > 65:
            flash("Donor age must be between 18 and 65 years.", "danger")
            return redirect(url_for('donors'))

        db.execute_query(
            """
            UPDATE donors 
            SET full_name = %s, blood_group_id = %s, age = %s, gender = %s, 
                contact = %s, email = %s, city = %s, address = %s, remarks = %s
            WHERE id = %s;
            """,
            (full_name, int(blood_group_id), age_int, gender, contact, email or None, city or None, address or None, remarks or None, donor_id),
            commit=True
        )
        flash(f"Donor #{donor_id} ('{full_name}') updated successfully in MySQL!", "success")
    except Exception as e:
        flash(f"Error updating donor: {e}", "danger")

    return redirect(url_for('donors'))

@app.route('/donors/delete/<int:donor_id>', methods=['POST'])
def delete_donor(donor_id):
    try:
        # Check if donor has donations
        res = db.execute_query("SELECT full_name FROM donors WHERE id = %s;", (donor_id,), fetch_one=True)
        if not res:
            flash("Donor record not found.", "warning")
            return redirect(url_for('donors'))

        donor_name = res.get('full_name', f'#{donor_id}')
        db.execute_query("DELETE FROM donors WHERE id = %s;", (donor_id,), commit=True)
        flash(f"Donor #{donor_id} ('{donor_name}') deleted from MySQL.", "info")
    except Exception as e:
        flash(f"Cannot delete donor: {e}", "danger")

    return redirect(url_for('donors'))

@app.route('/api/donor/<int:donor_id>')
def get_donor_json(donor_id):
    donor_row = db.execute_query("SELECT * FROM donors WHERE id = %s;", (donor_id,), fetch_one=True)
    if donor_row:
        # Convert date objects to ISO string
        if donor_row.get('last_donation_date'):
            donor_row['last_donation_date'] = donor_row['last_donation_date'].strftime('%Y-%m-%d')
        if donor_row.get('created_at'):
            donor_row['created_at'] = donor_row['created_at'].strftime('%Y-%m-%d %H:%M:%S')
        return jsonify(donor_row)
    return jsonify({'error': 'Donor not found'}), 404

# -----------------------------------------------------------------------------
# Route 3: Blood Stock Management & MySQL Cursor Audit
# -----------------------------------------------------------------------------
@app.route('/stock')
def stock():
    try:
        stock_list = db.execute_query("SELECT * FROM blood_stock_view ORDER BY blood_group_id ASC;")
        blood_groups = db.execute_query("SELECT * FROM blood_groups ORDER BY id ASC;")

        # Total units across stock
        total_units = sum(item.get('available_units', 0) for item in stock_list)

        return render_template(
            'stock.html',
            active_page='stock',
            stock_list=stock_list,
            blood_groups=blood_groups,
            total_units=total_units,
            cursor_audit=None
        )
    except Exception as e:
        flash(f"Error loading blood stock: {e}", "danger")
        return render_template('stock.html', active_page='stock', stock_list=[], blood_groups=[], total_units=0, cursor_audit=None)

@app.route('/stock/update', methods=['POST'])
def update_stock():
    blood_group_id = request.form.get('blood_group_id')
    units = request.form.get('units')
    operation = request.form.get('operation', 'ADD')

    if not blood_group_id or not units:
        flash("Please provide blood group and units.", "warning")
        return redirect(url_for('stock'))

    try:
        units_int = int(units)
        # Call MySQL Stored Procedure: sp_update_stock
        db.call_procedure('sp_update_stock', (int(blood_group_id), units_int, operation))
        flash(f"Blood stock updated successfully via MySQL stored procedure 'sp_update_stock' ({operation} {units_int} units)!", "success")
    except Exception as e:
        flash(f"Failed to update stock: {e}", "danger")

    return redirect(url_for('stock'))

@app.route('/stock/cursor-audit', methods=['GET', 'POST'])
def stock_cursor_audit():
    """
    Executes the MySQL Cursor Stored Procedure: sp_blood_stock_audit_cursor
    Iterates row-by-row over blood groups and generates a stock audit report with recommendations.
    """
    try:
        stock_list = db.execute_query("SELECT * FROM blood_stock_view ORDER BY blood_group_id ASC;")
        blood_groups = db.execute_query("SELECT * FROM blood_groups ORDER BY id ASC;")
        total_units = sum(item.get('available_units', 0) for item in stock_list)

        # Call procedure using cursor
        audit_res = db.call_procedure('sp_blood_stock_audit_cursor')
        cursor_audit_results = audit_res.get('results', [])

        flash(f"MySQL Cursor Audit executed successfully! Processed {len(cursor_audit_results)} blood groups row-by-row using MySQL CURSOR.", "info")

        return render_template(
            'stock.html',
            active_page='stock',
            stock_list=stock_list,
            blood_groups=blood_groups,
            total_units=total_units,
            cursor_audit=cursor_audit_results
        )
    except Exception as e:
        flash(f"Failed to execute cursor procedure: {e}", "danger")
        return redirect(url_for('stock'))

# -----------------------------------------------------------------------------
# Route 4: Blood Donation Records
# -----------------------------------------------------------------------------
@app.route('/donations')
def donations():
    try:
        search_query = request.args.get('search', '').strip()
        group_filter = request.args.get('group', '').strip()

        sql = "SELECT * FROM donation_history_view WHERE 1=1"
        params = []

        if search_query:
            sql += " AND (donor_name LIKE %s OR donor_contact LIKE %s OR donor_city LIKE %s)"
            wildcard = f"%{search_query}%"
            params.extend([wildcard, wildcard, wildcard])

        if group_filter:
            sql += " AND blood_group_name = %s"
            params.append(group_filter)

        sql += " ORDER BY donation_date DESC, donation_id DESC;"

        donations_list = db.execute_query(sql, tuple(params))
        donors_list = db.execute_query("SELECT id, full_name, blood_group_id FROM donors ORDER BY full_name ASC;")
        blood_groups = db.execute_query("SELECT * FROM blood_groups ORDER BY id ASC;")

        return render_template(
            'donations.html',
            active_page='donations',
            donations=donations_list,
            donors_list=donors_list,
            blood_groups=blood_groups,
            search_query=search_query,
            group_filter=group_filter
        )
    except Exception as e:
        flash(f"Error loading donation records: {e}", "danger")
        return render_template('donations.html', active_page='donations', donations=[], donors_list=[], blood_groups=[])

@app.route('/donations/add', methods=['POST'])
def add_donation():
    donor_id = request.form.get('donor_id')
    donation_date = request.form.get('donation_date', date.today().strftime('%Y-%m-%d'))
    units = request.form.get('units', '1')
    hemoglobin = request.form.get('hemoglobin_level', '').strip()
    blood_pressure = request.form.get('blood_pressure', '').strip()
    pulse_rate = request.form.get('pulse_rate', '').strip()
    notes = request.form.get('notes', '').strip()

    if not donor_id:
        flash("Please select a donor.", "warning")
        return redirect(url_for('donations'))

    try:
        units_int = int(units)
        if units_int <= 0:
            flash("Donation units must be at least 1.", "warning")
            return redirect(url_for('donations'))

        hb_val = float(hemoglobin) if hemoglobin else None
        if hb_val is not None and hb_val < 12.0:
            flash("Hemoglobin level must be at least 12.0 g/dL for safe donation eligibility.", "danger")
            return redirect(url_for('donations'))

        pulse_int = int(pulse_rate) if pulse_rate else None

        # Fetch donor's blood group
        donor = db.execute_query("SELECT full_name, blood_group_id FROM donors WHERE id = %s;", (int(donor_id),), fetch_one=True)
        if not donor:
            flash("Selected donor was not found in the database.", "danger")
            return redirect(url_for('donations'))

        blood_group_id = donor['blood_group_id']

        # Insert donation into MySQL
        # The MySQL Trigger 'trg_after_donation_insert' will automatically increment
        # blood_stock and update the donor's last_donation_date!
        donation_id = db.execute_query(
            """
            INSERT INTO donations (donor_id, blood_group_id, donation_date, units, hemoglobin_level, blood_pressure, pulse_rate, notes)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s);
            """,
            (int(donor_id), blood_group_id, donation_date, units_int, hb_val, blood_pressure or None, pulse_int, notes or None),
            commit=True,
            return_last_id=True
        )

        flash(
            f"Donation #{donation_id} recorded successfully! "
            f"MySQL Trigger 'trg_after_donation_insert' automatically incremented blood stock by {units_int} unit(s) "
            f"and updated {donor['full_name']}'s last donation date.",
            "success"
        )
    except Exception as e:
        flash(f"Failed to record donation: {e}", "danger")

    return redirect(url_for('donations'))

@app.route('/donations/delete/<int:donation_id>', methods=['POST'])
def delete_donation(donation_id):
    try:
        # Delete donation
        # MySQL Trigger 'trg_before_donation_delete' will verify stock and decrement safely
        db.execute_query("DELETE FROM donations WHERE id = %s;", (donation_id,), commit=True)
        flash(f"Donation #{donation_id} deleted. MySQL trigger adjusted blood stock safely.", "info")
    except Exception as e:
        flash(f"Cannot delete donation: {e}", "danger")

    return redirect(url_for('donations'))

# -----------------------------------------------------------------------------
# Route 5: Blood Requests Management
# -----------------------------------------------------------------------------
@app.route('/requests')
def requests_page():
    try:
        search_query = request.args.get('search', '').strip()
        status_filter = request.args.get('status', '').strip()
        group_filter = request.args.get('group', '').strip()

        sql = "SELECT * FROM blood_requests_view WHERE 1=1"
        params = []

        if search_query:
            sql += " AND (patient_name LIKE %s OR hospital_name LIKE %s OR reason LIKE %s)"
            wildcard = f"%{search_query}%"
            params.extend([wildcard, wildcard, wildcard])

        if status_filter:
            sql += " AND status = %s"
            params.append(status_filter)

        if group_filter:
            sql += " AND blood_group_name = %s"
            params.append(group_filter)

        sql += " ORDER BY request_date DESC, request_id DESC;"

        requests_list = db.execute_query(sql, tuple(params))
        blood_groups = db.execute_query("SELECT * FROM blood_groups ORDER BY id ASC;")

        return render_template(
            'requests.html',
            active_page='requests',
            requests=requests_list,
            blood_groups=blood_groups,
            search_query=search_query,
            status_filter=status_filter,
            group_filter=group_filter
        )
    except Exception as e:
        flash(f"Error loading blood requests: {e}", "danger")
        return render_template('requests.html', active_page='requests', requests=[], blood_groups=[])

@app.route('/requests/add', methods=['POST'])
def add_request():
    patient_name = request.form.get('patient_name', '').strip()
    hospital_name = request.form.get('hospital_name', '').strip()
    blood_group_id = request.form.get('blood_group_id')
    units_requested = request.form.get('units_requested', '1')
    request_date = request.form.get('request_date', date.today().strftime('%Y-%m-%d'))
    reason = request.form.get('reason', '').strip()

    if not patient_name or not hospital_name or not blood_group_id or not units_requested:
        flash("Please provide all required fields (Patient, Hospital, Blood Group, Units Requested).", "warning")
        return redirect(url_for('requests_page'))

    try:
        units_int = int(units_requested)
        if units_int <= 0:
            flash("Units requested must be greater than zero.", "warning")
            return redirect(url_for('requests_page'))

        req_id = db.execute_query(
            """
            INSERT INTO blood_requests (patient_name, hospital_name, blood_group_id, units_requested, request_date, reason, status)
            VALUES (%s, %s, %s, %s, %s, %s, 'Pending');
            """,
            (patient_name, hospital_name, int(blood_group_id), units_int, request_date, reason or None),
            commit=True,
            return_last_id=True
        )
        flash(f"Blood request #{req_id} for patient '{patient_name}' recorded successfully with status 'Pending'!", "success")
    except Exception as e:
        flash(f"Failed to submit blood request: {e}", "danger")

    return redirect(url_for('requests_page'))

@app.route('/requests/status/<int:request_id>', methods=['POST'])
def update_request_status(request_id):
    new_status = request.form.get('status')
    if new_status not in ['Pending', 'Approved', 'Fulfilled', 'Rejected']:
        flash("Invalid status specified.", "warning")
        return redirect(url_for('requests_page'))

    try:
        # If updating to 'Fulfilled', the MySQL trigger 'trg_before_blood_request_update'
        # checks available stock. If stock is insufficient, it throws SQLSTATE 45000,
        # which rolls back and raises an exception that we cleanly catch here!
        db.execute_query(
            "UPDATE blood_requests SET status = %s WHERE id = %s;",
            (new_status, request_id),
            commit=True
        )
        if new_status == 'Fulfilled':
            flash(f"Blood request #{request_id} has been FULFILLED! MySQL Trigger automatically validated stock and deducted blood units.", "success")
        else:
            flash(f"Blood request #{request_id} status updated to '{new_status}'.", "info")
    except Exception as e:
        err_text = str(e)
        if "Insufficient blood stock" in err_text:
            flash(f"Cannot fulfill Request #{request_id}: Insufficient blood stock available in inventory! Please check current stock.", "danger")
        else:
            flash(f"Database error updating request status: {e}", "danger")

    return redirect(url_for('requests_page'))

# -----------------------------------------------------------------------------
# Route 6: Reports & Statistical Insights
# -----------------------------------------------------------------------------
@app.route('/reports')
def reports():
    try:
        # Report 1: Blood stock summary with stored function call (fn_get_available_units)
        stock_report = db.execute_query(
            """
            SELECT 
                bg.id,
                bg.blood_group_name,
                bg.rh_factor,
                fn_get_available_units(bg.id) AS available_units,
                fn_get_stock_status_label(fn_get_available_units(bg.id)) AS status_label,
                COUNT(dn.id) AS total_donations_count,
                COALESCE(SUM(dn.units), 0) AS lifetime_collected_units
            FROM blood_groups bg
            LEFT JOIN donations dn ON bg.id = dn.blood_group_id
            GROUP BY bg.id, bg.blood_group_name, bg.rh_factor
            ORDER BY bg.id ASC;
            """
        )

        # Report 2: Donor directory with aggregated donation metrics (donor_details_view)
        donor_report = db.execute_query("SELECT * FROM donor_details_view ORDER BY total_donations DESC, donor_id ASC;")

        # Report 3: Donation history
        donation_report = db.execute_query("SELECT * FROM donation_history_view ORDER BY donation_date DESC LIMIT 30;")

        # Report 4: Blood request summary
        request_report = db.execute_query("SELECT * FROM blood_requests_view ORDER BY request_date DESC LIMIT 30;")

        # Report 5: Analytical query with GROUP BY and HAVING (donors distribution by city)
        city_stats = db.execute_query(
            """
            SELECT city, COUNT(*) AS donor_count, GROUP_CONCAT(DISTINCT bg.blood_group_name SEPARATOR ', ') AS available_groups
            FROM donors d
            JOIN blood_groups bg ON d.blood_group_id = bg.id
            WHERE city IS NOT NULL
            GROUP BY city
            HAVING COUNT(*) >= 1
            ORDER BY donor_count DESC;
            """
        )

        # Aggregated KPI numbers
        total_donors = len(donor_report)
        total_units = sum(item.get('available_units', 0) for item in stock_report)
        total_donations = db.execute_query("SELECT COUNT(*) AS cnt FROM donations;", fetch_one=True).get('cnt', 0)
        total_fulfilled = db.execute_query("SELECT COUNT(*) AS cnt FROM blood_requests WHERE status = 'Fulfilled';", fetch_one=True).get('cnt', 0)

        summary_kpi = {
            'total_donors': total_donors,
            'total_units': total_units,
            'total_donations': total_donations,
            'total_fulfilled': total_fulfilled
        }

        return render_template(
            'reports.html',
            active_page='reports',
            stock_report=stock_report,
            donor_report=donor_report,
            donation_report=donation_report,
            request_report=request_report,
            city_stats=city_stats,
            summary_kpi=summary_kpi
        )
    except Exception as e:
        flash(f"Error compiling reports: {e}", "danger")
        return render_template('reports.html', active_page='reports', stock_report=[], donor_report=[], donation_report=[], request_report=[], city_stats=[], summary_kpi={})

# -----------------------------------------------------------------------------
# Route 7: SQL Lab / Viva Demonstrator (Interactive DBMS showcase)
# -----------------------------------------------------------------------------
@app.route('/sql-lab', methods=['GET', 'POST'])
def sql_lab():
    """
    An interactive DBMS demonstration lab where a college student or evaluator
    can run actual MySQL queries and inspect real tables, views, procedures, and triggers.
    """
    query_result = None
    selected_query_title = None
    query_sql = None
    error_message = None

    demo_queries = {
        'dql_young_donors': {
            'title': 'DQL: Select with WHERE & ORDER BY (Young Donors)',
            'sql': 'SELECT full_name, age, city FROM donors WHERE age <= 30 ORDER BY age ASC LIMIT 5;'
        },
        'aggregate_metrics': {
            'title': 'Aggregates: COUNT, AVG, MIN, MAX on Donors',
            'sql': 'SELECT COUNT(*) AS total_donors, ROUND(AVG(age), 1) AS avg_age, MIN(age) AS youngest, MAX(age) AS oldest FROM donors;'
        },
        'inner_join_donations': {
            'title': 'Joins: Simple INNER JOIN across Donors & Blood Groups',
            'sql': 'SELECT donors.full_name, blood_groups.blood_group_name, donations.units, donations.donation_date FROM donations JOIN donors ON donations.donor_id = donors.id JOIN blood_groups ON donations.blood_group_id = blood_groups.id LIMIT 5;'
        },
        'subquery_critical_donors': {
            'title': 'Subquery: Donors with low blood stock (< 10 units)',
            'sql': 'SELECT full_name, city FROM donors WHERE blood_group_id IN (SELECT blood_group_id FROM blood_stock WHERE available_units < 10);'
        },
        'group_by_having': {
            'title': 'GROUP BY with HAVING: Cities with multiple donors',
            'sql': 'SELECT city, COUNT(*) AS donor_count FROM donors GROUP BY city HAVING donor_count > 1;'
        },
        'view_blood_stock': {
            'title': 'Views: Simple query on blood_stock_view',
            'sql': 'SELECT * FROM blood_stock_view;'
        },
        'function_get_units': {
            'title': 'Stored Function: Calling fn_get_available_units()',
            'sql': 'SELECT blood_group_name, fn_get_available_units(id) AS units FROM blood_groups;'
        },
        'show_triggers': {
            'title': 'Inspection: SHOW TRIGGERS in database',
            'sql': 'SHOW TRIGGERS;'
        },
        'show_procedures': {
            'title': 'Inspection: SHOW PROCEDURE STATUS',
            'sql': "SHOW PROCEDURE STATUS WHERE Db = 'blood_bank_db';"
        }
    }

    if request.method == 'POST':
        action = request.form.get('action')
        custom_sql = request.form.get('custom_sql', '').strip()

        if action in demo_queries:
            selected_query_title = demo_queries[action]['title']
            query_sql = demo_queries[action]['sql']
        elif custom_sql:
            selected_query_title = "Custom Evaluator Query"
            query_sql = custom_sql
        else:
            selected_query_title = demo_queries['dql_young_donors']['title']
            query_sql = demo_queries['dql_young_donors']['sql']

        try:
            # Execute query safely
            # Only allow SELECT, SHOW, DESCRIBE, EXPLAIN in this lab runner
            allowed_prefixes = ('SELECT', 'SHOW', 'DESCRIBE', 'EXPLAIN', 'CALL')
            if not query_sql.strip().upper().startswith(allowed_prefixes):
                raise ValueError("For security during viva demonstrations, only SELECT, SHOW, DESCRIBE, EXPLAIN, and CALL queries are supported here.")

            if query_sql.strip().upper().startswith('CALL'):
                # Call procedure
                proc_name = query_sql.strip().split()[1].split('(')[0]
                proc_res = db.call_procedure(proc_name)
                query_result = proc_res.get('results', [])
            else:
                query_result = db.execute_query(query_sql, fetch_all=True)
        except Exception as e:
            error_message = str(e)

    # Database overview metadata
    try:
        db_status = db.test_connection()
    except Exception:
        db_status = {'status': 'disconnected', 'tables': [], 'views': []}

    return render_template(
        'sql_lab.html',
        active_page='sql_lab',
        demo_queries=demo_queries,
        selected_query_title=selected_query_title,
        query_sql=query_sql,
        query_result=query_result,
        error_message=error_message,
        db_status=db_status
    )

# -----------------------------------------------------------------------------
# Main Application Entry Point
# -----------------------------------------------------------------------------
if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('DEBUG', 'True').lower() in ('true', '1', 'yes')
    print("=" * 70)
    print("  BLOOD BANK MANAGEMENT SYSTEM (BBMS) - FLASK SERVER")
    print(f"  Connected to MySQL Database : blood_bank_db")
    print(f"  Access web application at   : http://127.0.0.1:{port}")
    print("=" * 70)
    app.run(host='0.0.0.0', port=port, debug=debug)
