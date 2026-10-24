-- =============================================================================
-- Blood Bank Management System (BBMS) - Complete Relational Database Schema
-- DBMS Mini-Project | RDBMS: MySQL (Compatible with MySQL 5.7, 8.0+ and MariaDB)
-- Normalization: Normalized to 3NF (Third Normal Form)
-- =============================================================================

CREATE DATABASE IF NOT EXISTS blood_bank_db
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE blood_bank_db;

-- -----------------------------------------------------------------------------
-- Disable foreign key checks during setup to ensure clean recreation
-- -----------------------------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS stock_transaction_log;
DROP TABLE IF EXISTS blood_request;
DROP TABLE IF EXISTS patient;
DROP TABLE IF EXISTS donation;
DROP TABLE IF EXISTS donor;
DROP TABLE IF EXISTS blood_stock;
DROP TABLE IF EXISTS hospital;
DROP TABLE IF EXISTS blood_group;
DROP TABLE IF EXISTS admin;

SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================================
-- 1. TABLE: admin
-- Stores system administrator login credentials and audit identity
-- =============================================================================
CREATE TABLE admin (
    admin_id INT AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    role VARCHAR(30) DEFAULT 'Administrator',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT pk_admin PRIMARY KEY (admin_id),
    CONSTRAINT uq_admin_username UNIQUE (username),
    CONSTRAINT uq_admin_email UNIQUE (email)
) ENGINE=InnoDB;

-- =============================================================================
-- 2. TABLE: blood_group
-- Reference entity storing standard ABO and Rh blood groups & compatibility
-- =============================================================================
CREATE TABLE blood_group (
    blood_group_id INT AUTO_INCREMENT,
    group_name VARCHAR(5) NOT NULL,
    rh_factor VARCHAR(5) NOT NULL,
    can_donate_to VARCHAR(100) NOT NULL,
    can_receive_from VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    CONSTRAINT pk_blood_group PRIMARY KEY (blood_group_id),
    CONSTRAINT uq_blood_group_name UNIQUE (group_name)
) ENGINE=InnoDB;

