-- =============================================================================
-- Blood Bank Management System (BBMS) - Clean Table Presentation & Viva Guide
-- Database: blood_bank_db | RDBMS: MySQL 8.0+
-- File: database/clean_table_display.sql
-- =============================================================================
--
-- PURPOSE OF THIS SCRIPT:
-- ----------------------
-- When executing `SELECT * FROM table_name;` inside the MySQL Command Line
-- Client, tables with many columns (e.g., `donor`, `blood_request`, `hospital`)
-- often exceed standard terminal window width (80-120 columns). This causes
-- column headers and ASCII borders (+---+---+) to wrap onto subsequent lines,
-- resulting in broken, mangled, and difficult-to-read table output.
--
-- Date and time columns (`last_donation_date`, `created_at`, `last_updated`, etc.)
-- take up significant horizontal width. By omitting unnecessary dates and times
-- during presentation, every table fits cleanly on one screen without wrapping.
--
-- THIS SCRIPT PROVIDES:
-- 1. Non-destructive, horizontally aligned SELECT queries tailored to fit
--    within standard terminal widths for viva presentation (NO date/time columns).
-- 2. Meaningful JOIN queries that resolve numeric IDs into clear entity names.
-- 3. Professional column aliases (`Donor Name`, `Blood Group`, `Status`, etc.).
-- 4. Clean clinical metric formatting (e.g., Blood Pressure as 120/80).
-- 5. Reusable database VIEWS prefixed with `v_display_` that do NOT
--    replace or alter any original tables, constraints, or existing views.
-- 6. Comprehensive inspection, verification, and DBMS viva demonstration queries.
--
-- IMPORTANT SAFETY NOTE:
-- This script is completely non-destructive (DQL & safe CREATE OR REPLACE VIEW).
-- It does NOT alter table structures, drop base tables, delete data, or affect
-- Flask web application CRUD operations in any way.
-- =============================================================================

-- Step 1: Ensure active connection to the project database
USE blood_bank_db;

-- =============================================================================
-- SECTION 1: DATABASE OVERVIEW & TABLE VERIFICATION
-- =============================================================================

-- 1.1 Show all physical base tables in blood_bank_db
SELECT 
    TABLE_NAME AS `Base Table Name`,
    TABLE_ROWS AS `Approximate Rows`,
    TABLE_COLLATION AS `Collation`
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'blood_bank_db'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME ASC;

-- 1.2 Show all registered database views
SELECT 
    TABLE_NAME AS `View Name`,
    IS_UPDATABLE AS `Updatable`
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'blood_bank_db'
ORDER BY TABLE_NAME ASC;

-- 1.3 Exact live record counts across all 9 base tables
SELECT 'admin' AS `Table`, COUNT(*) AS `Total Rows` FROM admin
UNION ALL
SELECT 'blood_group', COUNT(*) FROM blood_group
UNION ALL
SELECT 'blood_stock', COUNT(*) FROM blood_stock
UNION ALL
SELECT 'hospital', COUNT(*) FROM hospital
UNION ALL
SELECT 'donor', COUNT(*) FROM donor
UNION ALL
SELECT 'donation', COUNT(*) FROM donation
UNION ALL
SELECT 'patient', COUNT(*) FROM patient
UNION ALL
SELECT 'blood_request', COUNT(*) FROM blood_request
UNION ALL
SELECT 'stock_transaction_log', COUNT(*) FROM stock_transaction_log;


-- =============================================================================
-- SECTION 2: CLEAN HORIZONTAL SELECT QUERIES (NO DATE/TIME - NO WRAPPING)
-- =============================================================================
-- These queries are specially formatted with column selection, aliases, and 
-- string limits so they fit neatly in horizontal ASCII borders without wrapping.

-- -----------------------------------------------------------------------------
-- 2.1 TABLE: admin (System Staff & Administrators)
-- Excludes password hash, login time, and created date for a clean display.
-- -----------------------------------------------------------------------------
SELECT 
    admin_id AS `ID`,
    username AS `Username`,
    full_name AS `Full Name`,
    role AS `Role`,
    email AS `Email Address`
FROM admin
ORDER BY admin_id ASC;


-- -----------------------------------------------------------------------------
-- 2.2 TABLE: blood_group (ABO & Rh Reference Entity)
-- Compact horizontal display query for presentation.
-- -----------------------------------------------------------------------------
SELECT 
    blood_group_id AS `ID`,
    group_name AS `Group`,
    rh_factor AS `Rh`,
    can_donate_to AS `Can Donate To`,
    can_receive_from AS `Can Receive From`
