from sqlalchemy import create_engine, text
from backend.app.database import DATABASE_URL

engine = create_engine(DATABASE_URL)
with engine.connect() as conn:
    print("Updating health_status enum definition...")
    # Change Enum definition to uppercase
    conn.execute(text("ALTER TABLE users MODIFY COLUMN health_status ENUM('NORMAL', 'CAUTION', 'RESTRICTED') DEFAULT 'NORMAL'"))
    
    # Update existing data just in case (though MODIFY might have handled it if it matched)
    conn.execute(text("UPDATE users SET health_status = 'NORMAL' WHERE health_status = 'Normal'"))
    conn.execute(text("UPDATE users SET health_status = 'CAUTION' WHERE health_status = 'Caution'"))
    conn.execute(text("UPDATE users SET health_status = 'RESTRICTED' WHERE health_status = 'Restricted'"))
    
    conn.commit()
    print("Health status enum updated to uppercase.")
