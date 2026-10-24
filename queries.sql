-- ============================================================================
-- Blood Bank Management System (BBMS)
-- Simplified Queries Reference: queries.sql
-- All queries written as simple and readable as possible for easy viva/presentation
-- ============================================================================

USE blood_bank_db;

-- ============================================================================
-- 1. BASIC SELECT QUERIES (DQL)
-- ============================================================================

-- 1.1 Show all blood groups
SELECT * FROM blood_groups;

-- 1.2 Show all donors with specific columns
SELECT id, full_name, age, gender, contact, city FROM donors;

-- 1.3 Filter with WHERE condition: Donors from Mumbai
SELECT full_name, contact, city FROM donors WHERE city = 'Mumbai';

-- 1.4 Filter with multiple conditions: Male donors older than 25
SELECT full_name, age, gender FROM donors WHERE gender = 'Male' AND age > 25;

-- 1.5 Sort results using ORDER BY: Donors sorted by youngest first
SELECT full_name, age, city FROM donors ORDER BY age ASC;

-- 1.6 Limit results: Get top 3 youngest donors
SELECT full_name, age, city FROM donors ORDER BY age ASC LIMIT 3;

-- 1.7 Find unique values using DISTINCT: Unique cities
SELECT DISTINCT city FROM donors;


-- ============================================================================
-- 2. AGGREGATE FUNCTIONS (COUNT, SUM, AVG, MIN, MAX)
-- ============================================================================

-- 2.1 Total number of donors registered
SELECT COUNT(*) AS total_donors FROM donors;

-- 2.2 Total blood units available across all groups
SELECT SUM(available_units) AS total_units_in_stock FROM blood_stock;

-- 2.3 Average, minimum, and maximum age of donors
SELECT 
    AVG(age) AS average_age,
    MIN(age) AS youngest_age,
    MAX(age) AS oldest_age
FROM donors;


-- ============================================================================
-- 3. GROUP BY AND HAVING
-- ============================================================================

-- 3.1 Count donors per city
SELECT city, COUNT(*) AS donor_count
FROM donors
GROUP BY city;

-- 3.2 Count donors per blood group
SELECT blood_group_id, COUNT(*) AS total_donors
FROM donors
GROUP BY blood_group_id;

-- 3.3 GROUP BY with HAVING: Cities that have more than 1 donor
SELECT city, COUNT(*) AS donor_count
FROM donors
GROUP BY city
HAVING COUNT(*) > 1;


-- ============================================================================
-- 4. JOINS (INNER JOIN & LEFT JOIN)
-- ============================================================================

-- 4.1 Simple INNER JOIN: Show donor name with blood group name
SELECT 
    donors.full_name, 
    blood_groups.blood_group_name, 
    donors.city
FROM donors
INNER JOIN blood_groups ON donors.blood_group_id = blood_groups.id;

-- 4.2 INNER JOIN: Show donations with donor name and blood group
SELECT 
    donations.id AS donation_id,
    donors.full_name,
    blood_groups.blood_group_name,
    donations.donation_date,
    donations.units
FROM donations
INNER JOIN donors ON donations.donor_id = donors.id
INNER JOIN blood_groups ON donations.blood_group_id = blood_groups.id;

-- 4.3 LEFT JOIN: Show all donors and their total donation count
SELECT 
    donors.full_name,
    COUNT(donations.id) AS total_donations
FROM donors
LEFT JOIN donations ON donors.id = donations.donor_id
GROUP BY donors.id, donors.full_name;


-- ============================================================================
-- 5. SUBQUERIES (NESTED SELECT)
-- ============================================================================

-- 5.1 Subquery with IN: Find donors whose blood group has low stock (< 10 units)
SELECT full_name, city
FROM donors
WHERE blood_group_id IN (
    SELECT blood_group_id FROM blood_stock WHERE available_units < 10
);

-- 5.2 Subquery with Comparison: Find donors older than the average donor age
SELECT full_name, age
FROM donors
WHERE age > (SELECT AVG(age) FROM donors);


-- ============================================================================
-- 6. VIEWS (PRE-BUILT QUERIES)
-- ============================================================================

-- 6.1 View current blood stock status
SELECT * FROM blood_stock_view;

-- 6.2 View donor details with blood group
SELECT donor_id, full_name, blood_group_name, city FROM donor_details_view;

-- 6.3 View donation history
SELECT donation_id, donor_name, blood_group_name, units, donation_date FROM donation_history_view;

-- 6.4 View hospital blood requests
SELECT request_id, hospital_name, blood_group_name, units_requested, status FROM blood_requests_view;


-- ============================================================================
-- 7. STORED PROCEDURES
-- ============================================================================

-- 7.1 Call procedure to view donor profile (Donor ID 1)
CALL sp_get_donor_info(1);

-- 7.2 Call procedure to update blood stock (Add 1 unit to Blood Group 1)
CALL sp_update_stock(1, 1, 'ADD');

-- 7.3 Call cursor procedure: Audits each blood group row-by-row
CALL sp_blood_stock_audit_cursor();


-- ============================================================================
-- 8. STORED FUNCTIONS
-- ============================================================================

-- 8.1 Get available units for a blood group (ID 1 = A+)
SELECT fn_get_available_units(1) AS available_units;

-- 8.2 Get stock status label based on unit count
SELECT fn_get_stock_status_label(12) AS status_label;


-- ============================================================================
-- 9. TRIGGERS DEMONSTRATION (AUTOMATIC INVENTORY UPDATE)
-- ============================================================================

-- Step A: Check stock before donation for Blood Group 1 (A+)
SELECT blood_group_id, available_units FROM blood_stock WHERE blood_group_id = 1;

-- Step B: Insert donation (Trigger trg_after_donation_insert fires automatically!)
INSERT INTO donations (donor_id, blood_group_id, donation_date, units)
VALUES (1, 1, CURDATE(), 1);

-- Step C: Check stock after donation (Notice units incremented by 1)
SELECT blood_group_id, available_units FROM blood_stock WHERE blood_group_id = 1;


-- ============================================================================
-- 10. DML (INSERT, UPDATE, DELETE)
-- ============================================================================

-- 10.1 INSERT: Add a new donor
INSERT INTO donors (full_name, blood_group_id, age, gender, contact, city)
VALUES ('Rohan Verma', 1, 24, 'Male', '9876543219', 'Delhi');

-- 10.2 UPDATE: Update donor's city
UPDATE donors
SET city = 'Noida'
WHERE contact = '9876543219';

-- 10.3 DELETE: Delete the newly added test donor
DELETE FROM donors
WHERE contact = '9876543219';
