from sqlalchemy import create_engine, text
from backend.app.database import DATABASE_URL

def create_reports_table():
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        print("🔌 Connected to database. Creating daily_reports table...")
        
        # Create table SQL
        sql = text("""
        CREATE TABLE IF NOT EXISTS daily_reports (
            id INT AUTO_INCREMENT PRIMARY KEY,
            report_date DATE NOT NULL,
            location_id VARCHAR(50),
            pdf_path TEXT,
            assignments_count INT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
        """)
        
        try:
            conn.execute(sql)
            print("✅ Table 'daily_reports' created successfully.")
        except Exception as e:
            print(f"⚠️ Error creating table: {e}")
            
        conn.commit()

if __name__ == "__main__":
    create_reports_table()
