-- ========================================
-- FairDispatch AI - MySQL Database Setup
-- Complete SQL Schema and Sample Data
-- ========================================

-- Step 1: Create Database
-- ========================================
CREATE DATABASE IF NOT EXISTS fairdispatch;
USE fairdispatch;

-- Step 2: Create Tables
-- ========================================

-- Table: admins (Admin authentication)
CREATE TABLE IF NOT EXISTS admins (
    id INT AUTO_INCREMENT PRIMARY KEY,
    location_id VARCHAR(50) NOT NULL UNIQUE,
    year VARCHAR(4) NOT NULL,
    dob VARCHAR(8) NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_location (location_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table: users (Drivers and Dispatchers)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    employee_id VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('DRIVER', 'DISPATCHER', 'ADMIN') DEFAULT 'DRIVER',
    location_id VARCHAR(50) NOT NULL,
    fatigue_score DECIMAL(5,2) DEFAULT 0.00,
    health_status ENUM('Normal', 'Caution', 'Restricted') DEFAULT 'Normal',
    credits INT DEFAULT 10,
    bonus_credits INT DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    has_medical_exemption BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_employee (employee_id),
    INDEX idx_location (location_id),
    INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table: routes (Delivery routes)
CREATE TABLE IF NOT EXISTS routes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    description TEXT NOT NULL,
    area VARCHAR(100) NOT NULL,
    location_id VARCHAR(50) NOT NULL,
    start_lat DECIMAL(10,8) NOT NULL,
    start_lng DECIMAL(11,8) NOT NULL,
    end_lat DECIMAL(10,8) NOT NULL,
    end_lng DECIMAL(11,8) NOT NULL,
    package_count INT NOT NULL,
    weight_kg DECIMAL(8,2) NOT NULL,
    grade INT NOT NULL CHECK (grade IN (1, 2, 3)),
    grade_reason TEXT,
    predicted_time_minutes INT,
    terrain_difficulty DECIMAL(3,2),
    walking_distance_km DECIMAL(5,2),
    traffic_level DECIMAL(3,2),
    apartment_density DECIMAL(3,2),
    has_elevator BOOLEAN DEFAULT TRUE,
    stairs_count INT DEFAULT 0,
    parking_difficulty DECIMAL(3,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_location (location_id),
    INDEX idx_grade (grade)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table: assignments (Route assignments to drivers)
CREATE TABLE IF NOT EXISTS assignments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    driver_id INT NOT NULL,
    route_id INT NOT NULL,
    assigned_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('Pending', 'Accepted', 'Declined', 'Completed', 'Cancelled') DEFAULT 'Pending',
    explanation TEXT,
    assignment_reason TEXT,
    decline_reason TEXT,
    reassignment_bonus INT DEFAULT 0,
    original_driver_id INT,
    response_time TIMESTAMP,
    completion_time TIMESTAMP,
    FOREIGN KEY (driver_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE CASCADE,
    FOREIGN KEY (original_driver_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_driver (driver_id),
    INDEX idx_route (route_id),
    INDEX idx_status (status),
    INDEX idx_date (assigned_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table: credit_logs (Credit transaction history)
CREATE TABLE IF NOT EXISTS credit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    driver_id INT NOT NULL,
    amount INT NOT NULL,
    reason VARCHAR(255) NOT NULL,
    is_bonus BOOLEAN DEFAULT FALSE,
    assignment_id INT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (driver_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (assignment_id) REFERENCES assignments(id) ON DELETE SET NULL,
    INDEX idx_driver (driver_id),
    INDEX idx_timestamp (timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table: notifications (In-app notifications)
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_read (is_read),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table: weekly_policies (Fairness policy configuration)
CREATE TABLE IF NOT EXISTS weekly_policies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    location_id VARCHAR(50) NOT NULL UNIQUE,
    easy_routes_target INT DEFAULT 2,
    medium_routes_target INT DEFAULT 3,
    hard_routes_target INT DEFAULT 2,
    easy_route_credits INT DEFAULT 3,
    medium_route_credits INT DEFAULT 4,
    hard_route_credits INT DEFAULT 6,
    max_consecutive_hard_routes INT DEFAULT 2,
    fatigue_threshold_for_restriction DECIMAL(5,2) DEFAULT 80.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_location (location_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Step 3: Insert Sample Data
-- ========================================

-- Insert Admin Account
INSERT INTO admins (location_id, year, dob, name, email) VALUES
('LOC001', '2024', '01011990', 'Admin Manager', 'admin@fairdispatch.com');

-- Insert Drivers and Dispatchers
INSERT INTO users (name, email, employee_id, password, role, location_id, fatigue_score, health_status, credits, bonus_credits, is_available, has_medical_exemption) VALUES
('Alex Driver', 'alex@fairdispatch.com', 'EMP001', 'pass123', 'DRIVER', 'LOC001', 30.00, 'Normal', 15, 0, TRUE, FALSE),
('Sam Tired', 'sam@fairdispatch.com', 'EMP002', 'pass123', 'DRIVER', 'LOC001', 85.00, 'Restricted', 8, 5, TRUE, TRUE),
('Jamie Fresh', 'jamie@fairdispatch.com', 'EMP003', 'pass123', 'DRIVER', 'LOC001', 15.00, 'Normal', 20, 10, TRUE, FALSE),
('Taylor Swift', 'taylor@fairdispatch.com', 'EMP004', 'pass123', 'DRIVER', 'LOC001', 55.00, 'Caution', 12, 0, TRUE, FALSE),
('Morgan Dispatcher', 'morgan@fairdispatch.com', 'EMP005', 'pass123', 'DISPATCHER', 'LOC001', 0.00, 'Normal', 0, 0, TRUE, FALSE);

-- Insert Sample Routes
INSERT INTO routes (description, area, location_id, start_lat, start_lng, end_lat, end_lng, package_count, weight_kg, grade, grade_reason, predicted_time_minutes, terrain_difficulty, walking_distance_km, traffic_level, apartment_density, has_elevator, stairs_count, parking_difficulty) VALUES
('Downtown residential area with elevator buildings', 'Downtown', 'LOC001', 40.7128, -74.0060, 40.7589, -73.9851, 15, 25.5, 1, 'Light packages, good parking, elevator access', 45, 0.2, 0.5, 0.3, 0.4, TRUE, 0, 0.2),
('Suburban houses with moderate traffic', 'Suburbs', 'LOC001', 40.7589, -73.9851, 40.7829, -73.9654, 25, 45.0, 2, 'Medium load, some stairs, moderate parking', 75, 0.4, 1.2, 0.5, 0.3, FALSE, 15, 0.5),
('High-rise apartments without elevator', 'Uptown', 'LOC001', 40.7829, -73.9654, 40.8075, -73.9626, 35, 65.0, 3, 'Heavy packages, no elevator, difficult parking', 120, 0.7, 2.0, 0.8, 0.9, FALSE, 45, 0.9),
('Shopping district with easy access', 'Shopping District', 'LOC001', 40.7484, -73.9857, 40.7614, -73.9776, 12, 18.0, 1, 'Light load, commercial area, good access', 35, 0.1, 0.3, 0.4, 0.2, TRUE, 0, 0.1),
('Industrial area with heavy packages', 'Industrial Zone', 'LOC001', 40.7282, -74.0776, 40.7456, -74.0514, 30, 80.0, 3, 'Very heavy packages, warehouse deliveries', 90, 0.6, 1.5, 0.6, 0.1, FALSE, 20, 0.7),
('Mixed residential-commercial area', 'Midtown', 'LOC001', 40.7549, -73.9840, 40.7614, -73.9776, 20, 35.0, 2, 'Mixed deliveries, moderate difficulty', 60, 0.3, 0.8, 0.5, 0.5, TRUE, 10, 0.4);

-- Insert Weekly Policy
INSERT INTO weekly_policies (location_id, easy_routes_target, medium_routes_target, hard_routes_target, easy_route_credits, medium_route_credits, hard_route_credits, max_consecutive_hard_routes, fatigue_threshold_for_restriction) VALUES
('LOC001', 2, 3, 2, 3, 4, 6, 2, 80.00);

-- Step 4: Create Views for Analytics
-- ========================================

-- View: Driver Performance Summary
CREATE OR REPLACE VIEW driver_performance AS
SELECT 
    u.id,
    u.name,
    u.employee_id,
    u.fatigue_score,
    u.health_status,
    u.credits,
    u.bonus_credits,
    COUNT(DISTINCT a.id) as total_assignments,
    SUM(CASE WHEN a.status = 'Completed' THEN 1 ELSE 0 END) as completed_assignments,
    SUM(CASE WHEN a.status = 'Declined' THEN 1 ELSE 0 END) as declined_assignments,
    AVG(r.grade) as avg_route_difficulty
FROM users u
LEFT JOIN assignments a ON u.id = a.driver_id
LEFT JOIN routes r ON a.route_id = r.id
WHERE u.role = 'DRIVER'
GROUP BY u.id, u.name, u.employee_id, u.fatigue_score, u.health_status, u.credits, u.bonus_credits;

-- View: Daily Assignment Summary
CREATE OR REPLACE VIEW daily_assignments AS
SELECT 
    DATE(a.assigned_date) as assignment_date,
    a.status,
    COUNT(*) as count,
    AVG(r.grade) as avg_difficulty
FROM assignments a
JOIN routes r ON a.route_id = r.id
GROUP BY DATE(a.assigned_date), a.status;

-- Step 5: Create Stored Procedures
-- ========================================

-- Procedure: Update Driver Fatigue
DELIMITER //
CREATE PROCEDURE update_driver_fatigue(
    IN p_driver_id INT,
    IN p_fatigue_change DECIMAL(5,2)
)
BEGIN
    UPDATE users 
    SET fatigue_score = GREATEST(0, LEAST(100, fatigue_score + p_fatigue_change))
    WHERE id = p_driver_id AND role = 'DRIVER';
    
    -- Update health status based on fatigue
    UPDATE users
    SET health_status = CASE
        WHEN fatigue_score >= 80 THEN 'Restricted'
        WHEN fatigue_score >= 60 THEN 'Caution'
        ELSE 'Normal'
    END
    WHERE id = p_driver_id AND role = 'DRIVER';
END //
DELIMITER ;

-- Procedure: Award Credits
DELIMITER //
CREATE PROCEDURE award_credits(
    IN p_driver_id INT,
    IN p_amount INT,
    IN p_reason VARCHAR(255),
    IN p_is_bonus BOOLEAN,
    IN p_assignment_id INT
)
BEGIN
    -- Update driver credits
    IF p_is_bonus THEN
        UPDATE users SET bonus_credits = bonus_credits + p_amount WHERE id = p_driver_id;
    ELSE
        UPDATE users SET credits = credits + p_amount WHERE id = p_driver_id;
    END IF;
    
    -- Log transaction
    INSERT INTO credit_logs (driver_id, amount, reason, is_bonus, assignment_id)
    VALUES (p_driver_id, p_amount, p_reason, p_is_bonus, p_assignment_id);
END //
DELIMITER ;

-- Procedure: Complete Assignment
DELIMITER //
CREATE PROCEDURE complete_assignment(
    IN p_assignment_id INT
)
BEGIN
    DECLARE v_driver_id INT;
    DECLARE v_route_grade INT;
    DECLARE v_credits INT;
    
    -- Get assignment details
    SELECT a.driver_id, r.grade INTO v_driver_id, v_route_grade
    FROM assignments a
    JOIN routes r ON a.route_id = r.id
    WHERE a.id = p_assignment_id;
    
    -- Calculate credits based on grade
    SELECT CASE v_route_grade
        WHEN 1 THEN easy_route_credits
        WHEN 2 THEN medium_route_credits
        WHEN 3 THEN hard_route_credits
    END INTO v_credits
    FROM weekly_policies
    WHERE location_id = (SELECT location_id FROM users WHERE id = v_driver_id)
    LIMIT 1;
    
    -- Update assignment status
    UPDATE assignments 
    SET status = 'Completed', completion_time = NOW()
    WHERE id = p_assignment_id;
    
    -- Award credits
    CALL award_credits(v_driver_id, v_credits, 'Route completion', FALSE, p_assignment_id);
    
    -- Update fatigue (increase based on difficulty)
    CALL update_driver_fatigue(v_driver_id, v_route_grade * 5);
END //
DELIMITER ;

-- Step 6: Create Triggers
-- ========================================

-- Trigger: Create notification on new assignment
DELIMITER //
CREATE TRIGGER after_assignment_insert
AFTER INSERT ON assignments
FOR EACH ROW
BEGIN
    INSERT INTO notifications (user_id, title, message, notification_type)
    VALUES (
        NEW.driver_id,
        'New Route Assignment',
        CONCAT('You have been assigned a new route. ', NEW.explanation),
        'route_assigned'
    );
END //
DELIMITER ;

-- Trigger: Create notification on assignment acceptance
DELIMITER //
CREATE TRIGGER after_assignment_accept
AFTER UPDATE ON assignments
FOR EACH ROW
BEGIN
    IF NEW.status = 'Accepted' AND OLD.status = 'Pending' THEN
        INSERT INTO notifications (user_id, title, message, notification_type)
        VALUES (
            NEW.driver_id,
            'Route Accepted',
            'Thank you for accepting the route assignment!',
            'route_accepted'
        );
    END IF;
END //
DELIMITER ;

-- Step 7: Sample Queries for Common Operations
-- ========================================

-- Query 1: Get all available drivers
-- SELECT * FROM users WHERE role = 'DRIVER' AND is_available = TRUE;

-- Query 2: Get pending assignments for a driver
-- SELECT a.*, r.* FROM assignments a
-- JOIN routes r ON a.route_id = r.id
-- WHERE a.driver_id = 1 AND a.status = 'Pending';

-- Query 3: Get driver performance stats
-- SELECT * FROM driver_performance WHERE employee_id = 'EMP001';

-- Query 4: Get today's assignments
-- SELECT * FROM assignments WHERE DATE(assigned_date) = CURDATE();

-- Query 5: Get high-fatigue drivers
-- SELECT * FROM users WHERE role = 'DRIVER' AND fatigue_score > 70;

-- Step 8: Indexes for Performance
-- ========================================
-- (Already created in table definitions above)

-- Step 9: Grant Permissions (Optional)
-- ========================================
-- GRANT ALL PRIVILEGES ON fairdispatch.* TO 'fairdispatch_user'@'%' IDENTIFIED BY 'secure_password';
-- FLUSH PRIVILEGES;

-- ========================================
-- Setup Complete!
-- ========================================
-- You can now:
-- 1. Connect your backend to this database
-- 2. Use the API to populate/manage data
-- 3. Or manually insert data using the queries above
-- ========================================
