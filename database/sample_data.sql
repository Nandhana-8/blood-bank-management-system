-- =============================================================================
-- Blood Bank Management System - Realistic Sample Seed Data
-- =============================================================================

USE blood_bank_db;

-- 1. Seed Admin Users (password: 'admin123' for default admin)
INSERT INTO admin (username, password_hash, full_name, email, role) VALUES
('admin', 'scrypt:32768:8:1$Z39d6eRST0OTDnCY$834f1c07325a1884cdc3faaef8c1a51b842e573c801db353294b69dd1e262d671422330a380000446fdd933b80d08e707ae2fddc3c1a4335c713a4a2a619a98c', 'Chief Medical Officer', 'admin@bloodbank.org', 'Super Administrator'),
('staff_sarah', 'scrypt:32768:8:1$Z39d6eRST0OTDnCY$834f1c07325a1884cdc3faaef8c1a51b842e573c801db353294b69dd1e262d671422330a380000446fdd933b80d08e707ae2fddc3c1a4335c713a4a2a619a98c', 'Sarah Jenkins', 'sarah.j@bloodbank.org', 'Lab Technician');

-- 2. Seed Blood Groups with Standard ABO/Rh Compatibility Info
INSERT INTO blood_group (blood_group_id, group_name, rh_factor, can_donate_to, can_receive_from, description) VALUES
(1, 'A+',  'Rh+', 'A+, AB+',           'A+, A-, O+, O-',       'Common blood group; contains A antigens and Rh factor'),
(2, 'A-',  'Rh-', 'A+, A-, AB+, AB-',   'A-, O-',               'Rare group; universal platelets donor'),
(3, 'B+',  'Rh+', 'B+, AB+',           'B+, B-, O+, O-',       'Contains B antigen and Rh factor'),
(4, 'B-',  'Rh-', 'B+, B-, AB+, AB-',   'B-, O-',               'Rare blood group without Rh factor'),
(5, 'AB+', 'Rh+', 'AB+',               'All (Universal Recipient)', 'Universal plasma donor; can receive any blood type'),
(6, 'AB-', 'Rh-', 'AB+, AB-',          'AB-, A-, B-, O-',      'Rarest of all blood groups'),
(7, 'O+',  'Rh+', 'O+, A+, B+, AB+',   'O+, O-',               'Most frequent transfusion requirement'),
(8, 'O-',  'Rh-', 'All (Universal Donor)', 'O-',                'Universal red blood cell donor for emergencies');

-- 3. Seed Blood Stock (Units available per blood group)
INSERT INTO blood_stock (stock_id, blood_group_id, total_units, threshold_low) VALUES
(1, 1, 34, 10),  -- A+
(2, 2, 8,  5),   -- A-
(3, 3, 26, 10),  -- B+
(4, 4, 6,  5),   -- B-
(5, 5, 14, 5),   -- AB+
(6, 6, 4,  5),   -- AB- (Low Stock Alert)
(7, 7, 45, 15),  -- O+
(8, 8, 12, 10);  -- O-

-- 4. Seed Partner Hospitals
INSERT INTO hospital (hospital_id, hospital_name, license_number, address, contact_number, email, emergency_contact) VALUES
(1, 'City Care General Hospital',    'HOSP-LIC-2023-01', '742 Evergreen Terrace, Central District',  '+1-555-0100', 'care@cityhospital.org',     '+1-555-9111'),
(2, 'St. Jude Memorial Hospital',     'HOSP-LIC-2021-45', '124 Healthcare Avenue, Westside',          '+1-555-0102', 'contact@stjudememorial.org', '+1-555-9112'),
(3, 'Metro Emergency Trauma Center',  'HOSP-LIC-2022-88', '899 Lifeline Boulevard, North Ridge',       '+1-555-0104', 'trauma@metrohealth.org',    '+1-555-9113'),
(4, 'Apex Children & Women Hospital', 'HOSP-LIC-2024-12', '45 Bloom Garden Way, South Valley',        '+1-555-0106', 'desk@apexspeciality.org',   '+1-555-9114'),
(5, 'Apollo Heart & Cancer Institute','HOSP-LIC-2020-99', '210 Medical City Park, Tech Zone',        '+1-555-0108', 'info@apolloinstitute.org',  '+1-555-9115');

-- 5. Seed Registered Donors
INSERT INTO donor (donor_id, name, age, gender, blood_group_id, phone, email, address, medical_clearance, last_donation_date) VALUES
(1,  'David Miller',    28, 'Male',   1, '+1-555-2001', 'david.miller@email.com',    '12 Pine Street, Downtown',       1, '2026-08-15'),
(2,  'Elena Rostova',   32, 'Female', 7, '+1-555-2002', 'elena.r@email.com',          '88 Maple Court, Suburbia',       1, '2026-07-20'),
(3,  'Marcus Johnson',  45, 'Male',   8, '+1-555-2003', 'marcus.j@email.com',        '450 Oak Highway, Hillside',      1, '2026-09-02'),
(4,  'Sophia Chen',     24, 'Female', 3, '+1-555-2004', 'sophia.chen@email.com',     '18 Sunset Boulevard, West End',  1, '2026-06-11'),
(5,  'Rajesh Sharma',   35, 'Male',   5, '+1-555-2005', 'rajesh.sharma@email.com',   '302 Silicon Avenue, Tech Hub',   1, '2026-08-28'),
(6,  'Amina Al-Mansoor',29, 'Female', 2, '+1-555-2006', 'amina.m@email.com',          '77 Crescent Way, Northshore',    1, '2026-05-19'),
(7,  'Carlos Santana',  40, 'Male',   7, '+1-555-2007', 'carlos.s@email.com',        '92 Rivera Drive, Portside',      1, '2026-09-10'),
(8,  'Grace Hopper',    22, 'Female', 6, '+1-555-2008', 'grace.h@email.com',          '55 University Park, Campus',     1, '2026-04-14'),
(9,  'Liam Gallagher',  31, 'Male',   4, '+1-555-2009', 'liam.g@email.com',          '101 Rockaway Lane, Eastgate',    1, '2026-08-01'),
(10, 'Zoe Washington',  26, 'Female', 1, '+1-555-2010', 'zoe.wash@email.com',        '63 Liberty Circle, Midtown',     1, '2026-09-18');

