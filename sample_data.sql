-- ============================================================================
-- Blood Bank Management System (BBMS)
-- Sample Data Script: sample_data.sql
-- Inserts at least 9 realistic sample records per table
-- Covers all 8 common blood groups (A+, A-, B+, B-, AB+, AB-, O+, O-) + Bombay (Oh)
-- Demonstrates DML: INSERT
-- ============================================================================

USE blood_bank_db;

-- ----------------------------------------------------------------------------
-- 1. Insert Blood Groups (9 records: 8 standard ABO/Rh + 1 rare Bombay group)
-- ----------------------------------------------------------------------------
INSERT INTO blood_groups (id, blood_group_name, rh_factor, description) VALUES
(1, 'A+',  'Positive', 'Can donate to A+, AB+; can receive from A+, A-, O+, O-'),
(2, 'A-',  'Negative', 'Can donate to A+, A-, AB+, AB-; can receive from A-, O-'),
(3, 'B+',  'Positive', 'Can donate to B+, AB+; can receive from B+, B-, O+, O-'),
(4, 'B-',  'Negative', 'Can donate to B+, B-, AB+, AB-; can receive from B-, O-'),
(5, 'AB+', 'Positive', 'Universal Recipient; can donate to AB+ only'),
(6, 'AB-', 'Negative', 'Can donate to AB+, AB-; can receive from A-, B-, AB-, O-'),
(7, 'O+',  'Positive', 'Can donate to A+, B+, AB+, O+; can receive from O+, O-'),
(8, 'O-',  'Negative', 'Universal Donor; can receive from O- only'),
(9, 'Oh',  'Positive', 'Bombay Phenotype (Rare); can receive from Oh only');

-- ----------------------------------------------------------------------------
-- 2. Insert Initial Blood Stock (9 records matching each blood group)
-- ----------------------------------------------------------------------------
INSERT INTO blood_stock (id, blood_group_id, available_units) VALUES
(1, 1, 18), -- A+
(2, 2,  6), -- A-
(3, 3, 22), -- B+
(4, 4,  5), -- B-
(5, 5, 14), -- AB+
(6, 6,  3), -- AB- (Critical stock)
(7, 7, 28), -- O+
(8, 8, 10), -- O-
(9, 9,  2); -- Oh (Rare / Critical)

-- ----------------------------------------------------------------------------
-- 3. Insert Donors (10 realistic fictional records, age 18-65)
-- ----------------------------------------------------------------------------
INSERT INTO donors (id, full_name, blood_group_id, age, gender, contact, email, address, city, last_donation_date, remarks) VALUES
(1,  'Aarav Sharma',     1, 28, 'Male',   '9876543210', 'aarav.sharma@example.com',    'Flat 402, Sunshine Apts, MG Road',       'Mumbai',    '2026-09-15', 'Regular volunteer donor'),
(2,  'Priya Patel',      7, 24, 'Female', '9823456789', 'priya.patel@example.com',     '12 Silver Park, SG Highway',             'Ahmedabad', '2026-08-20', 'Universal donor (O+)'),
(3,  'Rahul Verma',      3, 35, 'Male',   '9811223344', 'rahul.verma@example.com',     '78 Lakeview Residency, Indiranagar',     'Bengaluru', '2026-07-10', 'Fit and regular donor'),
(4,  'Ananya Iyer',      5, 29, 'Female', '9744556677', 'ananya.iyer@example.com',     '54 Green Glen Layout, Bellandur',        'Bengaluru', '2026-06-05', 'Plasma donor verified'),
(5,  'Vikramjit Singh',  8, 42, 'Male',   '9888776655', 'vikram.singh@example.com',    'H-23 Model Town, Phase 2',               'Chandigarh','2026-09-02', 'Universal donor O- negative'),
(6,  'Sneha Reddy',      1, 22, 'Female', '9701122334', 'sneha.reddy@example.com',     'Plot 88, Jubilee Hills, Rd No 36',       'Hyderabad', '2026-08-11', 'First-time college donor'),
(7,  'Rohan Gupta',      3, 31, 'Male',   '9933445566', 'rohan.gupta@example.com',     'B-14 Civil Lines, Near Stadium',         'Delhi',     '2026-05-18', 'Pre-screened healthy'),
(8,  'Meera Nair',       2, 27, 'Female', '9847112233', 'meera.nair@example.com',      'Padma Vilas, Marine Drive',              'Kochi',     '2026-07-29', 'Rare A- negative donor'),
(9,  'Arjun Mehta',      6, 45, 'Male',   '9867001122', 'arjun.mehta@example.com',     'Row House 5, Koregaon Park',             'Pune',      '2026-04-12', 'Rare AB- negative donor'),
(10, 'Divya Joshi',      4, 26, 'Female', '9890123456', 'divya.joshi@example.com',     '45 Shivaji Nagar, FC Road',              'Pune',      '2026-08-30', 'Dedicated youth volunteer');

