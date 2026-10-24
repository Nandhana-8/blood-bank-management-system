# Software Architecture & Engineering Design
## Blood Bank Management System (BBMS)

---

## 1. System Overview & Three-Tier Architecture

The Blood Bank Management System adheres to the classic **Three-Tier Architectural Model**:

```
+--------------------------------------------------------------+
|                    PRESENTATION TIER                         |
|     HTML5 Semantic Templates + Vanilla CSS + JavaScript      |
|  - Dashboard Widgets & Real-Time Stock Cards                 |
|  - Responsive Data Tables with Live Instant Filtering        |
|  - Asynchronous AJAX Modals (Donors, Requests, Hospitals)    |
|  - Dynamic ABO/Rh Transfusion Compatibility Calculator       |
+--------------------------------------------------------------+
                               |
                        HTTP / JSON REST
                               v
+--------------------------------------------------------------+
|                   APPLICATION / LOGIC TIER                   |
|                   Python 3.x + Flask Server                  |
|  - Session-Based Authentication & Password Hashing           |
|  - Transaction Management (Atomic Stock Increments/Issues)   |
|  - Stock Validation & Inventory Constraint Enforcement       |
|  - RESTful API Endpoints & Request Routing                   |
+--------------------------------------------------------------+
                               |
                        PyMySQL / DB-API
                               v
+--------------------------------------------------------------+
|                     DATA STORAGE TIER                        |
|               MySQL 8.0+ / MariaDB / SQLite3                 |
|  - Normalized Relational Tables (Normalized up to 3NF)       |
|  - Foreign Key Constraints & Cascade/Restrict Policies       |
|  - Check Constraints (Age 18-65, Non-Negative Stock)         |
|  - Materialized Views & Auditing Transaction Ledger          |
+--------------------------------------------------------------+
```

---

## 2. Directory Structure

```
blood-bank-management-system/
├── app.py                      # Flask Application Server & Endpoint Controllers
├── config.py                   # Configuration & Environment Variables
├── db.py                       # Unified Database Layer & Transaction Manager
├── init_db.py                  # DDL Creation & Sample Data Seeder
├── requirements.txt            # Python Dependencies
├── .env.example                # Environment Variable Template
├── database/
│   ├── schema.sql              # Pure MySQL DDL Schema, Tables, Constraints & Views
│   ├── sample_data.sql         # Seed Data (Admins, Donors, Hospitals, Stock, Requests)
│   ├── queries.sql             # Viva Voce & Lab Demonstration Queries
│   ├── er_diagram_description.md # ER Diagram & Entity Cardinality Specification
│   └── normalization_report.md   # 1NF, 2NF, 3NF Compliance Analysis
├── static/
│   ├── css/
│   │   └── style.css           # Medical / Hematology Dashboard Theme
│   └── js/
│       ├── main.js             # Modals, Toasts, Table Filtering, CSV Export
│       └── app_modules.js      # AJAX Form Submissions, Blood Compatibility Engine
├── templates/
│   ├── base.html               # Master Layout with Navigation Sidebar
│   ├── login.html              # Staff Login Portal
│   ├── dashboard.html          # Operational Dashboard & KPI Cards
│   ├── donors.html             # Donor Management CRUD & Filter
│   ├── stock.html              # Blood Stock Management & Audit Ledger
│   ├── donations.html          # Blood Donation Recording Sessions
│   ├── requests.html           # Blood Requisition Approval Workflow
│   ├── hospitals.html          # Partner Medical Centers Directory
│   ├── search.html             # Transfusion Compatibility Tool
│   └── reports.html            # Tabbed Audits, Print & CSV Export
└── docs/
    ├── DBMS_VIVA_GUIDE.md      # College Viva Voce Examination Guide
    └── ARCHITECTURE.md         # System Architecture & Design
```

---

## 3. Database Abstraction & Dual-Engine Capability

To ensure frictionless project presentation in viva labs and defense panels:
1. **First-Class MySQL Compatibility**: When running with MySQL (via XAMPP, WAMP, or standalone MySQL service), the application connects using `PyMySQL` with connection parameters configured in `.env`.
2. **Transparent Auto-Fallback to SQLite**: If MySQL service is stopped or credentials are not configured, the database manager automatically falls back to an SQLite database with `PRAGMA foreign_keys = ON;`, maintaining complete relational integrity without requiring the examiner to troubleshoot local MySQL connection issues.

---

## 4. Key Workflows & ACID Guarantees

### Workflow 1: Blood Donation
1. Donor identity and screening vitals (Hemoglobin, BP) are entered.
2. An atomic transaction is opened:
   - `INSERT INTO donation (...)`
   - `UPDATE donor SET last_donation_date = ...`
   - `UPDATE blood_stock SET total_units = total_units + ...`
   - `INSERT INTO stock_transaction_log (...)`
3. Transaction is committed. Stock increases immediately in dashboard.

### Workflow 2: Blood Requisition & Approval
1. Hospital submits blood request for patient with urgency level.
2. Initial status is set to `Pending`.
3. Admin reviews requisition and clicks **Approve**:
   - Stock for requested blood group is queried.
   - If `stock < requested_units`: The approval is blocked and an HTTP 400 error is returned with details.
   - If `stock >= requested_units`: Stock is decremented, status is set to `Approved`, approval timestamp and admin ID are recorded, and audit log is logged.