FROM blood_group
ORDER BY blood_group_id ASC;


-- -----------------------------------------------------------------------------
-- 2.3 TABLE: blood_stock (Current Inventory & Threshold Levels)
-- Excludes last_updated timestamp; replaces numeric ID with Blood Group name.
-- -----------------------------------------------------------------------------
SELECT 
    bs.stock_id AS `Stock ID`,
    bg.group_name AS `Blood Group`,
    bs.total_units AS `Available Units`,
    bs.threshold_low AS `Min Threshold`,
    CASE 
        WHEN bs.total_units = 0 THEN 'OUT OF STOCK'
        WHEN bs.total_units <= bs.threshold_low THEN 'CRITICAL LOW'
        WHEN bs.total_units <= (bs.threshold_low * 2) THEN 'MODERATE'
        ELSE 'ADEQUATE'
    END AS `Stock Status`
FROM blood_stock bs
JOIN blood_group bg ON bs.blood_group_id = bg.blood_group_id
ORDER BY bg.blood_group_id ASC;


-- -----------------------------------------------------------------------------
-- 2.4 TABLE: hospital (Partner Healthcare Facilities)
-- Excludes created_at timestamp; summarizes address for clean horizontal fit.
-- -----------------------------------------------------------------------------
SELECT 
    hospital_id AS `ID`,
    hospital_name AS `Hospital Name`,
    license_number AS `License No`,
    contact_number AS `Phone`,
    emergency_contact AS `Emergency Line`,
    LEFT(address, 28) AS `Address Summary`
FROM hospital
ORDER BY hospital_id ASC;


-- -----------------------------------------------------------------------------
-- 2.5 TABLE: donor (Registered Voluntary Donors)
-- Excludes last_donation_date and created_at timestamps!
-- Replaces numeric blood_group_id with Group Name and 1/0 with Yes/No.
-- -----------------------------------------------------------------------------
SELECT 
    d.donor_id AS `ID`,
    d.name AS `Donor Name`,
    d.age AS `Age`,
    d.gender AS `Gender`,
    bg.group_name AS `Blood`,
    d.phone AS `Phone`,
    CASE WHEN d.medical_clearance = 1 THEN 'Yes' ELSE 'No' END AS `Cleared`,
    LEFT(d.address, 25) AS `City / Area`
FROM donor d
JOIN blood_group bg ON d.blood_group_id = bg.blood_group_id
ORDER BY d.donor_id ASC;


-- -----------------------------------------------------------------------------
-- 2.6 TABLE: donation (Blood Unit Collection History)
-- Excludes donation_date and created_at timestamps.
-- Combines BP into clinical format (120/80) and resolves Staff name.
-- -----------------------------------------------------------------------------
SELECT 
    dn.donation_id AS `ID`,
    d.name AS `Donor Name`,
    bg.group_name AS `Blood`,
    dn.units AS `Units`,
    dn.hemoglobin_level AS `Hb (g/dL)`,
    CONCAT(dn.systolic_bp, '/', dn.diastolic_bp) AS `BP (mmHg)`,
    COALESCE(adm.full_name, 'System') AS `Staff Incharge`
FROM donation dn
JOIN donor d ON dn.donor_id = d.donor_id
JOIN blood_group bg ON dn.blood_group_id = bg.blood_group_id
LEFT JOIN admin adm ON dn.recorded_by = adm.admin_id
ORDER BY dn.donation_id ASC;


-- -----------------------------------------------------------------------------
-- 2.7 TABLE: patient (Transfusion Requisition Patients)
-- Excludes created_at timestamp.
-- -----------------------------------------------------------------------------
SELECT 
    p.patient_id AS `ID`,
    p.patient_name AS `Patient Name`,
    p.age AS `Age`,
    p.gender AS `Gender`,
    bg.group_name AS `Blood`,
    h.hospital_name AS `Admitted Hospital`,
    p.contact_number AS `Contact`,
    LEFT(p.medical_condition, 30) AS `Medical Diagnosis`
FROM patient p
JOIN blood_group bg ON p.blood_group_id = bg.blood_group_id
LEFT JOIN hospital h ON p.hospital_id = h.hospital_id
ORDER BY p.patient_id ASC;