-- =============================================================================
-- 3. TABLE: blood_stock
-- Tracks available inventory count (in units) for each blood group
-- Foreign key to blood_group with CHECK constraint ensuring stock cannot be negative
-- =============================================================================
CREATE TABLE blood_stock (
    stock_id INT AUTO_INCREMENT,
    blood_group_id INT NOT NULL,
    total_units INT NOT NULL DEFAULT 0,
    threshold_low INT NOT NULL DEFAULT 5,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_blood_stock PRIMARY KEY (stock_id),
    CONSTRAINT uq_blood_stock_group UNIQUE (blood_group_id),
    CONSTRAINT fk_blood_stock_group FOREIGN KEY (blood_group_id)
        REFERENCES blood_group(blood_group_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_stock_non_negative CHECK (total_units >= 0)
) ENGINE=InnoDB;

-- =============================================================================
-- 4. TABLE: hospital
-- Registered partner hospitals, trauma centers, and medical clinics
-- =============================================================================
CREATE TABLE hospital (
    hospital_id INT AUTO_INCREMENT,
    hospital_name VARCHAR(150) NOT NULL,
    license_number VARCHAR(50) NOT NULL,
    address TEXT NOT NULL,
    contact_number VARCHAR(25) NOT NULL,
    email VARCHAR(100) NOT NULL,
    emergency_contact VARCHAR(25),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_hospital PRIMARY KEY (hospital_id),
    CONSTRAINT uq_hospital_name UNIQUE (hospital_name),
    CONSTRAINT uq_hospital_license UNIQUE (license_number)
) ENGINE=InnoDB;

-- =============================================================================
-- 5. TABLE: donor
-- Registered voluntary blood donors with demographic and contact records
-- =============================================================================
CREATE TABLE donor (
    donor_id INT AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    age INT NOT NULL,
    gender VARCHAR(10) NOT NULL,
    blood_group_id INT NOT NULL,
    phone VARCHAR(25) NOT NULL,
    email VARCHAR(100),
    address TEXT NOT NULL,
    medical_clearance BOOLEAN DEFAULT TRUE,
    last_donation_date DATE NULL DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_donor PRIMARY KEY (donor_id),
    CONSTRAINT uq_donor_phone UNIQUE (phone),
    CONSTRAINT fk_donor_blood_group FOREIGN KEY (blood_group_id)
        REFERENCES blood_group(blood_group_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_donor_age CHECK (age >= 18 AND age <= 65),
    CONSTRAINT chk_donor_gender CHECK (gender IN ('Male', 'Female', 'Other'))
) ENGINE=InnoDB;

-- =============================================================================
-- 6. TABLE: donation
-- Record of blood units collected from registered donors
-- =============================================================================
CREATE TABLE donation (
    donation_id INT AUTO_INCREMENT,
    donor_id INT NOT NULL,
    blood_group_id INT NOT NULL,
    units INT NOT NULL DEFAULT 1,
    donation_date DATE NOT NULL,
    hemoglobin_level DECIMAL(4, 1) DEFAULT 13.5,
    systolic_bp INT DEFAULT 120,
    diastolic_bp INT DEFAULT 80,
    notes VARCHAR(255),
    recorded_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_donation PRIMARY KEY (donation_id),
    CONSTRAINT fk_donation_donor FOREIGN KEY (donor_id)
        REFERENCES donor(donor_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_donation_blood_group FOREIGN KEY (blood_group_id)
        REFERENCES blood_group(blood_group_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_donation_admin FOREIGN KEY (recorded_by)
        REFERENCES admin(admin_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_donation_units CHECK (units > 0)
) ENGINE=InnoDB;

-- =============================================================================
-- 7. TABLE: patient
-- Patients requiring transfusion, affiliated with a hospital
-- =============================================================================
CREATE TABLE patient (
    patient_id INT AUTO_INCREMENT,
    patient_name VARCHAR(100) NOT NULL,
    age INT NOT NULL,
    gender VARCHAR(10) NOT NULL,
    blood_group_id INT NOT NULL,
    hospital_id INT NULL,
    contact_number VARCHAR(25),
    medical_condition VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_patient PRIMARY KEY (patient_id),
    CONSTRAINT fk_patient_blood_group FOREIGN KEY (blood_group_id)
        REFERENCES blood_group(blood_group_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_patient_hospital FOREIGN KEY (hospital_id)
        REFERENCES hospital(hospital_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_patient_gender CHECK (gender IN ('Male', 'Female', 'Other'))
) ENGINE=InnoDB;

-- =============================================================================
-- 8. TABLE: blood_request
-- Transfusion and emergency blood requisition records
-- =============================================================================
CREATE TABLE blood_request (
    request_id INT AUTO_INCREMENT,
    patient_id INT NOT NULL,
    hospital_id INT NOT NULL,
    blood_group_id INT NOT NULL,
    units_requested INT NOT NULL,
    request_date DATE NOT NULL,
    urgency_level VARCHAR(20) DEFAULT 'Normal',
    status VARCHAR(20) DEFAULT 'Pending',
    approval_date TIMESTAMP NULL DEFAULT NULL,
    approved_by INT NULL,
    remarks VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_blood_request PRIMARY KEY (request_id),
    CONSTRAINT fk_request_patient FOREIGN KEY (patient_id)
        REFERENCES patient(patient_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_request_hospital FOREIGN KEY (hospital_id)
        REFERENCES hospital(hospital_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_request_blood_group FOREIGN KEY (blood_group_id)
        REFERENCES blood_group(blood_group_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_request_admin FOREIGN KEY (approved_by)
        REFERENCES admin(admin_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_request_units CHECK (units_requested > 0),
    CONSTRAINT chk_request_urgency CHECK (urgency_level IN ('Normal', 'Critical', 'Emergency')),
    CONSTRAINT chk_request_status CHECK (status IN ('Pending', 'Approved', 'Rejected'))
) ENGINE=InnoDB;

-- =============================================================================
-- 9. TABLE: stock_transaction_log
-- Auditing ledger recording every stock increment or decrement
-- =============================================================================
CREATE TABLE stock_transaction_log (
    log_id INT AUTO_INCREMENT,
    blood_group_id INT NOT NULL,
    transaction_type VARCHAR(30) NOT NULL,
    units_changed INT NOT NULL,
    reference_id INT NULL,
    remarks VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_stock_log PRIMARY KEY (log_id),
    CONSTRAINT fk_log_blood_group FOREIGN KEY (blood_group_id)
        REFERENCES blood_group(blood_group_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_log_type CHECK (transaction_type IN ('DONATION', 'REQUEST_ISSUE', 'MANUAL_ADJUSTMENT'))
) ENGINE=InnoDB;

-- =============================================================================
-- INDEXES for Query Optimization
-- =============================================================================
CREATE INDEX idx_donor_blood_group ON donor(blood_group_id);
CREATE INDEX idx_donor_phone ON donor(phone);
CREATE INDEX idx_donation_date ON donation(donation_date);
CREATE INDEX idx_donation_donor ON donation(donor_id);
CREATE INDEX idx_request_status ON blood_request(status);
CREATE INDEX idx_request_date ON blood_request(request_date);
CREATE INDEX idx_request_urgency ON blood_request(urgency_level);
CREATE INDEX idx_patient_hospital ON patient(hospital_id);

-- =============================================================================
-- SQL VIEWS for Reports & Abstracted Queries
-- =============================================================================

-- View 1: Current Stock Summary with Group Name and Safety Alert Status
CREATE OR REPLACE VIEW view_stock_summary AS
SELECT 
    bs.stock_id,
    bg.blood_group_id,
    bg.group_name,
    bs.total_units,
    bs.threshold_low,
    CASE 
        WHEN bs.total_units = 0 THEN 'Out of Stock'
        WHEN bs.total_units <= bs.threshold_low THEN 'Critical Low'
        WHEN bs.total_units <= (bs.threshold_low * 2) THEN 'Moderate'
        ELSE 'Adequate'
    END AS stock_status,
    bs.last_updated
FROM blood_stock bs
JOIN blood_group bg ON bs.blood_group_id = bg.blood_group_id
ORDER BY bg.group_name;

-- View 2: Complete Donation Details with Donor Information
CREATE OR REPLACE VIEW view_donation_history AS
SELECT 
    d.donation_id,
    dn.donor_id,
    dn.name AS donor_name,
    dn.phone AS donor_phone,
    bg.group_name AS blood_group,
    d.units,
    d.donation_date,
    d.hemoglobin_level,
    d.systolic_bp,
    d.diastolic_bp,
    d.notes,
    adm.full_name AS recorded_by_admin,
    d.created_at
FROM donation d
JOIN donor dn ON d.donor_id = dn.donor_id
JOIN blood_group bg ON d.blood_group_id = bg.blood_group_id
LEFT JOIN admin adm ON d.recorded_by = adm.admin_id
ORDER BY d.donation_date DESC, d.donation_id DESC;

-- View 3: Complete Request Details with Patient and Hospital Information
CREATE OR REPLACE VIEW view_blood_requests AS
SELECT 
    br.request_id,
    p.patient_name,
    p.age AS patient_age,
    p.gender AS patient_gender,
    h.hospital_id,
    h.hospital_name,
    h.contact_number AS hospital_contact,
    bg.group_name AS blood_group,
    br.units_requested,
    br.request_date,
    br.urgency_level,
    br.status,
    br.approval_date,
    adm.full_name AS approved_by_admin,
    br.remarks,
    br.created_at
FROM blood_request br
JOIN patient p ON br.patient_id = p.patient_id
JOIN hospital h ON br.hospital_id = h.hospital_id
JOIN blood_group bg ON br.blood_group_id = bg.blood_group_id
LEFT JOIN admin adm ON br.approved_by = adm.admin_id
ORDER BY 
    CASE br.status 
        WHEN 'Pending' THEN 1 
        WHEN 'Approved' THEN 2 
        ELSE 3 
    END,
    br.request_date DESC;
