from sqlalchemy import create_engine, text
from backend.app.database import DATABASE_URL

def add_route_score_columns():
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        print("Adding route_score and route_credits columns to routes table...")
        
        try:
            conn.execute(text("ALTER TABLE routes ADD COLUMN route_score INT"))
            print("✓ Added route_score column")
        except Exception as e:
            if "Duplicate column name" in str(e):
                print("  route_score column already exists")
            else:
                print(f"✗ Error adding route_score: {e}")
        
        try:
            conn.execute(text("ALTER TABLE routes ADD COLUMN route_credits INT"))
            print("✓ Added route_credits column")
        except Exception as e:
            if "Duplicate column name" in str(e):
                print("  route_credits column already exists")
            else:
                print(f"✗ Error adding route_credits: {e}")
        
        conn.commit()
        print("Schema update complete!")

if __name__ == "__main__":
    add_route_score_columns()
