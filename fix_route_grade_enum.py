from sqlalchemy import create_engine, text
from backend.app.database import DATABASE_URL

engine = create_engine(DATABASE_URL)
with engine.connect() as conn:
    print("Fixing route grade enum values...")
    
    # Update grade enum definition
    try:
        conn.execute(text("ALTER TABLE routes MODIFY COLUMN grade ENUM('EASY', 'MEDIUM', 'HARD')"))
        print("✓ Updated grade enum definition")
    except Exception as e:
        print(f"Error updating enum: {e}")
    
    # Update existing data
    try:
        conn.execute(text("UPDATE routes SET grade = 'EASY' WHERE grade = '1' OR grade = 'Easy'"))
        conn.execute(text("UPDATE routes SET grade = 'MEDIUM' WHERE grade = '2' OR grade = 'Medium'"))
        conn.execute(text("UPDATE routes SET grade = 'HARD' WHERE grade = '3' OR grade = 'Hard'"))
        print("✓ Updated existing grade values")
    except Exception as e:
        print(f"Error updating values: {e}")
    
    conn.commit()
    print("Grade enum fix complete!")
