from sqlalchemy import create_engine, text
from backend.app.database import DATABASE_URL

engine = create_engine(DATABASE_URL)
with engine.connect() as conn:
    print("Updating users table...")
    conn.execute(text("UPDATE users SET role = UPPER(role)"))
    conn.execute(text("UPDATE users SET health_status = UPPER(health_status)"))
    
    print("Updating assignments table...")
    conn.execute(text("UPDATE assignments SET status = UPPER(status)"))
    
    conn.commit()
    print("Database data updated to uppercase.")
