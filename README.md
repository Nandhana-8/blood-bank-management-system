# 🩸 Blood Bank Management System (BBMS)

A complete, beginner-friendly **Blood Bank Management System** built with **Python Flask** and **MySQL Server 8.0** connected via `mysql-connector-python`. Designed with clean architecture, live real-time synchronization, and comprehensive demonstration of all essential DBMS concepts required for academic evaluation and viva examinations.

---

## 📋 Table of Contents
1. [Technology Stack](#-technology-stack)
2. [Project Folder Structure](#-project-folder-structure)
3. [Database Design & 3NF Normalization](#-database-design--3nf-normalization)
4. [Mandatory SQL Concepts Explained (Viva Guide)](#-mandatory-sql-concepts-explained-viva-guide)
   - [DDL, DML, DQL](#1-ddl-dml-dql)
   - [Aggregate Functions & Joins](#2-aggregate-functions--joins)
   - [Subqueries & GROUP BY with HAVING](#3-subqueries--group-by-with-having)
   - [Views](#4-database-views)
   - [Stored Procedures & Transactions](#5-stored-procedures--acid-transactions)
   - [Stored Functions](#6-stored-functions)
   - [Triggers (Live Inventory Sync)](#7-triggers-live-synchronization)
   - [Cursors](#8-mysql-cursor-demonstration)
   - [Indexes](#9-indexes--optimization)
5. [Quick Start & Setup Guide](#-quick-start--setup-guide)
6. [How to Launch in VS Code Step-by-Step](#-how-to-launch-in-vs-code-step-by-step)
7. [MySQL CLI Commands Cheat Sheet](#-mysql-cli-commands-cheat-sheet)
8. [Automated Testing Suite](#-automated-testing-suite)

---

## 🛠 Technology Stack

- **Backend**: Python 3 (Flask Framework)
- **Database**: MySQL Server 8.0 (`blood_bank_db`)
- **Database Driver**: `mysql-connector-python`
- **Environment Management**: `python-dotenv`
- **Frontend**: HTML5, Vanilla CSS3, JavaScript (ES6+), Bootstrap 5.3, FontAwesome 6

---

## 📂 Project Folder Structure

```
blood-bank-management-system/
├── .env                     # Environment variables (MySQL credentials & Flask secret)
├── .env.example             # Example configuration template
├── requirements.txt         # Python dependencies
├── app.py                   # Main Flask application and API routes
├── db.py                    # MySQL connection module using mysql-connector-python
├── init_db.py               # Complete database setup and table verification script
├── test_app.py              # Automated 11-test verification test suite
│
├── schema.sql               # DDL: Tables, constraints, foreign keys, alter, safe drop
├── sample_data.sql          # DML: Realistic sample records (>= 9 records per table)
├── views.sql                # Abstracted relational views with JOINs & aggregations
├── functions.sql            # Stored functions (fn_get_available_units, etc.)
├── triggers.sql             # Live inventory sync & safe decrement triggers
├── procedures.sql           # Stored procedures with ACID transaction handling
├── cursor_demo.sql          # Cursor stored procedure (sp_blood_stock_audit_cursor)
├── queries.sql              # Executable demonstration queries for all DBMS concepts
│
├── static/
│   ├── css/
│   │   └── style.css        # Custom responsive medical & blood bank theme
│   └── js/
│       └── main.js          # Table CSV export, live filtering, and alert controls
│
└── templates/
    ├── base.html            # Core layout with navigation and alert messages
    ├── dashboard.html       # Control center KPI cards, stock levels, recent events
    ├── donors.html          # Donor directory with add/edit/delete modals
    ├── stock.html           # Blood stock management & MySQL cursor audit runner
    ├── donations.html       # Blood donation ledger with trigger sync
    ├── requests.html        # Hospital requisition lifecycle (Pending -> Fulfilled)
    ├── reports.html         # Multi-tab audited reports with CSV export & print
    ├── sql_lab.html         # Interactive DBMS viva lab console
    └── error.html           # User-friendly error page without exposing credentials
```

---

## 🗄 Database Design & 3NF Normalization

The database `blood_bank_db` is designed in strict **Third Normal Form (3NF)**:

```
  +------------------+         1 : 1          +------------------+
  |   blood_groups   | <--------------------> |   blood_stock    |
  |  (id, name, Rh)  |                        | (available_units)|
  +------------------+                        +------------------+
          |
          | 1 : N
          v
  +------------------+         1 : N          +------------------+
  |      donors      | ---------------------> |    donations     |
  | (name, age, tel) |                        | (units, date, Hb)|
  +------------------+                        +------------------+
          |                                            |
          +-------------------+                        |
                              |                        |
                              v                        v
                     +------------------------------------+
                     |           blood_requests           |
                     |  (patient, hospital, units, status)|
                     +------------------------------------+
```

### Normalization Justification:
1. **1NF (First Normal Form)**:
   - All columns contain only atomic (indivisible) values.
   - Each table has an explicit primary key (`id` AUTO_INCREMENT).
   - No repeating groups or comma-separated lists.
2. **2NF (Second Normal Form)**:
   - In 1NF, and every non-key column is fully functionally dependent on the primary key (no partial dependencies on composite keys).
3. **3NF (Third Normal Form)**:
   - In 2NF, and no transitive dependencies exist (non-key columns do not depend on other non-key columns). For example, donor city and contact depend solely on `donor.id`, while blood group metadata resides cleanly in `blood_groups`.

### Tables and Constraints:
- `blood_groups`: Stores 9 blood groups (A+, A-, B+, B-, AB+, AB-, O+, O-, Oh).
- `blood_stock`: Tracks available units per group with `CHECK (available_units >= 0)`.
- `donors`: Stores voluntary donor profiles with `CHECK (age >= 18 AND age <= 65)`.
- `donations`: Stores donation records with `CHECK (units > 0)` and `CHECK (hemoglobin_level >= 12.0)`.
- `blood_requests`: Stores hospital requisitions with status `('Pending', 'Approved', 'Fulfilled', 'Rejected')`.

---

## 🎓 Mandatory SQL Concepts Explained (Viva Guide)

### 1. DDL, DML, DQL
- **DDL (Data Definition Language)**: Defines database structure.
  - `CREATE TABLE`: Creates `blood_groups`, `donors`, `blood_stock`, `donations`, `blood_requests`.
  - `ALTER TABLE`: Demonstrates schema evolution (`ALTER TABLE donors ADD COLUMN remarks VARCHAR(255);`).
  - `DROP TABLE`: Safely demonstrated on temporary table `demo_scratch_table`.
- **DML (Data Modification Language)**: Modifies table data.
  - `INSERT`: Adds donors, donations, and blood requests.
  - `UPDATE`: Modifies donor contact or edits blood request status.
  - `DELETE`: Safely removes records with foreign key integrity.
- **DQL (Data Query Language)**:
  - `SELECT ... WHERE ... ORDER BY ... DISTINCT ... LIMIT`:
    ```sql
    SELECT DISTINCT city FROM donors ORDER BY city ASC LIMIT 5;
    ```

### 2. Aggregate Functions & Joins
- **Aggregates**: `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`:
  ```sql
  SELECT COUNT(*) AS total_donors, MIN(age) AS youngest, MAX(age) AS oldest, ROUND(AVG(age), 1) AS avg_age FROM donors;
  ```
- **INNER JOIN**: Joins donations with donor names and blood group names:
  ```sql
  SELECT dn.id, d.full_name, bg.blood_group_name, dn.units 
  FROM donations dn
  INNER JOIN donors d ON dn.donor_id = d.id
  INNER JOIN blood_groups bg ON dn.blood_group_id = bg.id;
  ```
- **LEFT JOIN**: Displays all registered donors, including those who have not yet donated:
  ```sql
  SELECT d.full_name, COUNT(dn.id) AS donations_count
  FROM donors d
  LEFT JOIN donations dn ON d.id = dn.donor_id
  GROUP BY d.id, d.full_name;
  ```
- **RIGHT JOIN**: Displays all blood groups even if no requests currently exist for them.

### 3. Subqueries & GROUP BY with HAVING
- **Subquery with IN**:
  ```sql
  SELECT full_name, contact FROM donors
  WHERE blood_group_id IN (SELECT blood_group_id FROM blood_stock WHERE available_units < 10);
  ```
- **Scalar Subquery**:
  ```sql
  SELECT dn.id, d.full_name, dn.hemoglobin_level 
  FROM donations dn
  JOIN donors d ON dn.donor_id = d.id
  WHERE dn.hemoglobin_level > (SELECT AVG(hemoglobin_level) FROM donations);
  ```
- **GROUP BY with HAVING**:
  ```sql
  SELECT city, COUNT(*) AS donor_count
  FROM donors
  GROUP BY city
  HAVING COUNT(*) > 1;
  ```

### 4. Database Views
Views provide a virtual, secure, and pre-computed abstraction over joined tables:
1. `donor_details_view`: Joins donors with blood groups and calculates total lifetime donations.
2. `blood_stock_view`: Summarizes available units, computed stock status ('Critical', 'Moderate', 'Sufficient'), and lifetime collected units.
3. `donation_history_view`: Formatted chronological donation records with donor details.
4. `blood_requests_view`: Hospital requisitions joined with live stock availability.

### 5. Stored Procedures & ACID Transactions
Procedures execute business logic inside MySQL using `START TRANSACTION`, `COMMIT`, and `ROLLBACK`:
- `sp_record_donation(donor_id, date, units, hb, bp, pulse, notes, OUT donation_id)`:
  Atomically verifies donor existence, records donation, and commits.
- `sp_update_stock(blood_group_id, units, operation)`:
  Safely updates stock ('ADD', 'SUBTRACT', 'SET') using row-level locking (`FOR UPDATE`) to prevent race conditions.
- `sp_get_donor_info(donor_id)`: Retrieves comprehensive donor profile and donation metrics.
- `sp_fulfill_request(request_id, OUT code, OUT msg)`: Fulfills a blood request atomically.

### 6. Stored Functions
- `fn_get_available_units(group_id) RETURNS INT`:
  Reads `blood_stock` and returns the exact available units for any blood group ID.
- `fn_get_stock_status_label(units) RETURNS VARCHAR(20)`:
  Returns `'CRITICAL'` (&lt; 5), `'MODERATE'` (5-15), or `'SUFFICIENT'` (&gt; 15).
- `fn_check_stock_availability(group_id, required_units) RETURNS BOOLEAN`:
  Returns `TRUE` if stock is sufficient, otherwise `FALSE`.

### 7. Triggers (Live Synchronization)
Triggers run inside MySQL automatically upon table modifications:
- `trg_after_donation_insert`:
  When a donation is inserted, it **automatically increments** `blood_stock.available_units` and updates the donor's `last_donation_date`.
- `trg_before_donation_update`:
  Safely balances blood stock when donation units or blood group are edited, preventing negative inventory.
- `trg_before_donation_delete`:
  Safely decrements blood stock when a donation record is deleted. If stock has already been consumed below the donation units, it halts the deletion with `SIGNAL SQLSTATE '45000'`.
- `trg_before_blood_request_update`:
  When a blood request is marked **Fulfilled**, it checks stock availability. If stock is insufficient, it throws an error and aborts. If sufficient, it **automatically deducts** the units and sets `fulfilled_date = CURDATE()`.

### 8. MySQL Cursor Demonstration
- Procedure: `sp_blood_stock_audit_cursor()`
- Uses a `DECLARE cur_blood_groups CURSOR FOR ...` and a `DECLARE CONTINUE HANDLER FOR NOT FOUND`.
- Loops through every blood group record row-by-row, analyzes stock levels against clinical thresholds, computes donation frequency, and populates a temporary table `temp_blood_stock_audit` with clinical recommendations.

### 9. Indexes & Optimization
Indexes accelerate search queries from $O(N)$ full-table scans to $O(\log N)$ B-Tree lookups:
- `idx_donors_blood_group` on `donors(blood_group_id)`
- `idx_donors_contact` on `donors(contact)`
- `idx_donations_date` on `donations(donation_date)`
- `idx_requests_status` on `blood_requests(status)`

---

## 🚀 Quick Start & Setup Guide

### 1. Prerequisites
- Python 3.9+ (Installed and on PATH)
- MySQL Server 8.0+ (Running on localhost:3306)

### 2. Configure Environment (`.env`)
Verify the `.env` file in the project root:
```ini
SECRET_KEY=change_this_to_a_random_secret_key
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=your_mysql_password
MYSQL_DB=blood_bank_db
PORT=5000
DEBUG=True
```

### 3. Install Dependencies
```bash
pip install -r requirements.txt
```

### 4. Initialize Database
Execute the automated database initializer:
```bash
python init_db.py
```
This automatically runs `schema.sql`, `sample_data.sql`, `views.sql`, `functions.sql`, `triggers.sql`, `procedures.sql`, and `cursor_demo.sql` in the exact dependency order and verifies all objects.

### 5. Start the Flask Server
```bash
python app.py
```
Open your browser and navigate to: **`http://127.0.0.1:5000`**

---

## 💻 How to Launch in VS Code Step-by-Step

1. Open VS Code.
2. Select **File &rarr; Open Folder...** and select the project folder.
3. Open the integrated terminal in VS Code (**Terminal &rarr; New Terminal** or `Ctrl + ~`).
4. Copy `.env.example` to `.env` and fill in your local MySQL credentials:
   ```powershell
   Copy-Item .env.example .env
   ```
5. Run the database initializer to verify the MySQL connection:
   ```powershell
   python init_db.py
   ```
6. Run the automated test suite to ensure all 11 unit tests pass:
   ```powershell
   python test_app.py
   ```
7. Start the web application:
   ```powershell
   python app.py
   ```
8. Click the URL `http://127.0.0.1:5000` or open it in any web browser.

---

## 🔍 MySQL CLI Commands Cheat Sheet

For college viva examinations, open Command Prompt or PowerShell and run:

### 1. Open MySQL and Authenticate
```bash
mysql -u root -p
# Enter your MySQL password when prompted
```

### 2. Select Database
```sql
USE blood_bank_db;
```

### 3. Show All Tables and Views
```sql
SHOW FULL TABLES;
```

### 4. Inspect Table Structures
```sql
DESCRIBE donors;
DESCRIBE blood_stock;
DESCRIBE donations;
DESCRIBE blood_requests;
```

### 5. View Stored Routines & Triggers
```sql
SHOW PROCEDURE STATUS WHERE Db = 'blood_bank_db';
SHOW FUNCTION STATUS WHERE Db = 'blood_bank_db';
SHOW TRIGGERS;
```

### 6. Query Table Records (Tabular Format)
```sql
SELECT * FROM blood_stock_view;
SELECT * FROM donor_details_view LIMIT 5;
SELECT * FROM donation_history_view LIMIT 5;
SELECT * FROM blood_requests_view LIMIT 5;
```

### 7. Execute Stored Procedures & Functions Manually
```sql
-- Call Cursor Procedure:
CALL sp_blood_stock_audit_cursor();

-- Call Stored Function:
SELECT blood_group_name, fn_get_available_units(id) AS units FROM blood_groups;

-- Call Stored Procedure:
CALL sp_get_donor_info(1);
```

---

## 🧪 Automated Testing Suite

The project includes an end-to-end automated unit test suite (`test_app.py`):
```bash
python test_app.py
```
### Verified Test Cases:
- `test_01_database_connection`: Direct MySQL connectivity and base tables.
- `test_02_dashboard_page`: Control center and live KPI rendering.
- `test_03_donors_page`: Donor directory table.
- `test_04_stock_page_and_cursor`: Stock inventory & MySQL Cursor audit execution.
- `test_05_donations_page`: Donation ledger.
- `test_06_requests_page`: Hospital requisition lifecycle.
- `test_07_reports_page`: Analytical report tabs.
- `test_08_sql_lab_page`: Interactive SQL Lab viva runner.
- `test_09_donor_lifecycle_sync`: Full Add &rarr; Edit &rarr; Delete cycle live in MySQL.
- `test_10_trigger_stock_sync_on_donation`: Trigger automatically increases stock on donation and decrements on deletion.
- `test_11_insufficient_stock_prevents_fulfillment`: Trigger blocks fulfillment when stock is insufficient.

---

## 🏆 Viva Key Takeaway Summary

| Concept | File | Demonstrated Routine / Query |
| :--- | :--- | :--- |
| **DDL** | `schema.sql` | `CREATE TABLE`, `ALTER TABLE`, `DROP TABLE` |
| **DML** | `sample_data.sql` | `INSERT`, `UPDATE`, `DELETE` |
| **DQL** | `queries.sql` | `SELECT` with `WHERE`, `ORDER BY`, `DISTINCT`, `LIMIT` |
| **Aggregates** | `queries.sql` | `COUNT()`, `SUM()`, `AVG()`, `MIN()`, `MAX()` |
| **Joins** | `views.sql` | `INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN` |
| **Subqueries** | `queries.sql` | Subqueries in `WHERE` and `HAVING` filters |
| **Views** | `views.sql` | `donor_details_view`, `blood_stock_view`, `donation_history_view`, `blood_requests_view` |
| **Procedures** | `procedures.sql` | `sp_record_donation`, `sp_update_stock`, `sp_fulfill_request` |
| **Functions** | `functions.sql` | `fn_get_available_units()`, `fn_get_stock_status_label()` |
| **Triggers** | `triggers.sql` | `trg_after_donation_insert`, `trg_before_blood_request_update`, etc. |
| **Cursors** | `cursor_demo.sql`| `sp_blood_stock_audit_cursor()` row-by-row iteration |
| **Indexes** | `schema.sql` | B-Tree indexes on `blood_group_id`, `contact`, `date`, `status` |
| **Transactions** | `procedures.sql`| `START TRANSACTION`, `COMMIT`, `ROLLBACK` |

---

## 📸 Screenshots & UI Previews

| Module | Description | Preview |
| :--- | :--- | :--- |
| **Executive Dashboard** | Live KPI summary cards (Total Donors, Units Available, Pending Requests), stock levels, and quick actions. | *(Screenshots can be added here)* |
| **Donor Directory** | Comprehensive donor management with search, filter, Add Donor, Edit Donor, and Safe Deletion modals. | *(Screenshots can be added here)* |
| **Blood Stock & Cursor Audit** | Live stock inventory per blood group and execution of the MySQL Cursor audit procedure. | *(Screenshots can be added here)* |
| **Donations Ledger** | Blood collection records with real-time MySQL trigger synchronization to inventory stock. | *(Screenshots can be added here)* |
| **Hospital Requisitions** | Request tracking from Pending to Fulfilled with automatic inventory deduction triggers. | *(Screenshots can be added here)* |
| **Analytical Reports** | Tabbed data views, exportable CSV tables, and print-ready summary reports. | *(Screenshots can be added here)* |
| **SQL Viva Lab** | Interactive SQL query tester for viva evaluation with syntax hints. | *(Screenshots can be added here)* |

---

## 👥 Team Members

| Name | Role | GitHub Username |
| :--- | :--- | :--- |
| **Nandhana Vinod** | Project Lead & Full-Stack Developer | `[GitHub Profile]` |
| *[Teammate Name]* | Collaborator & Database Developer | `[GitHub Username]` |

---

## 📄 License & Academic Integrity

This project is developed for academic learning and database management evaluation. Free to use and adapt for educational purposes.