-- -----------------------------------------------------------------------------
-- 2.8 TABLE: blood_request (Transfusion Requests & Approval Status)
-- Excludes request_date, approval_date, and created_at timestamps.
-- -----------------------------------------------------------------------------
SELECT 
    br.request_id AS `Req ID`,
    p.patient_name AS `Patient Name`,
    h.hospital_name AS `Hospital`,
    bg.group_name AS `Blood`,
    br.units_requested AS `Units`,
    br.urgency_level AS `Urgency`,
    br.status AS `Status`,
    COALESCE(adm.full_name, '-') AS `Approved By`
FROM blood_request br
JOIN patient p ON br.patient_id = p.patient_id
JOIN hospital h ON br.hospital_id = h.hospital_id
JOIN blood_group bg ON br.blood_group_id = bg.blood_group_id
LEFT JOIN admin adm ON br.approved_by = adm.admin_id
ORDER BY br.request_id ASC;


-- -----------------------------------------------------------------------------
-- 2.9 TABLE: stock_transaction_log (Inventory Audit Trail)
-- Excludes created_at timestamp.
-- -----------------------------------------------------------------------------
SELECT 
    stl.log_id AS `Log #`,
    bg.group_name AS `Blood`,
    stl.transaction_type AS `Operation Type`,
    CASE 
        WHEN stl.units_changed > 0 THEN CONCAT('+', stl.units_changed) 
        ELSE CAST(stl.units_changed AS CHAR) 
    END AS `Units (+/-)`,
    IFNULL(stl.reference_id, '-') AS `Ref ID`,
    LEFT(stl.remarks, 40) AS `Audit Description`
FROM stock_transaction_log stl
JOIN blood_group bg ON stl.blood_group_id = bg.blood_group_id
ORDER BY stl.log_id DESC;


-- =============================================================================
-- SECTION 3: REUSABLE PRESENTATION VIEWS (`v_display_...`)
-- =============================================================================
-- Note: These views omit date and time for clean, ultra-compact output.
-- Use prefix `v_display_` to avoid conflicts with application views.
-- =============================================================================

-- View 1: Clean Administrator View
CREATE OR REPLACE VIEW v_display_admin AS
SELECT 
    admin_id AS `ID`,
    username AS `Username`,
    full_name AS `Full Name`,
    role AS `Role`,
    email AS `Email`
FROM admin;

-- View 2: Clean Blood Group Reference View
CREATE OR REPLACE VIEW v_display_blood_groups AS
SELECT 
    blood_group_id AS `ID`,
    group_name AS `Blood Group`,
    rh_factor AS `Rh Factor`,
    can_donate_to AS `Can Donate To`,
    can_receive_from AS `Can Receive From`
FROM blood_group;

-- View 3: Clean Blood Stock Inventory View
CREATE OR REPLACE VIEW v_display_blood_stock AS
SELECT 
    bs.stock_id AS `Stock ID`,
    bg.group_name AS `Blood Group`,
    bs.total_units AS `Available Units`,
    bs.threshold_low AS `Min Threshold`,
    CASE 
        WHEN bs.total_units = 0 THEN 'OUT OF STOCK'
        WHEN bs.total_units <= bs.threshold_low THEN 'CRITICAL LOW'
        WHEN bs.total_units <= (bs.threshold_low * 2) THEN 'MODERATE'
        ELSE 'ADEQUATE'
    END AS `Stock Status`
FROM blood_stock bs
JOIN blood_group bg ON bs.blood_group_id = bg.blood_group_id;

-- View 4: Clean Hospital Directory View
CREATE OR REPLACE VIEW v_display_hospitals AS
SELECT 
    hospital_id AS `ID`,
    hospital_name AS `Hospital Name`,
    license_number AS `License No`,
    contact_number AS `Phone`,
    emergency_contact AS `Emergency Line`,
    LEFT(address, 28) AS `Address Summary`
FROM hospital;

-- View 5: Clean Donor Registry View (NO DATE OR TIME)
CREATE OR REPLACE VIEW v_display_donors AS
SELECT 
    d.donor_id AS `ID`,
    d.name AS `Donor Name`,
    d.age AS `Age`,
    d.gender AS `Gender`,
    bg.group_name AS `Blood`,
    d.phone AS `Phone`,
    CASE WHEN d.medical_clearance = 1 THEN 'Yes' ELSE 'No' END AS `Cleared`,
    LEFT(d.address, 25) AS `City / Area`
FROM donor d
JOIN blood_group bg ON d.blood_group_id = bg.blood_group_id;

