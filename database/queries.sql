-- =============================================================================
-- Blood Bank Management System (BBMS) - Comprehensive DBMS SQL Demonstration
-- Contains categorized SQL queries for Viva Voce, Labs, and Project Presentation
-- =============================================================================

USE blood_bank_db;

-- =============================================================================
-- SECTION 1: DDL & SCHEMA INSPECTION
-- =============================================================================

-- View all database tables
SHOW TABLES;

-- Inspect table structures with columns, data types, and primary keys
DESCRIBE donor;
DESCRIBE blood_stock;
DESCRIBE blood_request;

-- View foreign key constraints
SELECT 
    TABLE_NAME, 
    COLUMN_NAME, 
    CONSTRAINT_NAME, 
    REFERENCED_TABLE_NAME, 
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'blood_bank_db' 
  AND REFERENCED_TABLE_NAME IS NOT NULL;

-- =============================================================================
-- SECTION 2: BASIC CRUD OPERATIONS (Data Manipulation Language)
-- =============================================================================

-- CREATE (Insert a new donor)
INSERT INTO donor (name, age, gender, blood_group_id, phone, email, address, medical_clearance)
VALUES ('Alexander Wright', 30, 'Male', 1, '+1-555-8899', 'alex.w@email.com', '710 Broadway Ave, Downtown', 1);

-- READ (Select donor by ID)
SELECT * FROM donor WHERE donor_id = 1;

-- UPDATE (Update donor contact and address)
UPDATE donor 
SET phone = '+1-555-9988', address = '999 New Haven St, Uptown' 
WHERE donor_id = 1;

-- DELETE (Delete donor record - demonstrates referential integrity check)
-- Will succeed if donor has no foreign key dependencies in donation table
DELETE FROM donor WHERE donor_id = 11;

-- =============================================================================
-- SECTION 3: RELATIONAL JOINS (Inner, Left Outer, Multi-Table)
-- =============================================================================

-- Query 3.1: INNER JOIN - Donors with their respective Blood Group Names
SELECT 
    d.donor_id,
    d.name AS donor_name,
    d.age,
    d.gender,
    bg.group_name AS blood_group,
    d.phone,
    d.last_donation_date
FROM donor d
INNER JOIN blood_group bg ON d.blood_group_id = bg.blood_group_id
ORDER BY d.name ASC;

-- Query 3.2: 4-TABLE INNER JOIN - Blood Requests with Patient, Hospital & Group Details
SELECT 
    br.request_id,
    p.patient_name,
    p.age AS patient_age,
    h.hospital_name,
    h.contact_number AS hospital_contact,
    bg.group_name AS blood_group,
    br.units_requested,
    br.urgency_level,
    br.status,
    br.request_date
FROM blood_request br
JOIN patient p ON br.patient_id = p.patient_id
JOIN hospital h ON br.hospital_id = h.hospital_id
JOIN blood_group bg ON br.blood_group_id = bg.blood_group_id
WHERE br.status = 'Pending'
ORDER BY br.request_date ASC;

-- Query 3.3: LEFT OUTER JOIN - Hospitals and count of requests (including hospitals with 0 requests)
SELECT 
    h.hospital_name,
    h.contact_number,
    COUNT(br.request_id) AS total_requests_placed
FROM hospital h
LEFT JOIN blood_request br ON h.hospital_id = br.hospital_id
GROUP BY h.hospital_id, h.hospital_name, h.contact_number
ORDER BY total_requests_placed DESC;

-- Query 3.4: Multi-Table JOIN with Audit trail for Donation History
SELECT 
    dn.donation_id,
    d.name AS donor_name,
    bg.group_name AS blood_group,
    dn.units,
    dn.donation_date,
    dn.hemoglobin_level,
    COALESCE(adm.full_name, 'System Admin') AS recorded_by_staff
FROM donation dn
JOIN donor d ON dn.donor_id = d.donor_id
JOIN blood_group bg ON dn.blood_group_id = bg.blood_group_id
LEFT JOIN admin adm ON dn.recorded_by = adm.admin_id
ORDER BY dn.donation_date DESC;

-- =============================================================================
-- SECTION 4: AGGREGATE FUNCTIONS & GROUP BY WITH HAVING
-- =============================================================================

