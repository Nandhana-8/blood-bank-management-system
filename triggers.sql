-- ============================================================================
-- Blood Bank Management System (BBMS)
-- Database Triggers: triggers.sql
-- Automates inventory updates and enforces integrity constraints in MySQL:
-- 1. Increases stock and updates donor last_donation_date on donation insert
-- 2. Safely balances stock on donation update
-- 3. Safely decrements stock on donation delete (preventing negative inventory)
-- 4. Validates stock availability and decrements stock when request is Fulfilled
-- 5. Restores stock if a fulfilled request is canceled or status reverted
-- ============================================================================

USE blood_bank_db;

DELIMITER $$

-- ----------------------------------------------------------------------------
-- 1. Trigger: trg_after_donation_insert
-- Automatically increments available units in blood_stock and updates donor's last_donation_date
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_after_donation_insert$$

CREATE TRIGGER trg_after_donation_insert
AFTER INSERT ON donations
FOR EACH ROW
BEGIN
    -- Increase available blood units for the donated blood group
    UPDATE blood_stock 
    SET available_units = available_units + NEW.units
    WHERE blood_group_id = NEW.blood_group_id;

    -- Update donor's last donation date if this donation is newer
    UPDATE donors 
    SET last_donation_date = NEW.donation_date
    WHERE id = NEW.donor_id 
      AND (last_donation_date IS NULL OR last_donation_date <= NEW.donation_date);
END$$

-- ----------------------------------------------------------------------------
-- 2. Trigger: trg_before_donation_update
-- Safely adjusts blood stock when donation units or blood group are edited
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_before_donation_update$$

CREATE TRIGGER trg_before_donation_update
BEFORE UPDATE ON donations
FOR EACH ROW
BEGIN
    DECLARE v_current_stock INT;
    DECLARE v_diff INT;

    -- Handle case where blood group remained the same
    IF OLD.blood_group_id = NEW.blood_group_id THEN
        SET v_diff = NEW.units - OLD.units;
        
        -- If units were reduced, ensure stock doesn't become negative
        IF v_diff < 0 THEN
            SELECT available_units INTO v_current_stock 
            FROM blood_stock 
            WHERE blood_group_id = NEW.blood_group_id;

            IF (v_current_stock + v_diff) < 0 THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Error: Cannot reduce donation units. Stock would become negative!';
            END IF;
        END IF;

        UPDATE blood_stock 
        SET available_units = available_units + v_diff
        WHERE blood_group_id = NEW.blood_group_id;

    -- Handle case where blood group was changed
    ELSE
        -- Verify old blood group has enough stock to deduct OLD.units
        SELECT available_units INTO v_current_stock 
        FROM blood_stock 
        WHERE blood_group_id = OLD.blood_group_id;

        IF v_current_stock < OLD.units THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Cannot change blood group. Old blood stock has already been consumed!';
        END IF;

        -- Deduct from old blood group stock
        UPDATE blood_stock 
        SET available_units = available_units - OLD.units
        WHERE blood_group_id = OLD.blood_group_id;

        -- Add to new blood group stock
        UPDATE blood_stock 
        SET available_units = available_units + NEW.units
        WHERE blood_group_id = NEW.blood_group_id;
    END IF;
END$$

-- ----------------------------------------------------------------------------
-- 3. Trigger: trg_before_donation_delete
-- Safely decreases blood stock when a donation record is deleted
-- Prevents stock from becoming negative
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_before_donation_delete$$

CREATE TRIGGER trg_before_donation_delete
BEFORE DELETE ON donations
FOR EACH ROW
BEGIN
    DECLARE v_current_stock INT;

    SELECT available_units INTO v_current_stock
    FROM blood_stock
    WHERE blood_group_id = OLD.blood_group_id;

    IF v_current_stock < OLD.units THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Cannot delete donation. The blood units have already been issued/consumed!';
    ELSE
        UPDATE blood_stock
        SET available_units = available_units - OLD.units
        WHERE blood_group_id = OLD.blood_group_id;
    END IF;
END$$

-- ----------------------------------------------------------------------------
-- 4. Trigger: trg_before_blood_request_update
-- Decreases blood stock when a blood request is marked 'Fulfilled'
-- Checks stock availability and raises error if stock is insufficient
-- Also handles restoration if a fulfilled request is canceled or reverted
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_before_blood_request_update$$

CREATE TRIGGER trg_before_blood_request_update
BEFORE UPDATE ON blood_requests
FOR EACH ROW
BEGIN
    DECLARE v_available_stock INT;

    -- Case 1: Status transitioning to 'Fulfilled' from another status
    IF OLD.status <> 'Fulfilled' AND NEW.status = 'Fulfilled' THEN
        SELECT available_units INTO v_available_stock
        FROM blood_stock
        WHERE blood_group_id = NEW.blood_group_id;

        -- Prevent fulfillment if stock is insufficient
        IF v_available_stock < NEW.units_requested THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Insufficient blood stock to fulfill request!';
        ELSE
            -- Deduct stock safely
            UPDATE blood_stock
            SET available_units = available_units - NEW.units_requested
            WHERE blood_group_id = NEW.blood_group_id;

            -- Stamp fulfillment date if not already set
            IF NEW.fulfilled_date IS NULL THEN
                SET NEW.fulfilled_date = CURDATE();
            END IF;
        END IF;

    -- Case 2: Status transitioning away from 'Fulfilled' (reversion / cancellation)
    ELSEIF OLD.status = 'Fulfilled' AND NEW.status <> 'Fulfilled' THEN
        -- Restore deducted stock
        UPDATE blood_stock
        SET available_units = available_units + OLD.units_requested
        WHERE blood_group_id = OLD.blood_group_id;

        -- Clear fulfilled date
        SET NEW.fulfilled_date = NULL;
    END IF;
END$$

DELIMITER ;
