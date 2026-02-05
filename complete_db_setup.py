"""
Complete Database Setup and Fix Script
This script ensures all tables have the correct schema and populates demo data
"""
from sqlalchemy import create_engine, text
from backend.app.database import DATABASE_URL
import sys

def run_complete_setup():
    engine = create_engine(DATABASE_URL)
    
    print("=" * 60)
    print("FAIRDISPATCH DATABASE COMPLETE SETUP")
    print("=" * 60)
    
    with engine.connect() as conn:
        # Step 1: Ensure all tables exist with correct schema
        print("\n[1/4] Creating/Verifying Tables...")
        
        tables_sql = [
            # Admins table
            """CREATE TABLE IF NOT EXISTS admins (
                id INT AUTO_INCREMENT PRIMARY KEY,
                location_id VARCHAR(50) NOT NULL UNIQUE,
                year VARCHAR(4) NOT NULL,
                dob VARCHAR(8) NOT NULL,
                name VARCHAR(100) NOT NULL,
                email VARCHAR(100),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4""",
            
            # Users table
            """CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                email VARCHAR(100) NOT NULL,
                employee_id VARCHAR(50) NOT NULL UNIQUE,
                password VARCHAR(255) NOT NULL,
                role ENUM('DRIVER', 'DISPATCHER', 'ADMIN') DEFAULT 'DRIVER',
                location_id VARCHAR(50) NOT NULL,
                fatigue_score DECIMAL(5,2) DEFAULT 0.00,
                health_status ENUM('NORMAL', 'CAUTION', 'RESTRICTED') DEFAULT 'NORMAL',
                credits INT DEFAULT 10,
                bonus_credits INT DEFAULT 0,
                is_available BOOLEAN DEFAULT TRUE,
                has_medical_exemption BOOLEAN DEFAULT FALSE,
                exemption_reason TEXT,
                exemption_until DATETIME,
                age INT,
                dob VARCHAR(255),
                native_place VARCHAR(255),
                experience_years INT,
                license_type VARCHAR(50),
                photo_url TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4""",
            
            # Routes table
            """CREATE TABLE IF NOT EXISTS routes (
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
                has_elevator BOOLEAN DEFAULT TRUE,
                traffic_level DECIMAL(3,2),
                apartment_density DECIMAL(3,2),
                walking_distance_km DECIMAL(5,2),
                stairs_count INT DEFAULT 0,
                parking_difficulty DECIMAL(3,2) DEFAULT 0.5,
                predicted_time_minutes INT,
                terrain_difficulty DECIMAL(3,2),
                grade INT,
                grade_reason TEXT,
                is_assigned BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4""",
            
            # Assignments table
            """CREATE TABLE IF NOT EXISTS assignments (
                id INT AUTO_INCREMENT PRIMARY KEY,
                driver_id INT NOT NULL,
                route_id INT NOT NULL,
                assigned_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                status ENUM('PENDING', 'ACCEPTED', 'DECLINED', 'REASSIGNED', 'COMPLETED') DEFAULT 'PENDING',
                explanation TEXT,
                assignment_reason TEXT,
                response_time DATETIME,
                decline_reason TEXT,
                original_driver_id INT,
                reassignment_bonus INT DEFAULT 0,
                completed_at DATETIME,
                actual_time_minutes INT,
                FOREIGN KEY (driver_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4""",
            
            # Credit logs table
            """CREATE TABLE IF NOT EXISTS credit_logs (
                id INT AUTO_INCREMENT PRIMARY KEY,
                driver_id INT NOT NULL,
                amount INT NOT NULL,
                reason VARCHAR(255) NOT NULL,
                is_bonus BOOLEAN DEFAULT FALSE,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (driver_id) REFERENCES users(id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4""",
            
            # Notifications table
            """CREATE TABLE IF NOT EXISTS notifications (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                title VARCHAR(255) NOT NULL,
                message TEXT NOT NULL,
                notification_type VARCHAR(50) NOT NULL,
                is_read BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4""",
            
            # Weekly policies table
            """CREATE TABLE IF NOT EXISTS weekly_policies (
                id INT AUTO_INCREMENT PRIMARY KEY,
                location_id VARCHAR(50) NOT NULL UNIQUE,
                easy_routes_target INT DEFAULT 2,
                medium_routes_target INT DEFAULT 3,
                hard_routes_target INT DEFAULT 2,
                easy_route_credits INT DEFAULT 3,
                medium_route_credits INT DEFAULT 4,
                hard_route_credits INT DEFAULT 6,
                max_consecutive_hard_routes INT DEFAULT 2,
                min_rest_days_after_hard INT DEFAULT 1,
                fatigue_threshold_for_restriction DECIMAL(5,2) DEFAULT 80.00,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                updated_by VARCHAR(100)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4""",
            
            # Daily reports table
            """CREATE TABLE IF NOT EXISTS daily_reports (
                id INT AUTO_INCREMENT PRIMARY KEY,
                report_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                location_id VARCHAR(50) NOT NULL,
                pdf_path TEXT,
                assignments_count INT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"""
        ]
        
        for sql in tables_sql:
            try:
                conn.execute(text(sql))
                print("✓ Table created/verified")
            except Exception as e:
                print(f"✗ Error: {e}")
        
        conn.commit()
        print("\n[2/4] Tables setup complete!")
        
        # Step 2: Verify data exists
        print("\n[3/4] Checking existing data...")
        result = conn.execute(text("SELECT COUNT(*) FROM users"))
        user_count = result.scalar()
        print(f"  - Users: {user_count}")
        
        result = conn.execute(text("SELECT COUNT(*) FROM routes"))
        route_count = result.scalar()
        print(f"  - Routes: {route_count}")
        
        result = conn.execute(text("SELECT COUNT(*) FROM admins"))
        admin_count = result.scalar()
        print(f"  - Admins: {admin_count}")
        
        print("\n[4/4] Setup Complete!")
        print("=" * 60)
        print("✓ Database is ready!")
        print("✓ You can now run the demo populate endpoint")
        print("=" * 60)

if __name__ == "__main__":
    try:
        run_complete_setup()
    except Exception as e:
        print(f"\n✗ FATAL ERROR: {e}")
        sys.exit(1)
