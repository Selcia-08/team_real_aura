from sqlalchemy import create_engine, text
import os
from backend.app.database import DATABASE_URL

def update_schema():
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        print("Connected to database. Updating schema...")
        
        # List of columns to add
        columns = [
            ("age", "INT"),
            ("dob", "VARCHAR(255)"),
            ("native_place", "VARCHAR(255)"),
            ("experience_years", "INT"),
            ("license_type", "VARCHAR(50)"),
            ("photo_url", "TEXT"),
            ("has_medical_exemption", "BOOLEAN DEFAULT FALSE"),
            ("exemption_reason", "TEXT"),
            ("exemption_until", "DATETIME")
        ]
        
        for col_name, col_type in columns:
            try:
                sql = text(f"ALTER TABLE users ADD COLUMN {col_name} {col_type}")
                conn.execute(sql)
                print(f"Added column: {col_name}")
            except Exception as e:
                if "Duplicate column name" in str(e):
                    print(f"Column {col_name} already exists.")
                else:
                    print(f"Error adding {col_name}: {e}")
            
        conn.commit()
        print("Schema update complete.")

if __name__ == "__main__":
    update_schema()
