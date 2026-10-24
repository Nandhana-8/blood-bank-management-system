-- ============================================================================
-- Blood Bank Management System (BBMS)
-- Stored Functions: functions.sql
-- Demonstrates deterministic & data-reading stored functions in MySQL
-- ============================================================================

USE blood_bank_db;

DELIMITER $$

-- ----------------------------------------------------------------------------
-- 1. Function: fn_get_available_units
-- Returns the current available units for a specific blood group ID
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_get_available_units$$

CREATE FUNCTION fn_get_available_units(p_blood_group_id INT)
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_units INT DEFAULT 0;

    SELECT COALESCE(available_units, 0)
    INTO v_units
    FROM blood_stock
    WHERE blood_group_id = p_blood_group_id
    LIMIT 1;

    RETURN v_units;
END$$

-- ----------------------------------------------------------------------------
-- 2. Function: fn_get_stock_status_label
-- Categorizes stock quantity into CRITICAL, MODERATE, or SUFFICIENT
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_get_stock_status_label$$

CREATE FUNCTION fn_get_stock_status_label(p_units INT)
RETURNS VARCHAR(20)
NO SQL
DETERMINISTIC
BEGIN
    IF p_units < 5 THEN
        RETURN 'CRITICAL';
    ELSEIF p_units BETWEEN 5 AND 15 THEN
        RETURN 'MODERATE';
    ELSE
        RETURN 'SUFFICIENT';
    END IF;
END$$

-- ----------------------------------------------------------------------------
-- 3. Function: fn_check_stock_availability
-- Verifies whether sufficient stock exists to satisfy a requested quantity
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_check_stock_availability$$

CREATE FUNCTION fn_check_stock_availability(p_blood_group_id INT, p_required_units INT)
RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_current_units INT DEFAULT 0;

    SELECT COALESCE(available_units, 0)
    INTO v_current_units
    FROM blood_stock
    WHERE blood_group_id = p_blood_group_id
    LIMIT 1;

    IF v_current_units >= p_required_units THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END$$

DELIMITER ;