-- ----------------------------------------------------------------------------
-- 4. Insert Blood Donations (10 realistic donation history records)
-- ----------------------------------------------------------------------------
INSERT INTO donations (id, donor_id, blood_group_id, donation_date, units, hemoglobin_level, blood_pressure, pulse_rate, notes) VALUES
(1,  1, 1, '2026-09-15', 1, 14.2, '120/80', 74, 'Routine voluntary donation at City Center camp'),
(2,  2, 7, '2026-08-20', 1, 13.5, '118/76', 72, 'Voluntary blood drive at tech park'),
(3,  3, 3, '2026-07-10', 1, 15.0, '122/82', 78, 'Annual corporate donation camp'),
(4,  4, 5, '2026-06-05', 1, 12.8, '115/75', 70, 'Walk-in voluntary donor'),
(5,  5, 8, '2026-09-02', 1, 15.6, '124/80', 76, 'Emergency call response for O- units'),
(6,  6, 1, '2026-08-11', 1, 13.1, '110/72', 68, 'College youth donation campaign'),
(7,  7, 3, '2026-05-18', 1, 14.8, '120/78', 75, 'Standard voluntary donation'),
(8,  8, 2, '2026-07-29', 1, 13.4, '116/74', 72, 'Rare negative blood group call response'),
(9,  9, 6, '2026-04-12', 1, 14.5, '122/80', 74, 'Special registry donor donation'),
(10, 10,4, '2026-08-30', 1, 13.8, '118/76', 70, 'Walk-in blood bank donation');

-- ----------------------------------------------------------------------------
-- 5. Insert Blood Requests (10 realistic hospital patient requests)
-- ----------------------------------------------------------------------------
INSERT INTO blood_requests (id, patient_name, hospital_name, blood_group_id, units_requested, request_date, reason, status, fulfilled_date) VALUES
(1,  'Kavita Deshmukh', 'KEM Hospital, Mumbai',               1, 2, '2026-10-18', 'Elective Cardiac Surgery',           'Pending',   NULL),
(2,  'Tariq Mansoori',  'Apollo Lifeline Hospital, Delhi',    7, 3, '2026-10-17', 'Road Accident Trauma Support',       'Approved',  NULL),
(3,  'Sanjay Kulkarni', 'Ruby Hall Clinic, Pune',             3, 1, '2026-10-16', 'Oncology Chemotherapy Support',      'Fulfilled', '2026-10-16'),
(4,  'Lakshmi Narayanan','Manipal Hospital, Bengaluru',       8, 2, '2026-10-15', 'Emergency Cesarean Delivery',       'Fulfilled', '2026-10-15'),
(5,  'Harish Choudhary','Fortis Escorts, Jaipur',             1, 1, '2026-10-19', 'Thalassemia Regular Transfusion',    'Pending',   NULL),
(6,  'Deepak Malhotra', 'Max Super Speciality, Delhi',        5, 2, '2026-10-14', 'Orthopedic Hip Replacement',         'Fulfilled', '2026-10-14'),
(7,  'Sunita Singhania','Lilavati Hospital, Mumbai',          2, 1, '2026-10-19', 'Emergency ICU Blood Loss',           'Pending',   NULL),
(8,  'Farhan Akhtar',   'Care Hospital, Hyderabad',           3, 2, '2026-10-18', 'Dengue Severe Thrombocytopenia',    'Approved',  NULL),
(9,  'Rameshwar Yadav', 'AIIMS Medical Center, Delhi',        7, 2, '2026-10-13', 'Gastrointestinal Bleeding Surgery',  'Fulfilled', '2026-10-13'),
(10, 'Ayesha Begum',    'Amrita Institute, Kochi',            6, 1, '2026-10-12', 'Elective Spine Surgery',             'Rejected',  NULL);
