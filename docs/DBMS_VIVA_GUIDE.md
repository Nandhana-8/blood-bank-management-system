# College DBMS Mini-Project Viva Voce & Interview Guide
## Project: Blood Bank Management System (BBMS)

This guide covers the most frequent questions asked by external examiners and professors during DBMS laboratory evaluations and project defense presentations.

---

## 1. Relational Database Concepts in BBMS

### Q1: What is the database schema for this project?
**Answer:** The Blood Bank Management System uses 9 normalized relational tables:
1. `admin`: Administrative accounts with hashed credentials and role privileges.
2. `blood_group`: Reference table defining the 8 standard ABO/Rh blood groups and transfusion compatibility.
3. `blood_stock`: Tracks real-time available units for each blood group with minimum safety thresholds.
4. `hospital`: Partner hospitals, trauma centers, and medical clinics.
5. `donor`: Voluntary blood donors with age, contact, address, and eligibility dates.
6. `donation`: Individual blood collection sessions linked to donors, logging units, vitals, and date.
7. `patient`: Patients requiring transfusions, affiliated with a hospital.
8. `blood_request`: Blood requisitions created for patients, with status tracking (`Pending`, `Approved`, `Rejected`).
9. `stock_transaction_log`: Auditing ledger recording every automated stock increment or decrement.

---

### Q2: What are Primary Keys and Foreign Keys in this project?
**Answer:**
- **Primary Key (PK)**: A column or set of columns that uniquely identifies each tuple (row) in a table. In our schema, all tables utilize auto-incrementing integer surrogate keys (`donor_id`, `hospital_id`, `request_id`, etc.) to guarantee fast indexing and unique identification.
- **Foreign Key (FK)**: A column that references the Primary Key of another table, establishing a relationship and enforcing **Referential Integrity**.
  - Example: `donation.donor_id` references `donor.donor_id`.
  - Example: `blood_request.hospital_id` references `hospital.hospital_id`.

---

### Q3: How is Referential Integrity maintained? What happens when a parent record is deleted?
**Answer:**
We use explicit foreign key constraints with rules:
- `ON DELETE RESTRICT`: Used on `blood_stock.blood_group_id` and `donation.donor_id`. Prevents deleting a donor or blood group if there are existing donation transactions.
- `ON DELETE CASCADE`: Used on `blood_request.patient_id`. If a temporary patient record is cleared, associated pending blood requests are removed cleanly.
- `ON DELETE SET NULL`: Used on `donation.recorded_by` referencing `admin.admin_id`. If an admin account is deactivated, past medical donation records are preserved with a `NULL` admin reference rather than being destroyed.

---

### Q4: Explain the Normalization levels achieved in this project.
**Answer:** The database is normalized up to **Third Normal Form (3NF)**:
1. **1NF (First Normal Form)**:
   - All attribute values are atomic (indivisible). For example, past donations are not stored as comma-separated lists in the donor table; each donation is an independent row in `donation`.
   - Every table has a distinct primary key.
2. **2NF (Second Normal Form)**:
   - Satisfies 1NF.
   - Every non-key attribute is **fully functionally dependent** on the primary key. Since all our primary keys are single surrogate integers (no composite keys), partial dependency cannot exist.
3. **3NF (Third Normal Form)**:
   - Satisfies 2NF.
   - Eliminates **transitive dependencies** ($X \rightarrow Y$ and $Y \rightarrow Z$).
   - For example: We do not store `hospital_name`, `hospital_address`, and `hospital_phone` inside the `blood_request` table. Instead, hospital details are stored once in `hospital`, and `blood_request` only retains `hospital_id`.

---

### Q5: How are ACID Properties and Transactions implemented in this project?
**Answer:** Transactions are essential for blood banking because inventory operations must never be left in an inconsistent state:
- **Atomicity**: In the **Record Donation** workflow:
  1. Insert into `donation`
  2. Update `donor.last_donation_date`
  3. Increment `blood_stock.total_units`
  4. Write to `stock_transaction_log`
  All 4 queries execute inside `START TRANSACTION` / `COMMIT`. If any statement fails (e.g. database error), the entire batch is rolled back (`ROLLBACK`), preventing phantom units.
- **Consistency**: In the **Approve Request** workflow:
  Before deducting stock, the system verifies `available_stock >= requested_units`. If stock is insufficient, the transaction terminates and prevents approval.
- **Isolation**: Handled by MySQL InnoDB with Row-Level Locking (`SELECT ... FOR UPDATE` or atomic decrement `UPDATE blood_stock SET total_units = total_units - X WHERE total_units >= X`).
- **Durability**: InnoDB Write-Ahead Logging (WAL) and redo logs guarantee that once committed, blood inventory records survive power loss.

---

### Q6: Can blood stock become negative? How is that prevented?
**Answer:** Prevented at two distinct layers:
1. **Database Constraint**: `blood_stock` has `CONSTRAINT chk_stock_non_negative CHECK (total_units >= 0)`. Any SQL update that would drop units below 0 throws a DBMS constraint violation error.
2. **Application Logic**: In `app.py`, `api_approve_request()` compares `available < units_requested`. If units are insufficient, it immediately returns an HTTP 400 error: `"Insufficient stock available for blood group X"`.

---

### Q7: Give examples of SQL Joins used in this system.
**Answer:**
1. **INNER JOIN**:
   ```sql
   SELECT d.name, bg.group_name 
   FROM donor d 
   JOIN blood_group bg ON d.blood_group_id = bg.blood_group_id;
   ```
2. **LEFT OUTER JOIN**:
   ```sql
   -- Lists all hospitals even if they have placed 0 blood requests
   SELECT h.hospital_name, COUNT(br.request_id) AS total_requests
   FROM hospital h
   LEFT JOIN blood_request br ON h.hospital_id = br.hospital_id
   GROUP BY h.hospital_id, h.hospital_name;
   ```
3. **Multi-Table JOIN (4 Tables)**:
   ```sql
   SELECT br.request_id, p.patient_name, h.hospital_name, bg.group_name, br.units_requested
   FROM blood_request br
   JOIN patient p ON br.patient_id = p.patient_id
   JOIN hospital h ON br.hospital_id = h.hospital_id
   JOIN blood_group bg ON br.blood_group_id = bg.blood_group_id
   WHERE br.status = 'Pending';
   ```

---

### Q8: What SQL Views are implemented?
**Answer:**
- `view_stock_summary`: Pre-joins `blood_stock` with `blood_group` and computes clinical health alerts (`Critical Low`, `Moderate`, `Adequate`) using a `CASE` statement.
- `view_blood_requests`: Combines patient details, hospital center, blood type, and approved staff names into an easy-to-query reporting relation.
- `view_donation_history`: Joins donation sessions with donor profiles and recording staff.

---

### Q9: What are Triggers and where can they be used in BBMS?
**Answer:** A trigger is a stored program executed automatically in response to DML operations (`INSERT`, `UPDATE`, `DELETE`).
In BBMS, the trigger `trg_after_stock_update` on `blood_stock` automatically writes an audit record into `stock_transaction_log` whenever `total_units` changes, capturing the previous balance, new balance, and timestamp.
