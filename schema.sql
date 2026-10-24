-- ============================================================================
-- Blood Bank Management System (BBMS)
-- Database Schema Script: schema.sql
-- Demonstrates DDL: CREATE, ALTER, DROP, Constraints, Foreign Keys & Indexes
-- Normalized to 3NF (Third Normal Form)
-- ============================================================================

-- Step 1: Create and select database
CREATE DATABASE IF NOT EXISTS blood_bank_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE blood_bank_db;

-- ----------------------------------------------------------------------------
-- DDL Demonstration: Safe DROP demonstration on temporary demonstration object
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS demo_scratch_table (
    demo_id INT PRIMARY KEY AUTO_INCREMENT,
    test_note VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Safely drop the demonstration table as required by DDL demonstration
DROP TABLE IF EXISTS demo_scratch_table;

-- ----------------------------------------------------------------------------
-- Drop existing views and tables in reverse dependency order (Clean setup)
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS blood_requests_view;
DROP VIEW IF EXISTS donation_history_view;
DROP VIEW IF EXISTS blood_stock_view;
DROP VIEW IF EXISTS donor_details_view;

DROP TABLE IF EXISTS blood_requests;
DROP TABLE IF EXISTS donations;
DROP TABLE IF EXISTS donors;
DROP TABLE IF EXISTS blood_stock;
DROP TABLE IF EXISTS blood_groups;

-- Also clean up legacy tables if present from earlier experiments
DROP TABLE IF EXISTS stock_transaction_log;
DROP TABLE IF EXISTS blood_request;
DROP TABLE IF EXISTS donation;
DROP TABLE IF EXISTS donor;
DROP TABLE IF EXISTS patient;
DROP TABLE IF EXISTS hospital;
DROP TABLE IF EXISTS blood_group;
DROP TABLE IF EXISTS admin;

-- ============================================================================
-- 1. Table: blood_groups
-- Stores standard blood types (A+, A-, B+, B-, AB+, AB-, O+, O-, Oh)
-- ============================================================================
CREATE TABLE blood_groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    blood_group_name VARCHAR(10) NOT NULL UNIQUE,
    rh_factor ENUM('Positive', 'Negative') NOT NULL,
    description VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 2. Table: blood_stock
-- Tracks available units for each blood group (1-to-1 with blood_groups)
-- Prevents negative stock via CHECK constraint
-- ============================================================================
CREATE TABLE blood_stock (
    id INT AUTO_INCREMENT PRIMARY KEY,
    blood_group_id INT NOT NULL UNIQUE,
    available_units INT NOT NULL DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_stock_non_negative CHECK (available_units >= 0),
    CONSTRAINT fk_stock_blood_group FOREIGN KEY (blood_group_id)
        REFERENCES blood_groups(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 3. Table: donors
-- Stores voluntary blood donor demographics and eligibility
-- Age restricted between 18 and 65 years via CHECK constraint
-- ============================================================================
CREATE TABLE donors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    blood_group_id INT NOT NULL,
    age INT NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    contact VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(100) NULL,
    address VARCHAR(255) NULL,
    city VARCHAR(100) NULL,
    last_donation_date DATE NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_donor_age CHECK (age >= 18 AND age <= 65),
    CONSTRAINT fk_donor_blood_group FOREIGN KEY (blood_group_id)
        REFERENCES blood_groups(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 4. Table: donations
-- Records individual blood donation events
-- Validates units > 0 and donor eligibility
-- ============================================================================
CREATE TABLE donations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    donor_id INT NOT NULL,
    blood_group_id INT NOT NULL,
    donation_date DATE NOT NULL,
    units INT NOT NULL DEFAULT 1,
    hemoglobin_level DECIMAL(4, 1) NULL,
    blood_pressure VARCHAR(20) NULL,
    pulse_rate INT NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_donation_units CHECK (units > 0),
    CONSTRAINT chk_donation_hemoglobin CHECK (hemoglobin_level IS NULL OR hemoglobin_level >= 12.0),
    CONSTRAINT fk_donation_donor FOREIGN KEY (donor_id)
        REFERENCES donors(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_donation_blood_group FOREIGN KEY (blood_group_id)
        REFERENCES blood_groups(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 5. Table: blood_requests
-- Records blood requests submitted by hospitals/patients with lifecycle status
-- Validates units_requested > 0
-- ============================================================================
CREATE TABLE blood_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_name VARCHAR(100) NOT NULL,
    hospital_name VARCHAR(150) NOT NULL,
    blood_group_id INT NOT NULL,
    units_requested INT NOT NULL DEFAULT 1,
    request_date DATE NOT NULL,
    reason VARCHAR(255) NULL,
    status ENUM('Pending', 'Approved', 'Fulfilled', 'Rejected') NOT NULL DEFAULT 'Pending',
    fulfilled_date DATE NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_request_units CHECK (units_requested > 0),
    CONSTRAINT fk_request_blood_group FOREIGN KEY (blood_group_id)
        REFERENCES blood_groups(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- DDL Demonstration: ALTER TABLE to modify column and demonstrate schema evolution
-- ----------------------------------------------------------------------------
ALTER TABLE donors ADD COLUMN remarks VARCHAR(255) NULL AFTER last_donation_date;

-- ----------------------------------------------------------------------------
-- Performance Optimization: Indexes on frequently filtered/joined columns
-- ----------------------------------------------------------------------------
CREATE INDEX idx_donors_blood_group ON donors(blood_group_id);
CREATE INDEX idx_donors_contact ON donors(contact);
CREATE INDEX idx_donors_city ON donors(city);
CREATE INDEX idx_donations_date ON donations(donation_date);
CREATE INDEX idx_donations_donor ON donations(donor_id);
CREATE INDEX idx_donations_group ON donations(blood_group_id);
CREATE INDEX idx_requests_status ON blood_requests(status);
CREATE INDEX idx_requests_group ON blood_requests(blood_group_id);
CREATE INDEX idx_requests_date ON blood_requests(request_date);
