from sqlalchemy import create_engine, text
from backend.app.database import DATABASE_URL

def update_routes_table():
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        print("Connected to database. Updating routes table...")
        
        # List of columns to add to routes table
        columns = [
            ("end_lat", "DECIMAL(10,8)"),
            ("end_lng", "DECIMAL(11,8)"),
            ("package_count", "INT"),
            ("weight_kg", "DECIMAL(10,2)"),
            ("has_elevator", "BOOLEAN DEFAULT TRUE"),
            ("traffic_level", "DECIMAL(3,2)"),
            ("apartment_density", "DECIMAL(3,2)"),
            ("walking_distance_km", "DECIMAL(5,2)"),
            ("stairs_count", "INT DEFAULT 0"),
            ("parking_difficulty", "DECIMAL(3,2) DEFAULT 0.5"),
            ("predicted_time_minutes", "INT"),
            ("terrain_difficulty", "DECIMAL(3,2)"),
            ("grade", "INT"),
            ("grade_reason", "TEXT"),
            ("is_assigned", "BOOLEAN DEFAULT FALSE"),
            ("created_at", "TIMESTAMP DEFAULT CURRENT_TIMESTAMP"),
        ]
        
        for col_name, col_type in columns:
            try:
                sql = text(f"ALTER TABLE routes ADD COLUMN {col_name} {col_type}")
                conn.execute(sql)
                print(f"Added column: {col_name}")
            except Exception as e:
                if "Duplicate column name" in str(e):
                    print(f"Column {col_name} already exists.")
                else:
                    print(f"Error adding {col_name}: {e}")
            
        conn.commit()
        print("Routes table update complete.")

if __name__ == "__main__":
    update_routes_table()
