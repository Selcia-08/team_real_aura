from sqlalchemy import create_engine, text
from backend.app.database import DATABASE_URL

engine = create_engine(DATABASE_URL)
with engine.connect() as conn:
    res = conn.execute(text("SELECT employee_id, role, health_status FROM users"))
    print("\n--- ALL USERS ---")
    for row in res.fetchall():
        print(f"EmpID: {row[0]} | Role: {row[1]} | Health: {row[2]}")
