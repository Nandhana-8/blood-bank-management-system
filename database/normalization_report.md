# Database Normalization Report
## Blood Bank Management System (BBMS)

This document explains the step-by-step normalization process applied during the design of the **Blood Bank Management System** database, proving compliance up to **Third Normal Form (3NF)**.

---

## 1. Objectives of Normalization

1. Eliminate redundant data storage (e.g. avoid repeating hospital contact information across hundreds of blood requests).
2. Prevent insertion anomalies (e.g. ability to record a hospital before it places any requests).
3. Prevent deletion anomalies (e.g. deleting a blood request does not delete hospital information).
4. Prevent update anomalies (e.g. updating a hospital's contact number in one single record updates all references immediately).

---

## 2. First Normal Form (1NF)

### 1NF Criteria
- Each column must contain atomic (indivisible) values.
- No repeating groups or arrays within a single attribute.
- A unique primary key identifies every tuple.

### Application in BBMS:
- Attributes such as `phone`, `email`, `units`, and `donation_date` contain single atomic scalar values.
- Multi-valued attributes like multiple past donations are not stored as comma-separated values in the `donor` table. Instead, a separate `donation` table is created where each donation is an independent row with foreign key `donor_id`.
- Compatibility lists in `blood_group` are informational lookups; actual compatibility checks in business logic rely on relational group matching.

---

## 3. Second Normal Form (2NF)

### 2NF Criteria
- The table must already be in 1NF.
- There must be **no partial functional dependencies** (no non-prime attribute is functionally dependent on a proper subset of any candidate key).
- In relations with single-column primary keys, 2NF is automatically satisfied.

### Application in BBMS:
- Every table uses a surrogate primary key:
  - `donor (donor_id)`
  - `donation (donation_id)`
  - `hospital (hospital_id)`
  - `patient (patient_id)`
  - `blood_request (request_id)`
  - `blood_stock (stock_id)`
- Since all primary keys are single attributes (not composite keys), no non-key attribute can be partially dependent on a composite key. Hence, every relation is strictly in **2NF**.

---

## 4. Third Normal Form (3NF)

### 3NF Criteria
- The table must already be in 2NF.
- There must be **no transitive dependencies** (no non-prime attribute depends on another non-prime attribute: $X \rightarrow Y$ and $Y \rightarrow Z$).

### Application in BBMS:

#### Case Study A: Blood Requests and Hospital Details
- **Un-normalized Anti-pattern**:
  - `blood_request (request_id, patient_name, hospital_name, hospital_address, hospital_phone, units, date)`
  - Here, `request_id -> hospital_name`, and `hospital_name -> hospital_address, hospital_phone`.
  - This is a transitive dependency!
- **Normalized 3NF Solution in BBMS**:
  - Hospital details are extracted into `hospital(hospital_id, hospital_name, address, contact_number, email)`.
  - The `blood_request` table stores only the foreign key `hospital_id`.
  - Transitive dependency eliminated.

#### Case Study B: Patient and Hospital Association
- **Un-normalized Anti-pattern**:
  - Storing patient medical history and hospital address inside `blood_request`.
- **Normalized 3NF Solution in BBMS**:
  - Extracted into `patient(patient_id, patient_name, age, gender, blood_group_id, hospital_id)`.
  - Blood request refers to `patient_id`.

#### Case Study C: Blood Group Attributes & Stock
- **Un-normalized Anti-pattern**:
  - Repeating ABO group descriptions and rh factors inside every donor and donation row.
- **Normalized 3NF Solution in BBMS**:
  - Master entity `blood_group(blood_group_id, group_name, rh_factor, ...)`.
  - `donor`, `donation`, `patient`, and `blood_stock` refer to `blood_group_id`.

---

## 5. Summary Functional Dependencies Matrix

| Relation | Primary Key | Functional Dependencies | Normal Form |
| :--- | :--- | :--- | :--- |
| `admin` | `admin_id` | `admin_id -> username, password_hash, full_name, email, role` | **3NF** |
| `blood_group` | `blood_group_id` | `blood_group_id -> group_name, rh_factor, can_donate_to, can_receive_from` | **3NF** |
| `blood_stock` | `stock_id` | `stock_id -> blood_group_id, total_units, threshold_low, last_updated` | **3NF** |
| `hospital` | `hospital_id` | `hospital_id -> hospital_name, license_number, address, contact_number, email` | **3NF** |
| `donor` | `donor_id` | `donor_id -> name, age, gender, blood_group_id, phone, email, address, last_donation_date` | **3NF** |
| `donation` | `donation_id` | `donation_id -> donor_id, blood_group_id, units, donation_date, recorded_by` | **3NF** |
| `patient` | `patient_id` | `patient_id -> patient_name, age, gender, blood_group_id, hospital_id` | **3NF** |
| `blood_request` | `request_id` | `request_id -> patient_id, hospital_id, blood_group_id, units_requested, status` | **3NF** |
