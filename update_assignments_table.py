from sqlalchemy import create_engine, text
from backend.app.database import DATABASE_URL

def update_assignments_table():
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        print("Connected to database. Updating assignments table...")
        
        # List of columns to add
        columns = [
            ("explanation", "TEXT"),
            ("response_time", "DATETIME"),
            ("decline_reason", "TEXT"),
            ("original_driver_id", "INT"),
            ("reassignment_bonus", "INT DEFAULT 0"),
            ("completed_at", "DATETIME"),
            ("actual_time_minutes", "INT"),
        ]
        
        for col_name, col_type in columns:
            try:
                sql = text(f"ALTER TABLE assignments ADD COLUMN {col_name} {col_type}")
                conn.execute(sql)
                print(f"Added column: {col_name}")
            except Exception as e:
                if "Duplicate column name" in str(e):
                    print(f"Column {col_name} already exists.")
                else:
                    print(f"Error adding {col_name}: {e}")
        
        # Update status enum to uppercase
        try:
            print("Updating status enum...")
            conn.execute(text("ALTER TABLE assignments MODIFY COLUMN status ENUM('PENDING', 'ACCEPTED', 'DECLINED', 'REASSIGNED', 'COMPLETED') DEFAULT 'PENDING'"))
            print("Status enum updated.")
        except Exception as e:
            print(f"Error updating status enum: {e}")
        
        # Update existing data
        try:
            print("Updating existing status values...")
            conn.execute(text("UPDATE assignments SET status = UPPER(status)"))
            print("Status values updated.")
        except Exception as e:
            print(f"Error updating status values: {e}")
            
        conn.commit()
        print("Assignments table update complete.")

if __name__ == "__main__":
    update_assignments_table()
