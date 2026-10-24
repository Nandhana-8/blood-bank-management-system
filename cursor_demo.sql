-- ============================================================================
-- Blood Bank Management System (BBMS)
-- Cursor Demonstration: cursor_demo.sql
-- Implements a stored procedure that utilizes a MySQL CURSOR to iterate
-- row-by-row over blood groups, analyze stock thresholds, and produce an audit report.
-- ============================================================================

USE blood_bank_db;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_blood_stock_audit_cursor$$

CREATE PROCEDURE sp_blood_stock_audit_cursor()
BEGIN
    -- Declare loop control flag
    DECLARE v_done INT DEFAULT FALSE;

    -- Declare variables to hold cursor values
    DECLARE v_group_id INT;
    DECLARE v_group_name VARCHAR(10);
    DECLARE v_rh VARCHAR(10);
    DECLARE v_units INT;
    DECLARE v_status_category VARCHAR(20);
    DECLARE v_action_recommendation VARCHAR(120);
    DECLARE v_total_donations INT DEFAULT 0;

    -- Declare CURSOR to iterate across all blood groups
    DECLARE cur_blood_groups CURSOR FOR
        SELECT 
            bg.id,
            bg.blood_group_name,
            bg.rh_factor,
            COALESCE(bs.available_units, 0) AS available_units
        FROM blood_groups bg
        LEFT JOIN blood_stock bs ON bg.id = bs.blood_group_id
        ORDER BY bg.id ASC;

    -- Declare NOT FOUND handler for cursor completion
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    -- Create temporary table to store cursor-generated report
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_blood_stock_audit (
        blood_group_id INT,
        blood_group_name VARCHAR(10),
        rh_factor VARCHAR(10),
        available_units INT,
        status_category VARCHAR(20),
        total_donations_logged INT,
        recommendation VARCHAR(120),
        audited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Clear table for fresh audit run
    TRUNCATE TABLE temp_blood_stock_audit;

    -- Open the cursor
    OPEN cur_blood_groups;

    -- Loop through each blood group
    read_loop: LOOP
        FETCH cur_blood_groups INTO v_group_id, v_group_name, v_rh, v_units;

        IF v_done THEN
            LEAVE read_loop;
        END IF;

        -- Count donations registered for this blood group
        SELECT COUNT(*) INTO v_total_donations
        FROM donations
        WHERE blood_group_id = v_group_id;

        -- Classify stock status and formulate clinical recommendation
        IF v_units < 5 THEN
            SET v_status_category = 'CRITICAL';
            SET v_action_recommendation = 'CRITICAL LOW: Launch immediate emergency blood donation drive';
        ELSEIF v_units BETWEEN 5 AND 15 THEN
            SET v_status_category = 'MODERATE';
            SET v_action_recommendation = 'MODERATE: Adequate reserve; maintain routine donor outreach';
        ELSE
            SET v_status_category = 'SUFFICIENT';
            SET v_action_recommendation = 'SUFFICIENT: Optimum stock balance; continue regular intake';
        END IF;

        -- Insert audit finding into temporary report table
        INSERT INTO temp_blood_stock_audit (
            blood_group_id,
            blood_group_name,
            rh_factor,
            available_units,
            status_category,
            total_donations_logged,
            recommendation
        ) VALUES (
            v_group_id,
            v_group_name,
            v_rh,
            v_units,
            v_status_category,
            v_total_donations,
            v_action_recommendation
        );
    END LOOP;

    -- Close the cursor
    CLOSE cur_blood_groups;

    -- Return the compiled audit results as a formatted tabular result set
    SELECT 
        blood_group_id AS `Group ID`,
        blood_group_name AS `Blood Group`,
        rh_factor AS `Rh Factor`,
        available_units AS `Available Units`,
        status_category AS `Stock Status`,
        total_donations_logged AS `Donations Logged`,
        recommendation AS `Clinical Recommendation`
    FROM temp_blood_stock_audit
    ORDER BY blood_group_id ASC;

END$$

DELIMITER ;
