from sqlalchemy import create_engine, text
from backend.app.database import DATABASE_URL

def create_missing_tables():
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        print("Connected to database. Creating missing tables...")
        
        # Create daily_reports table
        try:
            create_daily_reports = text("""
                CREATE TABLE IF NOT EXISTS daily_reports (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    report_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    location_id VARCHAR(50) NOT NULL,
                    pdf_path TEXT,
                    assignments_count INT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_location (location_id),
                    INDEX idx_date (report_date)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """)
            conn.execute(create_daily_reports)
            print("Created daily_reports table")
        except Exception as e:
            print(f"daily_reports table: {e}")
        
        # Create credit_logs table if missing
        try:
            create_credit_logs = text("""
                CREATE TABLE IF NOT EXISTS credit_logs (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    driver_id INT NOT NULL,
                    amount INT NOT NULL,
                    reason VARCHAR(255) NOT NULL,
                    is_bonus BOOLEAN DEFAULT FALSE,
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (driver_id) REFERENCES users(id) ON DELETE CASCADE,
                    INDEX idx_driver (driver_id),
                    INDEX idx_timestamp (timestamp)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """)
            conn.execute(create_credit_logs)
            print("Created credit_logs table")
        except Exception as e:
            print(f"credit_logs table: {e}")
        
        # Create notifications table if missing
        try:
            create_notifications = text("""
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
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """)
            conn.execute(create_notifications)
            print("Created notifications table")
        except Exception as e:
            print(f"notifications table: {e}")
            
        conn.commit()
        print("All missing tables created successfully.")

if __name__ == "__main__":
    create_missing_tables()
