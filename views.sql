-- ============================================================================
-- Blood Bank Management System (BBMS)
-- Database Views: views.sql
-- Implements reusable abstracted query views demonstrating:
-- INNER JOIN, LEFT JOIN, Aggregations (COUNT, SUM), and Conditional CASE expressions
-- ============================================================================

USE blood_bank_db;

-- ----------------------------------------------------------------------------
-- 1. View: donor_details_view
-- Combines donor demographic details with blood group and lifetime donation metrics
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS donor_details_view;
CREATE VIEW donor_details_view AS
SELECT 
    d.id AS donor_id,
    d.full_name,
    d.age,
    d.gender,
    bg.id AS blood_group_id,
    bg.blood_group_name,
    bg.rh_factor,
    d.contact,
    d.email,
    d.address,
    d.city,
    d.last_donation_date,
    d.remarks,
    COUNT(dn.id) AS total_donations,
    COALESCE(SUM(dn.units), 0) AS total_units_donated,
    d.created_at AS registration_date
FROM donors d
INNER JOIN blood_groups bg ON d.blood_group_id = bg.id
LEFT JOIN donations dn ON d.id = dn.donor_id
GROUP BY 
    d.id, 
    d.full_name, 
    d.age, 
    d.gender, 
    bg.id, 
    bg.blood_group_name, 
    bg.rh_factor, 
    d.contact, 
    d.email, 
    d.address, 
    d.city, 
    d.last_donation_date, 
    d.remarks, 
    d.created_at;

-- ----------------------------------------------------------------------------
-- 2. View: blood_stock_view
-- Summarizes blood stock inventory, availability status categories and total inflows
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS blood_stock_view;
CREATE VIEW blood_stock_view AS
SELECT 
    bs.id AS stock_id,
    bg.id AS blood_group_id,
    bg.blood_group_name,
    bg.rh_factor,
    bg.description,
    bs.available_units,
    CASE 
        WHEN bs.available_units < 5 THEN 'Critical'
        WHEN bs.available_units BETWEEN 5 AND 15 THEN 'Moderate'
        ELSE 'Sufficient'
    END AS stock_status,
    COUNT(dn.id) AS total_donations_recorded,
    COALESCE(SUM(dn.units), 0) AS lifetime_units_collected,
    bs.last_updated
FROM blood_stock bs
INNER JOIN blood_groups bg ON bs.blood_group_id = bg.id
LEFT JOIN donations dn ON bg.id = dn.blood_group_id
GROUP BY 
    bs.id, 
    bg.id, 
    bg.blood_group_name, 
    bg.rh_factor, 
    bg.description, 
    bs.available_units, 
    bs.last_updated;

-- ----------------------------------------------------------------------------
-- 3. View: donation_history_view
-- Formatted chronological donation records with donor details and clinical metrics
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS donation_history_view;
CREATE VIEW donation_history_view AS
SELECT 
    dn.id AS donation_id,
    dn.donor_id,
    d.full_name AS donor_name,
    d.contact AS donor_contact,
    d.city AS donor_city,
    bg.id AS blood_group_id,
    bg.blood_group_name,
    dn.donation_date,
    dn.units,
    dn.hemoglobin_level,
    dn.blood_pressure,
    dn.pulse_rate,
    dn.notes,
    dn.created_at
FROM donations dn
INNER JOIN donors d ON dn.donor_id = d.id
INNER JOIN blood_groups bg ON dn.blood_group_id = bg.id;

-- ----------------------------------------------------------------------------
-- 4. View: blood_requests_view
-- Request status overview joined with real-time stock availability
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS blood_requests_view;
CREATE VIEW blood_requests_view AS
SELECT 
    br.id AS request_id,
    br.patient_name,
    br.hospital_name,
    bg.id AS blood_group_id,
    bg.blood_group_name,
    br.units_requested,
    bs.available_units AS current_stock_available,
    br.request_date,
    br.reason,
    br.status,
    br.fulfilled_date,
    br.created_at
FROM blood_requests br
INNER JOIN blood_groups bg ON br.blood_group_id = bg.id
INNER JOIN blood_stock bs ON bg.id = bs.blood_group_id;