-- 6. Seed Donation History
INSERT INTO donation (donation_id, donor_id, blood_group_id, units, donation_date, hemoglobin_level, systolic_bp, diastolic_bp, notes, recorded_by) VALUES
(1,  1,  1, 1, '2026-08-15', 14.2, 118, 78, 'Routine voluntary donation; donor in good health', 1),
(2,  2,  7, 2, '2026-07-20', 13.8, 120, 80, 'Apheresis donation during blood drive', 1),
(3,  3,  8, 1, '2026-09-02', 15.1, 122, 82, 'Emergency O- call donation', 1),
(4,  4,  3, 1, '2026-06-11', 13.4, 115, 75, 'Regular voluntary donor', 2),
(5,  5,  5, 1, '2026-08-28', 14.0, 124, 82, 'Donated at campus camp', 2),
(6,  6,  2, 1, '2026-05-19', 13.1, 119, 78, 'Rare A- group replacement unit', 1),
(7,  7,  7, 2, '2026-09-10', 14.8, 120, 80, 'Double red blood cell donation', 1),
(8,  8,  6, 1, '2026-04-14', 12.9, 116, 76, 'Rare AB- blood donor', 2),
(9,  9,  4, 1, '2026-08-01', 14.5, 125, 84, 'Voluntary walk-in donor', 1),
(10, 10, 1, 1, '2026-09-18', 13.6, 118, 79, 'World Heart Day blood drive participant', 2);

-- 7. Seed Patients
INSERT INTO patient (patient_id, patient_name, age, gender, blood_group_id, hospital_id, contact_number, medical_condition) VALUES
(1, 'Michael Brown',   54, 'Male',   1, 1, '+1-555-3001', 'Scheduled bypass cardiac surgery'),
(2, 'Hannah Abbott',   31, 'Female', 8, 3, '+1-555-3002', 'Severe trauma victim from road accident'),
(3, 'Arthur Davies',   68, 'Male',   7, 2, '+1-555-3003', 'Anemia secondary to chronic renal failure'),
(4, 'Clara Oswald',    29, 'Female', 5, 4, '+1-555-3004', 'Post-partum hemorrhage management'),
(5, 'George Costanza', 49, 'Male',   3, 5, '+1-555-3005', 'Orthopedic knee reconstruction surgery'),
(6, 'Nancy Wheeler',   19, 'Female', 6, 3, '+1-555-3006', 'Aplastic anemia therapeutic transfusion'),
(7, 'Samuel Smith',    42, 'Male',   7, 1, '+1-555-3007', 'Gastrointestinal bleeding emergency'),
(8, 'Rachel Green',    36, 'Female', 2, 4, '+1-555-3008', 'Caesarean section with low platelet reserve');

-- 8. Seed Blood Requests (Demonstrating Pending, Approved, Rejected workflows)
INSERT INTO blood_request (request_id, patient_id, hospital_id, blood_group_id, units_requested, request_date, urgency_level, status, approval_date, approved_by, remarks) VALUES
(1, 1, 1, 1, 2, '2026-09-20', 'Normal',    'Approved', '2026-09-20 14:30:00', 1, 'Issued to City Care OT-2'),
(2, 2, 3, 8, 3, '2026-09-25', 'Emergency', 'Approved', '2026-09-25 08:15:00', 1, 'Dispatched via emergency green corridor'),
(3, 3, 2, 7, 2, '2026-09-26', 'Normal',    'Pending',  NULL,                   NULL, 'Awaiting hematologist cross-match confirmation'),
(4, 4, 4, 5, 1, '2026-09-26', 'Critical',  'Pending',  NULL,                   NULL, 'ICU bed 12 maternal ward requisition'),
(5, 5, 5, 3, 2, '2026-09-24', 'Normal',    'Approved', '2026-09-24 16:45:00', 2, 'Released to Apollo surgical unit'),
(6, 6, 3, 6, 8, '2026-09-23', 'Critical',  'Rejected', '2026-09-23 11:20:00', 1, 'Insufficient stock available (requested 8, balance was 4)'),
(7, 7, 1, 7, 3, '2026-09-27', 'Emergency', 'Pending',  NULL,                   NULL, 'Urgent requisition received from Dr. Watson'),
(8, 8, 4, 2, 1, '2026-09-22', 'Normal',    'Approved', '2026-09-22 10:00:00', 1, 'Issued to Apex labor ward');

-- 9. Seed Stock Transaction Audit Log
INSERT INTO stock_transaction_log (blood_group_id, transaction_type, units_changed, reference_id, remarks) VALUES
(1, 'DONATION',       1, 1, 'Donation from David Miller'),
(7, 'DONATION',       2, 2, 'Donation from Elena Rostova'),
(8, 'DONATION',       1, 3, 'Donation from Marcus Johnson'),
(1, 'REQUEST_ISSUE', -2, 1, 'Units issued for Patient Michael Brown at City Care'),
(8, 'REQUEST_ISSUE', -3, 2, 'Emergency units issued for Patient Hannah Abbott at Metro Trauma'),
(3, 'REQUEST_ISSUE', -2, 5, 'Units issued for Patient George Costanza at Apollo Heart');
