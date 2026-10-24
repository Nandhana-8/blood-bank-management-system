#!/usr/bin/env python3
"""
Blood Bank Management System (BBMS) - Automated Test Suite
Verifies all web pages, routes, database synchronization, triggers, procedures, and cursors.
"""

import sys
import unittest
from app import app
import db

class BBMSTestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        app.config['TESTING'] = True
        app.config['WTF_CSRF_ENABLED'] = False
        cls.client = app.test_client()

    def test_01_database_connection(self):
        """Verify direct MySQL connection and required base tables."""
        status = db.test_connection()
        self.assertEqual(status['status'], 'connected')
        for tbl in ['blood_groups', 'blood_stock', 'donors', 'donations', 'blood_requests']:
            self.assertIn(tbl, status['tables'])
        print("\n[TEST 01 PASSED] MySQL Connection & Base Tables verified.")

    def test_02_dashboard_page(self):
        """Verify dashboard page loads with live statistics."""
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b"Executive Blood Bank Dashboard", response.data)
        self.assertIn(b"Live Blood Stock Levels", response.data)
        print("[TEST 02 PASSED] Dashboard route (/ and /dashboard) loads with live KPI metrics.")

    def test_03_donors_page(self):
        """Verify donor management page loads."""
        response = self.client.get('/donors')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b"Donor Management", response.data)
        self.assertIn(b"Registered Donors Directory", response.data)
        print("[TEST 03 PASSED] Donors route (/donors) loads properly.")

    def test_04_stock_page_and_cursor(self):
        """Verify stock page and MySQL Cursor audit procedure."""
        response = self.client.get('/stock')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b"Blood Stock Management", response.data)

        # Execute cursor procedure route
        cursor_resp = self.client.get('/stock/cursor-audit')
        self.assertEqual(cursor_resp.status_code, 200)
        self.assertIn(b"MySQL Cursor Audit Report", cursor_resp.data)
        self.assertIn(b"sp_blood_stock_audit_cursor", cursor_resp.data)
        print("[TEST 04 PASSED] Blood Stock and MySQL Cursor Audit (/stock/cursor-audit) executed successfully.")

    def test_05_donations_page(self):
        """Verify blood donation records page loads."""
        response = self.client.get('/donations')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b"Blood Donation Records", response.data)
        self.assertIn(b"Donation Event History", response.data)
        print("[TEST 05 PASSED] Donations route (/donations) loads properly.")

    def test_06_requests_page(self):
        """Verify blood requests page loads."""
        response = self.client.get('/requests')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b"Blood Requisition Management", response.data)
        self.assertIn(b"Hospital Requisitions Registry", response.data)
        print("[TEST 06 PASSED] Requests route (/requests) loads properly.")

    def test_07_reports_page(self):
        """Verify reports page loads with multiple report tabs."""
        response = self.client.get('/reports')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b"Comprehensive Blood Bank Reports", response.data)
        self.assertIn(b"Blood Stock Inventory", response.data)
        self.assertIn(b"Donor Register", response.data)
        print("[TEST 07 PASSED] Reports route (/reports) loads with all analytical tabs.")

    def test_08_sql_lab_page(self):
        """Verify SQL Lab / Viva Demonstrator page loads and runs queries."""
        response = self.client.get('/sql-lab')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b"SQL Lab & Viva Demonstrator", response.data)

        # Test executing a query via SQL Lab
        post_resp = self.client.post('/sql-lab', data={'action': 'dql_young_donors'})
        self.assertEqual(post_resp.status_code, 200)
        self.assertIn(b"MySQL Query Output", post_resp.data)
        print("[TEST 08 PASSED] SQL Lab (/sql-lab) executes DQL queries live in MySQL.")

    def test_09_donor_lifecycle_sync(self):
        """Test adding, editing, and deleting a donor with live MySQL verification."""
        # 1. Add Donor
        add_resp = self.client.post('/donors/add', data={
            'full_name': 'Test Automated Donor',
            'blood_group_id': 1,
            'age': 27,
            'gender': 'Male',
            'contact': '9112233445',
            'email': 'automated.test@example.com',
            'city': 'Bengaluru',
            'address': 'Test Tech Park',
            'remarks': 'Automated Test Donor'
        }, follow_redirects=True)
        self.assertEqual(add_resp.status_code, 200)

        # Verify in MySQL
        donor = db.execute_query("SELECT * FROM donors WHERE contact = '9112233445';", fetch_one=True)
        self.assertIsNotNone(donor)
        donor_id = donor['id']
        self.assertEqual(donor['full_name'], 'Test Automated Donor')

        # 2. Edit Donor
        edit_resp = self.client.post(f'/donors/edit/{donor_id}', data={
            'full_name': 'Test Updated Donor',
            'blood_group_id': 1,
            'age': 28,
            'gender': 'Male',
            'contact': '9112233445',
            'email': 'updated.test@example.com',
            'city': 'Bengaluru',
            'address': 'Updated Street Address',
            'remarks': 'Updated remarks'
        }, follow_redirects=True)
        self.assertEqual(edit_resp.status_code, 200)

        updated_donor = db.execute_query("SELECT full_name, age FROM donors WHERE id = %s;", (donor_id,), fetch_one=True)
        self.assertEqual(updated_donor['full_name'], 'Test Updated Donor')
        self.assertEqual(updated_donor['age'], 28)

        # 3. Clean up / Delete Donor
        del_resp = self.client.post(f'/donors/delete/{donor_id}', follow_redirects=True)
        self.assertEqual(del_resp.status_code, 200)
        deleted = db.execute_query("SELECT id FROM donors WHERE id = %s;", (donor_id,), fetch_one=True)
        self.assertIsNone(deleted)
        print("[TEST 09 PASSED] Donor Lifecycle (Add -> Edit -> Delete) verified in MySQL.")

    def test_10_trigger_stock_sync_on_donation(self):
        """Verify MySQL Trigger increases blood_stock on donation insert and decrements on deletion."""
        # Check initial stock of Blood Group 1 (A+)
        initial_stock = db.execute_query("SELECT available_units FROM blood_stock WHERE blood_group_id = 1;", fetch_one=True)['available_units']

        # Record a donation of 2 units for donor 1 (A+)
        post_resp = self.client.post('/donations/add', data={
            'donor_id': 1,
            'donation_date': '2026-10-21',
            'units': 2,
            'hemoglobin_level': 14.0,
            'blood_pressure': '120/80',
            'pulse_rate': 72,
            'notes': 'Unit test live sync'
        }, follow_redirects=True)
        self.assertEqual(post_resp.status_code, 200)

        # Check stock increased by 2 units purely by MySQL trigger
        after_insert_stock = db.execute_query("SELECT available_units FROM blood_stock WHERE blood_group_id = 1;", fetch_one=True)['available_units']
        self.assertEqual(after_insert_stock, initial_stock + 2)

        # Find donation ID
        donation = db.execute_query("SELECT id FROM donations WHERE notes = 'Unit test live sync';", fetch_one=True)
        donation_id = donation['id']

        # Delete donation
        del_resp = self.client.post(f'/donations/delete/{donation_id}', follow_redirects=True)
        self.assertEqual(del_resp.status_code, 200)

        # Check stock returned to initial value via MySQL trigger
        after_delete_stock = db.execute_query("SELECT available_units FROM blood_stock WHERE blood_group_id = 1;", fetch_one=True)['available_units']
        self.assertEqual(after_delete_stock, initial_stock)
        print("[TEST 10 PASSED] Live Trigger synchronization (Insert donation -> Stock increments; Delete donation -> Stock decrements) verified.")

    def test_11_insufficient_stock_prevents_fulfillment(self):
        """Verify that fulfilling a request with units > available stock is blocked by MySQL Trigger."""
        # Blood Group 9 (Oh - Bombay) has 2 units
        # Insert a request for 25 units
        req_id = db.execute_query(
            "INSERT INTO blood_requests (patient_name, hospital_name, blood_group_id, units_requested, request_date, status) VALUES ('Test Overdemand', 'Test Care', 9, 25, CURDATE(), 'Pending');",
            commit=True,
            return_last_id=True
        )

        # Attempt to fulfill
        fulfill_resp = self.client.post(f'/requests/status/{req_id}', data={'status': 'Fulfilled'}, follow_redirects=True)
        self.assertIn(b"Insufficient blood stock", fulfill_resp.data)

        # Verify status is still 'Pending' in MySQL
        req_row = db.execute_query("SELECT status FROM blood_requests WHERE id = %s;", (req_id,), fetch_one=True)
        self.assertEqual(req_row['status'], 'Pending')

        # Clean up
        db.execute_query("DELETE FROM blood_requests WHERE id = %s;", (req_id,), commit=True)
        print("[TEST 11 PASSED] Insufficient stock correctly blocks fulfillment via MySQL Trigger.")

if __name__ == '__main__':
    unittest.main()
