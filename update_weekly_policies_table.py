from sqlalchemy import create_engine, text
from backend.app.database import DATABASE_URL

def update_weekly_policies_table():
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        print("Connected to database. Updating weekly_policies table...")
        
        # List of columns to add
        columns = [
            ("easy_routes_target", "INT DEFAULT 2"),
            ("medium_routes_target", "INT DEFAULT 3"),
            ("hard_routes_target", "INT DEFAULT 2"),
            ("easy_route_credits", "INT DEFAULT 3"),
            ("medium_route_credits", "INT DEFAULT 4"),
            ("hard_route_credits", "INT DEFAULT 6"),
            ("max_consecutive_hard_routes", "INT DEFAULT 2"),
            ("min_rest_days_after_hard", "INT DEFAULT 1"),
            ("fatigue_threshold_for_restriction", "DECIMAL(5,2) DEFAULT 80.0"),
            ("updated_at", "TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"),
            ("updated_by", "VARCHAR(100)"),
        ]
        
        for col_name, col_type in columns:
            try:
                sql = text(f"ALTER TABLE weekly_policies ADD COLUMN {col_name} {col_type}")
                conn.execute(sql)
                print(f"Added column: {col_name}")
            except Exception as e:
                if "Duplicate column name" in str(e):
                    print(f"Column {col_name} already exists.")
                else:
                    print(f"Error adding {col_name}: {e}")
            
        conn.commit()
        print("Weekly policies table update complete.")

if __name__ == "__main__":
    update_weekly_policies_table()