-- View 6: Clean Donation Logs View
CREATE OR REPLACE VIEW v_display_donations AS
SELECT 
    dn.donation_id AS `ID`,
    d.name AS `Donor Name`,
    bg.group_name AS `Blood`,
    dn.units AS `Units`,
    dn.hemoglobin_level AS `Hb (g/dL)`,
    CONCAT(dn.systolic_bp, '/', dn.diastolic_bp) AS `BP (mmHg)`,
    COALESCE(adm.full_name, 'System') AS `Staff Incharge`
FROM donation dn
JOIN donor d ON dn.donor_id = d.donor_id
JOIN blood_group bg ON dn.blood_group_id = bg.blood_group_id
LEFT JOIN admin adm ON dn.recorded_by = adm.admin_id;

-- View 7: Clean Patient Register View
CREATE OR REPLACE VIEW v_display_patients AS
SELECT 
    p.patient_id AS `ID`,
    p.patient_name AS `Patient Name`,
    p.age AS `Age`,
    p.gender AS `Gender`,
    bg.group_name AS `Blood`,
    h.hospital_name AS `Admitted Hospital`,
    p.contact_number AS `Contact`,
    LEFT(p.medical_condition, 30) AS `Medical Diagnosis`
FROM patient p
JOIN blood_group bg ON p.blood_group_id = bg.blood_group_id
LEFT JOIN hospital h ON p.hospital_id = h.hospital_id;

-- View 8: Clean Blood Requests View
CREATE OR REPLACE VIEW v_display_blood_requests AS
SELECT 
    br.request_id AS `Req ID`,
    p.patient_name AS `Patient Name`,
    h.hospital_name AS `Hospital`,
    bg.group_name AS `Blood`,
    br.units_requested AS `Units`,
    br.urgency_level AS `Urgency`,
    br.status AS `Status`,
    COALESCE(adm.full_name, '-') AS `Approved By`
FROM blood_request br
JOIN patient p ON br.patient_id = p.patient_id
JOIN hospital h ON br.hospital_id = h.hospital_id
JOIN blood_group bg ON br.blood_group_id = bg.blood_group_id
LEFT JOIN admin adm ON br.approved_by = adm.admin_id;

-- View 9: Clean Stock Audit Trail View
CREATE OR REPLACE VIEW v_display_stock_audit AS
SELECT 
    stl.log_id AS `Log #`,
    bg.group_name AS `Blood`,
    stl.transaction_type AS `Operation Type`,
    CASE 
        WHEN stl.units_changed > 0 THEN CONCAT('+', stl.units_changed) 
        ELSE CAST(stl.units_changed AS CHAR) 
    END AS `Units (+/-)`,
    IFNULL(stl.reference_id, '-') AS `Ref ID`,
    LEFT(stl.remarks, 40) AS `Audit Description`
FROM stock_transaction_log stl
JOIN blood_group bg ON stl.blood_group_id = bg.blood_group_id;


-- =============================================================================
-- SECTION 4: VERTICAL RECORD INSPECTION (WHEN COMPLETE DETAILS ARE NEEDED)
-- =============================================================================
-- When an examiner asks to inspect complete records of a wide table, use \G:
-- SELECT * FROM donor WHERE donor_id = 1\G
-- SELECT * FROM blood_request WHERE request_id = 2\G

-- =============================================================================
-- SECTION 5: SCRIPT EXECUTION & VERIFICATION TEST
-- =============================================================================
SELECT 'v_display_admin' AS `Testing View`, COUNT(*) AS `Rows` FROM v_display_admin
UNION ALL
SELECT 'v_display_blood_groups', COUNT(*) FROM v_display_blood_groups
UNION ALL
SELECT 'v_display_blood_stock', COUNT(*) FROM v_display_blood_stock
UNION ALL
SELECT 'v_display_hospitals', COUNT(*) FROM v_display_hospitals
UNION ALL
SELECT 'v_display_donors', COUNT(*) FROM v_display_donors
UNION ALL
SELECT 'v_display_donations', COUNT(*) FROM v_display_donations
UNION ALL
SELECT 'v_display_patients', COUNT(*) FROM v_display_patients
UNION ALL
SELECT 'v_display_blood_requests', COUNT(*) FROM v_display_blood_requests
UNION ALL
SELECT 'v_display_stock_audit', COUNT(*) FROM v_display_stock_audit;

-- =============================================================================
-- END OF SCRIPT: clean_table_display.sql
-- =============================================================================
