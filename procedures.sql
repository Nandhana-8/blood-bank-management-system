-- ============================================================================
-- Blood Bank Management System (BBMS)
-- Stored Procedures: procedures.sql
-- Implements business logic routines with ACID Transactions (START TRANSACTION, COMMIT, ROLLBACK)
-- ============================================================================

USE blood_bank_db;

DELIMITER $$

-- ----------------------------------------------------------------------------
-- 1. Procedure: sp_record_donation
-- Records a blood donation inside an atomic transaction
-- Retrieves the donor's blood group and inserts the record
-- Triggers automatically handle inventory increment and donor last_donation_date
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_record_donation$$

CREATE PROCEDURE sp_record_donation(
    IN p_donor_id INT,
    IN p_donation_date DATE,
    IN p_units INT,
    IN p_hemoglobin DECIMAL(4, 1),
    IN p_blood_pressure VARCHAR(20),
    IN p_pulse_rate INT,
    IN p_notes TEXT,
    OUT p_donation_id INT
)
proc_body: BEGIN
    DECLARE v_blood_group_id INT;
    DECLARE v_donor_exists INT DEFAULT 0;

    -- Error handler to guarantee rollback on any SQL exception
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Input validation
    IF p_units <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Units must be greater than zero.';
    END IF;

    IF p_hemoglobin IS NOT NULL AND p_hemoglobin < 12.0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Hemoglobin level must be at least 12.0 g/dL for donation eligibility.';
    END IF;

    START TRANSACTION;

    -- Check if donor exists and fetch blood_group_id
    SELECT COUNT(*), blood_group_id 
    INTO v_donor_exists, v_blood_group_id
    FROM donors
    WHERE id = p_donor_id
    GROUP BY blood_group_id;

    IF v_donor_exists = 0 OR v_blood_group_id IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Donor does not exist in the database.';
    END IF;

    -- Insert donation record (MySQL trigger will automatically increment blood_stock)
    INSERT INTO donations (
        donor_id,
        blood_group_id,
        donation_date,
        units,
        hemoglobin_level,
        blood_pressure,
        pulse_rate,
        notes
    ) VALUES (
        p_donor_id,
        v_blood_group_id,
        COALESCE(p_donation_date, CURDATE()),
        p_units,
        p_hemoglobin,
        p_blood_pressure,
        p_pulse_rate,
        p_notes
    );

    SET p_donation_id = LAST_INSERT_ID();

    COMMIT;
END$$

-- ----------------------------------------------------------------------------
-- 2. Procedure: sp_update_stock
-- Updates blood stock inventory using operations: 'ADD', 'SUBTRACT', or 'SET'
-- Enforces ACID safety and non-negative stock constraint
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_update_stock$$

CREATE PROCEDURE sp_update_stock(
    IN p_blood_group_id INT,
    IN p_units INT,
    IN p_operation VARCHAR(10)
)
proc_body: BEGIN
    DECLARE v_current INT DEFAULT 0;
    DECLARE v_op VARCHAR(10);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET v_op = UPPER(TRIM(p_operation));

    START TRANSACTION;

    -- Retrieve current stock
    SELECT COALESCE(available_units, 0)
    INTO v_current
    FROM blood_stock
    WHERE blood_group_id = p_blood_group_id
    FOR UPDATE; -- Row-level lock for concurrency safety

    IF v_op = 'ADD' THEN
        IF p_units <= 0 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Units to add must be positive.';
        END IF;
        UPDATE blood_stock
        SET available_units = available_units + p_units
        WHERE blood_group_id = p_blood_group_id;

    ELSEIF v_op = 'SUBTRACT' THEN
        IF p_units <= 0 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Units to subtract must be positive.';
        END IF;
        IF v_current < p_units THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Insufficient stock. Cannot subtract more than available.';
        END IF;
        UPDATE blood_stock
        SET available_units = available_units - p_units
        WHERE blood_group_id = p_blood_group_id;

    ELSEIF v_op = 'SET' THEN
        IF p_units < 0 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Available units cannot be set to a negative number.';
        END IF;
        UPDATE blood_stock
        SET available_units = p_units
        WHERE blood_group_id = p_blood_group_id;

    ELSE
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid operation. Use ADD, SUBTRACT, or SET.';
    END IF;

    COMMIT;
END$$

-- ----------------------------------------------------------------------------
-- 3. Procedure: sp_get_donor_info
-- Retrieves donor profile along with blood group details and donation summary
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_get_donor_info$$

CREATE PROCEDURE sp_get_donor_info(IN p_donor_id INT)
BEGIN
    SELECT 
        d.id AS donor_id,
        d.full_name,
        d.age,
        d.gender,
        d.blood_group_id,
        bg.blood_group_name,
        bg.rh_factor,
        d.contact,
        d.email,
        d.address,
        d.city,
        d.last_donation_date,
        d.remarks,
        d.created_at AS registered_on,
        COUNT(dn.id) AS total_donations_count,
        COALESCE(SUM(dn.units), 0) AS total_units_donated
    FROM donors d
    INNER JOIN blood_groups bg ON d.blood_group_id = bg.id
    LEFT JOIN donations dn ON d.id = dn.donor_id
    WHERE d.id = p_donor_id
    GROUP BY 
        d.id, d.full_name, d.age, d.gender, d.blood_group_id, 
        bg.blood_group_name, bg.rh_factor, d.contact, d.email, 
        d.address, d.city, d.last_donation_date, d.remarks, d.created_at;
END$$

-- ----------------------------------------------------------------------------
-- 4. Procedure: sp_fulfill_request
-- Fulfills a blood request atomically, ensuring stock availability
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_fulfill_request$$

CREATE PROCEDURE sp_fulfill_request(
    IN p_request_id INT,
    OUT p_result_code INT,
    OUT p_result_message VARCHAR(255)
)
proc_body: BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_units INT;
    DECLARE v_group_id INT;
    DECLARE v_stock INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result_code = 0;
        SET p_result_message = 'Failed to fulfill request due to a database exception or insufficient stock.';
    END;

    START TRANSACTION;

    SELECT status, units_requested, blood_group_id
    INTO v_status, v_units, v_group_id
    FROM blood_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF v_status IS NULL THEN
        ROLLBACK;
        SET p_result_code = 0;
        SET p_result_message = 'Request not found.';
        LEAVE proc_body;
    END IF;

    IF v_status = 'Fulfilled' THEN
        ROLLBACK;
        SET p_result_code = 0;
        SET p_result_message = 'Request is already marked as Fulfilled.';
        LEAVE proc_body;
    END IF;

    -- Check stock
    SELECT available_units INTO v_stock
    FROM blood_stock
    WHERE blood_group_id = v_group_id;

    IF v_stock < v_units THEN
        ROLLBACK;
        SET p_result_code = 0;
        SET p_result_message = CONCAT('Insufficient stock! Need ', v_units, ' units, but only ', v_stock, ' available.');
        LEAVE proc_body;
    END IF;

    -- Update request status (Trigger will handle stock deduction and date update)
    UPDATE blood_requests
    SET status = 'Fulfilled',
        fulfilled_date = CURDATE()
    WHERE id = p_request_id;

    COMMIT;

    SET p_result_code = 1;
    SET p_result_message = 'Blood request fulfilled successfully and stock updated!';
END$$

DELIMITER ;