-- Query 4.1: Aggregates - Overall Blood Bank Metrics
SELECT 
    COUNT(DISTINCT d.donor_id) AS total_donors,
    SUM(bs.total_units) AS total_available_blood_units,
    AVG(bs.total_units) AS avg_units_per_group,
    MIN(bs.total_units) AS lowest_stocked_units,
    MAX(bs.total_units) AS highest_stocked_units
FROM blood_stock bs
CROSS JOIN donor d;

-- Query 4.2: GROUP BY with SUM and COUNT - Total donations per Blood Group
SELECT 
    bg.group_name,
    COUNT(d.donation_id) AS donation_count,
    SUM(d.units) AS total_units_collected,
    ROUND(AVG(d.hemoglobin_level), 2) AS avg_donor_hemoglobin
FROM blood_group bg
LEFT JOIN donation d ON bg.blood_group_id = d.blood_group_id
GROUP BY bg.blood_group_id, bg.group_name
ORDER BY total_units_collected DESC;

-- Query 4.3: GROUP BY with HAVING Clause
-- Find hospitals that have requested more than 1 total blood unit
SELECT 
    h.hospital_name,
    COUNT(br.request_id) AS request_count,
    SUM(br.units_requested) AS total_units_demanded
FROM hospital h
JOIN blood_request br ON h.hospital_id = br.hospital_id
GROUP BY h.hospital_id, h.hospital_name
HAVING SUM(br.units_requested) > 1
ORDER BY total_units_demanded DESC;

-- Query 4.4: Blood Request Status distribution
SELECT 
    status,
    COUNT(*) AS count_requests,
    SUM(units_requested) AS total_units
FROM blood_request
GROUP BY status;

-- =============================================================================
-- SECTION 5: SUBQUERIES (Nested, Scalar, IN, EXISTS)
-- =============================================================================

-- Query 5.1: Subquery with IN - Donors who have NEVER donated blood yet
SELECT donor_id, name, phone, email, last_donation_date
FROM donor
WHERE donor_id NOT IN (
    SELECT DISTINCT donor_id FROM donation
);

-- Query 5.2: Correlated Subquery with EXISTS - Blood groups currently facing critical low stock
SELECT bg.group_name, bg.can_donate_to, bg.can_receive_from
FROM blood_group bg
WHERE EXISTS (
    SELECT 1 
    FROM blood_stock bs 
    WHERE bs.blood_group_id = bg.blood_group_id 
      AND bs.total_units <= bs.threshold_low
);

-- Query 5.3: Scalar Subquery in WHERE - Blood groups with stock above overall average
SELECT 
    bg.group_name,
    bs.total_units
FROM blood_stock bs
JOIN blood_group bg ON bs.blood_group_id = bg.blood_group_id
WHERE bs.total_units > (
    SELECT AVG(total_units) FROM blood_stock
)
ORDER BY bs.total_units DESC;

-- Query 5.4: Subquery in FROM clause (Derived Table)
-- Calculate donation frequency per donor and join with donor details
SELECT 
    d.name,
    d.phone,
    stats.donation_count,
    stats.total_donated_units
FROM donor d
JOIN (
    SELECT donor_id, COUNT(*) AS donation_count, SUM(units) AS total_donated_units
    FROM donation
    GROUP BY donor_id
) stats ON d.donor_id = stats.donor_id
ORDER BY stats.total_donated_units DESC;

-- =============================================================================
-- SECTION 6: ADVANCED SEARCH & BLOOD COMPATIBILITY LOGIC
-- =============================================================================

-- Query 6.1: Search donors eligible to donate right now (no donation in past 90 days)
SELECT 
    d.donor_id,
    d.name,
    bg.group_name,
    d.phone,
    d.last_donation_date,
    DATEDIFF(CURRENT_DATE, d.last_donation_date) AS days_since_last_donation
FROM donor d
JOIN blood_group bg ON d.blood_group_id = bg.blood_group_id
WHERE d.medical_clearance = 1 
  AND (d.last_donation_date IS NULL OR DATEDIFF(CURRENT_DATE, d.last_donation_date) >= 90)
ORDER BY days_since_last_donation DESC;

