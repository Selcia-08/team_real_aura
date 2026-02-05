from sqlalchemy import create_engine, text
from backend.app.database import DATABASE_URL

engine = create_engine(DATABASE_URL)
with engine.connect() as conn:
    res = conn.execute(text("SELECT * FROM users WHERE employee_id='EMP001'"))
    row = res.fetchone()
    if row:
        print("\n--- USER DATA ---")
        for column, value in row._mapping.items():
            print(f"{column}: {value} (type: {type(value)})")
    else:
        print("User not found")