-- Query 6.2: Search compatible stock for emergency patient needing B- blood
-- B- can receive from: B-, O-
SELECT 
    bg.group_name,
    bs.total_units,
    CASE 
        WHEN bg.group_name = 'B-' THEN 'Exact Match'
        WHEN bg.group_name = 'O-' THEN 'Universal Donor Match'
        ELSE 'Incompatible'
    END AS match_type
FROM blood_stock bs
JOIN blood_group bg ON bs.blood_group_id = bg.blood_group_id
WHERE bg.group_name IN ('B-', 'O-')
ORDER BY bs.total_units DESC;

-- =============================================================================
-- SECTION 7: ATOMIC TRANSACTIONS (ACID Properties Demonstration)
-- =============================================================================

-- Transaction 7.1: Recording a New Blood Donation (Increments stock & updates donor)
START TRANSACTION;

-- Step 1: Record new donation
INSERT INTO donation (donor_id, blood_group_id, units, donation_date, hemoglobin_level, systolic_bp, diastolic_bp, notes, recorded_by)
VALUES (1, 1, 1, CURRENT_DATE(), 14.5, 120, 80, 'Walk-in voluntary donation', 1);

-- Step 2: Update donor's last donation date
UPDATE donor 
SET last_donation_date = CURRENT_DATE()
WHERE donor_id = 1;

-- Step 3: Increment corresponding blood stock units
UPDATE blood_stock 
SET total_units = total_units + 1 
WHERE blood_group_id = 1;

-- Step 4: Record stock audit entry
INSERT INTO stock_transaction_log (blood_group_id, transaction_type, units_changed, reference_id, remarks)
VALUES (1, 'DONATION', 1, LAST_INSERT_ID(), 'Stock incremented via donation');

-- Commit transaction ensuring all operations execute atomically
COMMIT;


-- Transaction 7.2: Approving a Blood Request (Safe stock validation & deduction)
START TRANSACTION;

-- Step 1: Check availability (e.g. for Request ID 3, blood_group_id = 7, units = 2)
-- If total_units >= 2, proceed with deduction:
UPDATE blood_stock 
SET total_units = total_units - 2 
WHERE blood_group_id = 7 AND total_units >= 2;

-- Step 2: Mark request as approved with timestamp and admin ID
UPDATE blood_request 
SET status = 'Approved', 
    approval_date = NOW(), 
    approved_by = 1,
    remarks = 'Approved and issued to hospital'
WHERE request_id = 3 AND status = 'Pending';

-- Step 3: Audit log
INSERT INTO stock_transaction_log (blood_group_id, transaction_type, units_changed, reference_id, remarks)
VALUES (7, 'REQUEST_ISSUE', -2, 3, 'Stock deducted for approved request #3');

-- If any step failed, execute: ROLLBACK;
-- Otherwise commit changes:
COMMIT;

-- =============================================================================
-- SECTION 8: STORED PROCEDURES & TRIGGERS
-- =============================================================================

DELIMITER $$

-- Procedure: Get comprehensive stock health report
CREATE PROCEDURE sp_get_blood_bank_kpis()
BEGIN
    SELECT 
        (SELECT COUNT(*) FROM donor) AS total_donors,
        (SELECT COALESCE(SUM(total_units), 0) FROM blood_stock) AS total_stock_units,
        (SELECT COUNT(*) FROM blood_request WHERE status = 'Pending') AS pending_requests,
        (SELECT COUNT(*) FROM hospital) AS total_hospitals,
        (SELECT COUNT(*) FROM donation) AS total_donations;
END$$

-- Trigger: Automatically audit manual blood stock updates
CREATE TRIGGER trg_after_stock_update
AFTER UPDATE ON blood_stock
FOR EACH ROW
BEGIN
    IF NEW.total_units <> OLD.total_units THEN
        INSERT INTO stock_transaction_log (
            blood_group_id, 
            transaction_type, 
            units_changed, 
            remarks
        ) VALUES (
            NEW.blood_group_id, 
            'MANUAL_ADJUSTMENT', 
            NEW.total_units - OLD.total_units, 
            CONCAT('Units updated from ', OLD.total_units, ' to ', NEW.total_units)
        );
    END IF;
END$$

DELIMITER ;
